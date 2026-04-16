{#-- ==========================================================================================
Routine:		dv_Load_SAT_CustomerCommissionOverride
Description: 	Loads table SAT_CustomerCommissionOverride
History:
	25/09/2024	B. Woods		Routine Written
========================================================================================== --#}

CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_SAT_CustomerCommissionOverride`(
    IN p_RecordSource STRING
)
BEGIN
    -- Logging Variables
    DECLARE v_Component STRING DEFAULT '{{ project_id }}.{{ target_dataset_id }}.dv_Load_SAT_CustomerCommissionOverride';
    
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

            TRUNCATE TABLE `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_CustomerCommissionOverride`;
            
            INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_CustomerCommissionOverride` (
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
            FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_CustomerCommissionOverride_Stg`;

            SET v_Inserted = @@row_count;

        COMMIT TRANSACTION;

    EXCEPTION WHEN ERROR THEN
        -- Safely rollback the TRUNCATE if the INSERT fails
        ROLLBACK TRANSACTION;
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Record load metrics in log (Option 2: Using DATETIME and CURRENT_DATETIME)
    CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
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