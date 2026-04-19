CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.dbo_Load_Payzone_Regions`(
    IN p_ProcessID INT64
)
BEGIN
    -- ------------------------------------------------------------------------------------------
    -- Routine:     dbo_Load_Payzone_Regions
    -- Description: Upserts regions into dbo_Payzone_Regions using a MERGE statement
    -- ------------------------------------------------------------------------------------------

    DECLARE v_Component STRING DEFAULT 'prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_Load_Payzone_Regions';
    DECLARE v_Step STRING DEFAULT 'Upsert';
    
    -- OPTION 2: Changed from TIMESTAMP to DATETIME
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Ended DATETIME;
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING DEFAULT NULL;
    DECLARE v_AffectedRows INT64 DEFAULT 0;

    BEGIN
        -- BigQuery MERGE performs the update and insert in one pass
        MERGE INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_Payzone_Regions` AS Tgt
        USING `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_payzone_regions_stg` AS Src
        ON Tgt.id = Src.id
        
        WHEN MATCHED THEN
            UPDATE SET
                franchisee_code = Src.franchisee_code,
                region_company_name = Src.region_company_name,
                region_company_phone = Src.region_company_phone,
                region_address = Src.region_address,
                region_company_email = Src.region_company_email,
                secondary_franchisee_codes = Src.secondary_franchisee_codes,
                CountryId = Src.CountryId,
                SYS_CHANGE_VERSION = Src.SYS_CHANGE_VERSION

        WHEN NOT MATCHED THEN
            INSERT (
                id, 
                franchisee_code, 
                region_company_name, 
                region_company_phone, 
                region_address, 
                region_company_email, 
                secondary_franchisee_codes, 
                CountryId, 
                SYS_CHANGE_VERSION
            )
            VALUES (
                Src.id, 
                Src.franchisee_code, 
                Src.region_company_name, 
                Src.region_company_phone, 
                Src.region_address, 
                Src.region_company_email, 
                Src.secondary_franchisee_codes, 
                Src.CountryId, 
                Src.SYS_CHANGE_VERSION
            );

        -- Capture total affected rows
        SET v_AffectedRows = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = FORMAT('Failed (%s)', v_Step);
        SET v_ErrorMessage = @@error.message;
    END;

    -- OPTION 2: Changed from CURRENT_TIMESTAMP() to CURRENT_DATETIME()
    SET v_Ended = CURRENT_DATETIME();
    
    -- Final Log Call
    CALL `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.Staging_SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,      -- Now a DATETIME
        v_Ended,        -- Now a DATETIME
        v_Result,
        v_ErrorMessage,
        -1,              -- Inserted (Combined into AffectedRows for MERGE)
        v_AffectedRows, -- Updated (Combined into AffectedRows for MERGE)
        -1
    );

END;