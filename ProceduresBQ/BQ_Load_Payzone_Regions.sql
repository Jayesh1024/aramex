-- ==========================================================================================
-- Routine:     Load_Payzone_Regions]
-- Description: Loads any labels into [dbo].[Payzone_Regions]]
-- Example:     Exec [dbo].[Load_Payzone_Regions]] 30
-- History:
--  13/05/2025  B. Woods        Routine Written
--
-- ==========================================================================================


CREATE OR REPLACE PROCEDURE `dbo.Load_Payzone_Regions`(
    IN p_ProcessID INT64
)
BEGIN
    -- ------------------------------------------------------------------------------------------
    -- Routine:     Load_Payzone_Regions
    -- Description: Upserts regions into dbo.Payzone_Regions using a MERGE statement
    -- History:
    --  13/05/2025  B. Woods / AI   Routine written and converted to BigQuery
    -- ------------------------------------------------------------------------------------------

    DECLARE v_Component STRING DEFAULT 'dbo.Load_Payzone_Regions';
    DECLARE v_Step STRING DEFAULT 'Upsert';
    DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Ended TIMESTAMP;
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING DEFAULT NULL;
    DECLARE v_AffectedRows INT64 DEFAULT 0;

    BEGIN
        -- BigQuery MERGE performs the update and insert in one pass
        MERGE INTO `dbo.Payzone_Regions` AS Tgt
        USING `Staging.payzone_regions_stg` AS Src
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
    
    CALL `Staging.SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,
        v_Ended,
        v_Result,
        v_ErrorMessage,
        0,              -- Inserted (Combined into AffectedRows for MERGE)
        v_AffectedRows, -- Updated (Combined into AffectedRows for MERGE)
        -1              -- Standard return/status code
    );

END;