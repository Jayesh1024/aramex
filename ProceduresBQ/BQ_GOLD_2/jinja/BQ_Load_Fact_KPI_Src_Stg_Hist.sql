-- ==========================================================================================
-- Routine:     Load_Fact_KPI_Src_Stg_Hist
-- Description: One-shot historical load of Fact KPI source scans from dv_LNK_Scan.
--              No LoadControl window or late-upload catch-up (Part 2). Sets Fact_KPI_Scan watermark.
-- Example:     CALL Staging_Load_Fact_KPI_Src_Stg_Hist(2574);
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.Staging_Load_Fact_KPI_Src_Stg_Hist`(
    IN p_ProcessID INT64
)
BEGIN
    DECLARE v_Component STRING DEFAULT 'Staging_Load_Fact_KPI_Src_Stg_Hist';
    DECLARE v_Step STRING DEFAULT 'Initialization';

    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Ended DATETIME;
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_EndDate DATETIME;
    DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();

    BEGIN
        SET v_Step = 'Part1';

        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_KPI_Src_Stg` (
            LabelNo, CountryCode, ScanDateTime, ScanType, ScanStatus, FranchiseeCode,
            CourierNumber, ScanDate, CreatedOn, FromRf, FromCf, ToRf, ToCf,
            ToLocality, ToPostalCode, RealisedDate, Zone, CustomerId
        )
        SELECT
            MF.LabelNo,
            MF.CountryCode,
            R.ScanDate,
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
        WHERE R.CountryName = 'Australia';

        SET v_Inserted = @@row_count;

        SET v_EndDate = DATETIME_SUB(DATETIME_TRUNC(v_Loaded, DAY), INTERVAL 1 MILLISECOND);
        CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_Set_LastValue`(
            'Fact_KPI_Scan', 'ScanDateTime', CAST(v_EndDate AS STRING), FALSE
        );

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

    EXCEPTION WHEN ERROR THEN
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
