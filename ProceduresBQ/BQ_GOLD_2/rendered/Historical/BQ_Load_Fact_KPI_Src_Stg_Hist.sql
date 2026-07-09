-- ==========================================================================================
-- Routine:     Load_Fact_KPI_Src_Stg_Hist
-- Description: One-shot historical load of Fact KPI source scans from dv_LNK_Scan.
--              No LoadControl window, no late-upload catch-up (Part 2), no watermark update.
-- Example:     CALL Staging_Load_Fact_KPI_Src_Stg_Hist(2574);
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_Load_Fact_KPI_Src_Stg_Hist`(
    IN p_ProcessID INT64
)
BEGIN
    -- Core Variables
    DECLARE v_Component STRING DEFAULT 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Load_Fact_KPI_Src_Stg';
    DECLARE v_Step STRING DEFAULT 'Initialization';

    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Ended DATETIME;
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;

    BEGIN
        SET v_Step = 'Part1';

        INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_KPI_Src_Stg` (
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
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Scan` R 
        JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF` MF 
            ON MF.CountryCode = R.CountryCode
            AND MF.LabelNo = R.LabelNo 
            AND MF.IsCurrent = 1 
            AND MF.RealisedDate IS NOT NULL
        WHERE (UPPER(R.CountryName) = 'AUSTRALIA' OR UPPER(R.CountryName) = 'NEW ZEALAND');

        SET v_Inserted = @@row_count;

        SET v_Ended = CURRENT_DATETIME();
        CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
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
        -- Catch errors and log them accurately based on the v_Step it failed on
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
        
        CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
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
