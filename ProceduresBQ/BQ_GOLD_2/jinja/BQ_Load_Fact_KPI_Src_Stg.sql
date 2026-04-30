{#-- ==========================================================================================
Routine:     Staging_Load_Fact_KPI_Src_Stg
Description: Maintains the stats for InterBranch Pickup & Delivery KPIs
History:
  01/12/2022  B. Woods        Routine Written
========================================================================================== --#}

CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.Staging_Load_Fact_KPI_Src_Stg`(
    IN p_ProcessID INT64, 
    IN p_StartDateOverRide STRING, 
    IN p_EndDateOverRide STRING
)
BEGIN
    -- Core Variables
    DECLARE v_Component STRING DEFAULT '{{ project_id }}.{{ target_dataset_id }}.Staging_Load_Fact_KPI_Src_Stg';
    DECLARE v_Step STRING DEFAULT 'Initialization';
    
    -- OPTION 2: Changed from TIMESTAMP to DATETIME
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Ended DATETIME;
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;

    -- Working Variables
    DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_StartDate DATETIME;
    DECLARE v_EndDate DATETIME;
    DECLARE v_RealisedDateCutOff DATETIME;

    BEGIN
        -- Calculate RealisedDateCutOff (6 months ago)
        SET v_RealisedDateCutOff = DATETIME_SUB(v_Loaded, INTERVAL 6 MONTH);

        -- Get LastValue for StartDate
        SET v_StartDate = (
            SELECT SAFE_CAST(LastValue AS DATETIME) 
            FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_LoadControl` 
            WHERE RecordSource = 'Fact_KPI_Scan' 
            LIMIT 1
        );

        -- Apply Overrides if provided
        SET v_StartDate = COALESCE(SAFE_CAST(NULLIF(p_StartDateOverRide, '') AS DATETIME), v_StartDate);
        
        -- End Date defaults to 23:59:59.999 of yesterday
        SET v_EndDate = COALESCE(
            SAFE_CAST(NULLIF(p_EndDateOverRide, '') AS DATETIME), 
            DATETIME_SUB(DATETIME_TRUNC(v_Loaded, DAY), INTERVAL 1 MILLISECOND)
        );

        -- ====================================================================
        -- Part 1: Daily scans load
        -- ====================================================================
        SET v_Step = 'Part1';

        TRUNCATE TABLE `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_KPI_Src_Stg`;

        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_KPI_Src_Stg` (
            LabelNo, CountryCode, ScanDateTime, ScanType, ScanStatus, FranchiseeCode, 
            CourierNumber, ScanDate, CreatedOn, FromRf, FromCf, ToRf, ToCf, 
            ToLocality, ToPostalCode, RealisedDate, Zone, CustomerId
        )
        SELECT 
            MF.LabelNo,
            MF.CountryCode,
            R.ScanDateTime,
            R.ScanType,
            R.ScanStatus,
            R.FranchiseeCode,
            R.CourierNumber,
            DATE(R.ScanDate),
            MF.CreatedOn,
            MF.FromRf,
            MF.FromCf,
            MF.ToRf,
            MF.ToCf,
            MF.ToLocality,
            MF.ToPostalCode,
            MF.RealisedDate,
            MF.Zone,
            MF.CustomerId
        FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_Scan_Recent` R 
        JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF` MF 
            ON MF.CountryCode = 1 
            AND MF.LabelNo = R.LabelNo 
            AND MF.IsCurrent = 1 
            AND MF.RealisedDate IS NOT NULL
            AND MF.RealisedDate > v_RealisedDateCutOff
        WHERE R.ScanDateTime > v_StartDate 
            AND R.CountryName = 'Australia'        
            AND R.ScanDateTime <= v_EndDate;

        SET v_Inserted = @@row_count;

        -- Update Watermark / Last Loaded Date
        CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_Set_LastValue`('Fact_KPI_Scan', 'ScanDateTime', CAST(v_EndDate AS STRING),FALSE);

        -- Log Part 1 Success (Option 2: Use DATETIME and CURRENT_DATETIME)
        SET v_Ended = CURRENT_DATETIME();
        CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
            CONCAT(v_Component, '-Part1'),
            p_ProcessID,
            v_Started,
            v_Ended,
            v_Result,
            v_ErrorMessage,
            v_Inserted,
            -1,
            -1
        ); 

        -- ====================================================================
        -- Part 2: Query whole month for missing labels (due to late uploads)
        -- ====================================================================
        SET v_Step = 'Part2';
        SET v_Started = CURRENT_DATETIME();
        
        -- StartDate moves back to 30 days ago
        SET v_StartDate = DATETIME_SUB(v_Loaded, INTERVAL 30 DAY);

        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_KPI_Src_Stg` (
            LabelNo, CountryCode, ScanDateTime, ScanType, ScanStatus, FranchiseeCode, 
            CourierNumber, ScanDate, CreatedOn, FromRf, FromCf, ToRf, ToCf, 
            ToLocality, ToPostalCode, RealisedDate, Zone, CustomerId
        )
        SELECT 
            MF.LabelNo,
            MF.CountryCode,
            R.ScanDate AS ScanDateTime,
            R.ScanType,
            R.ScanStatus,
            R.FranchiseeCode,
            R.CourierNumber,
            DATE(R.ScanDate),
            MF.CreatedOn,
            MF.FromRf,
            MF.FromCf,
            MF.ToRf,
            MF.ToCf,
            MF.ToLocality,
            MF.ToPostalCode,
            MF.RealisedDate,
            MF.Zone,
            MF.CustomerId
        FROM `{{ project_id }}.{{ target_dataset_id }}.dv_LNK_Scan` R 
        JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF` MF 
            ON MF.CountryCode = 1 
            AND MF.LabelNo = R.LabelNo 
            AND MF.IsCurrent = 1 
            AND MF.RealisedDate IS NOT NULL
            AND MF.RealisedDate > v_RealisedDateCutOff
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_KPI_Src_Stg` stg 
            ON stg.LabelNo = MF.LabelNo 
            AND stg.ScanDateTime = R.ScanDate  
        WHERE stg.LabelNo IS NULL   -- not already in todays load
            AND R.Loaded > v_StartDate 
            AND R.CountryName = 'Australia'        
            AND (
                (CAST(R.ScanDate AS DATE) >= DATE('2024-02-15') AND DATE_DIFF(CAST(R.Loaded AS DATE), CAST(R.ScanDate AS DATE), DAY) > 0)
                OR
                (CAST(R.ScanDate AS DATE) < DATE('2024-02-15') AND DATE_DIFF(CAST(R.Loaded AS DATE), CAST(R.ScanDate AS DATE), DAY) > 1)
            );

        SET v_Inserted = @@row_count;

        -- Log Part 2 Success
        SET v_Ended = CURRENT_DATETIME();
        CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
            CONCAT(v_Component, '-Part2'),
            p_ProcessID,
            v_Started,
            v_Ended,
            v_Result,
            v_ErrorMessage,
            v_Inserted,
            -1,
            -1
        ); 

    EXCEPTION WHEN ERROR THEN
        -- Catch errors and log them accurately based on the v_Step it failed on
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
        
        CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
            CONCAT(v_Component, '-', v_Step),
            p_ProcessID,
            v_Started,
            CURRENT_DATETIME(),
            v_Result,
            v_ErrorMessage,
            v_Inserted,
            -1,
            -1
        );
    END;
END;