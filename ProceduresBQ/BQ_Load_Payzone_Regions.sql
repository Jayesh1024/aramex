{#-- ==========================================================================================
Routine:     dbo_Load_Payzone_Regions
Description: Loads any labels into dbo_Payzone_Regions
History:
  13/05/2025  B. Woods        Routine Written
========================================================================================== --#}

CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id}}.dbo_Load_Payzone_Regions`(
    IN p_ProcessID INT64
)
BEGIN
    -- ------------------------------------------------------------------------------------------
    -- Routine:     dbo_Load_Payzone_Regions
    -- Description: Upserts regions into dbo_Payzone_Regions using a MERGE statement
    -- ------------------------------------------------------------------------------------------

    DECLARE v_Component STRING DEFAULT '{{ project_id }}.{{ target_dataset_id }}.dbo_Load_Payzone_Regions';
    DECLARE v_Step STRING DEFAULT 'Upsert';
    DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Ended TIMESTAMP;
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING DEFAULT NULL;
    DECLARE v_AffectedRows INT64 DEFAULT 0;

    BEGIN
        -- BigQuery MERGE performs the update and insert in one pass
        MERGE INTO `{{ project_id }}.{{ target_dataset_id }}.dbo_Payzone_Regions` AS Tgt
        USING `{{ project_id }}.{{ target_dataset_id }}.Staging_payzone_regions_stg` AS Src
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

    -- Final Log Call
    SET v_Ended = CURRENT_TIMESTAMP();
    
    CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,
        v_Ended,
        v_Result,
        v_ErrorMessage,
        0,              -- Inserted (Combined into AffectedRows for MERGE)
        v_AffectedRows, -- Updated (Combined into AffectedRows for MERGE)
        IF(v_Result = 'Success', 0, -1)
    );

END;