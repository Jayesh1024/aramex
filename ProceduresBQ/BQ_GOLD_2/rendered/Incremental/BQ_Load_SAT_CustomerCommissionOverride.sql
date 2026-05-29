CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_SAT_CustomerCommissionOverride`(
    IN p_RecordSource STRING
)
BEGIN
    -- Logging Variables
    DECLARE v_Component STRING DEFAULT 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_Load_SAT_CustomerCommissionOverride';
    
    -- OPTION 2: Changed from TIMESTAMP to DATETIME
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;

    -- Working Variables
    DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
    
    -- Unused variables kept as requested
    DECLARE v_Step STRING;
    DECLARE v_delim STRING DEFAULT '\r'; -- Carriage Return

    BEGIN
        -- Multi-statement transaction to prevent downstream queries from reading an empty table
        BEGIN TRANSACTION;

            TRUNCATE TABLE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_CustomerCommissionOverride`;
            
            INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_CustomerCommissionOverride` (
                CountryCode, 
                RFCode, 
                CustomerId, 
                ProductId, 
                Percentage, 
                UpdatedOn, 
                UpdatedBy, 
                Loaded, 
                RecordSource
            )
            SELECT
                CountryCode,
                RFCode,
                CustomerId,
                ProductId,
                Percentage,
                UpdatedOn,
                UpdatedBy,
                v_Loaded AS Loaded,
                p_RecordSource AS RecordSource
            FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CustomerCommissionOverride_Stg`;

            SET v_Inserted = @@row_count;

        COMMIT TRANSACTION;

    EXCEPTION WHEN ERROR THEN
        -- Safely rollback the TRUNCATE if the INSERT fails
        ROLLBACK TRANSACTION;
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Record load metrics in log (Option 2: Using DATETIME and CURRENT_DATETIME)
    CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
        v_Component,
        -1,  
        v_Started,
        CURRENT_DATETIME(),
        v_Result,
        v_ErrorMessage,
        v_Inserted,
        -1,
        -1
    );

END;