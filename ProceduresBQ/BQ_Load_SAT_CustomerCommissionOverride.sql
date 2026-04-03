
			 
-- ==========================================================================================
-- Routine:		Load_SAT_CustomerCommissionOverride
-- Description: 	Loads table SAT_CustomerCommissionOverride
-- Example:		Exec [DV].[Load_SAT_FL_Zones]  'Fastway_PriceOverrides'  
-- History:
--	25/09/2024	B. Woods		Routine Written
-- ==========================================================================================


CREATE OR REPLACE PROCEDURE `dv.Load_SAT_CustomerCommissionOverride`(
    IN p_RecordSource STRING
)
BEGIN
    -- Logging Variables
    DECLARE v_Component STRING DEFAULT 'dv.Load_SAT_CustomerCommissionOverride';
    DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
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
        -- during the window between TRUNCATE and INSERT.
        BEGIN TRANSACTION;

            TRUNCATE TABLE `dv.SAT_CustomerCommissionOverride`;
            
            INSERT INTO `dv.SAT_CustomerCommissionOverride` (
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
            FROM `Staging.CustomerCommissionOverride_Stg`;

            SET v_Inserted = @@row_count;

        COMMIT TRANSACTION;

    EXCEPTION WHEN ERROR THEN
        -- Safely rollback the TRUNCATE if the INSERT fails
        ROLLBACK TRANSACTION;
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Record load metrics in log
    CALL `Staging.SaveLog`(
        v_Component,
        -1,  -- Hardcoded -1 as per the original script
        v_Started,
        CURRENT_TIMESTAMP(),
        v_Result,
        v_ErrorMessage,
        v_Inserted,
        0,
        IF(v_Result = 'Success', 0, -1)
    );

END;