-- ==========================================================================================
-- Routine:		Get_LastValue
-- Description: Gets the Last Id/Date used to query the source system for latest data
-- Example:		Exec [Staging].[Get_LastValue] 'LabelMaster'
-- History:
--	23/11/2018  P. Waldron		Routine Written
--	02/07/2019  P. Waldron		Refactor to use RecordSource instead of DatasetName
-- ==========================================================================================



CREATE OR REPLACE PROCEDURE `Staging.Get_LastValue`(
    IN p_RecordSource STRING
)
BEGIN
    -- ------------------------------------------------------------------------------------------
    -- Routine:     Get_LastValue
    -- Description: Gets the Last Id/Date used to query the source system for latest data
    -- History:
    --  23/11/2018  P. Waldron / AI  Routine converted to BigQuery
    -- ------------------------------------------------------------------------------------------

    DECLARE v_LastValue STRING;

    -- Look up the value from the LoadControl table
    SET v_LastValue = (
        SELECT LastValue 
        FROM `Staging.LoadControl`
        WHERE RecordSource = p_RecordSource
        LIMIT 1
    );

    -- Error Handling: If the RecordSource is missing, throw an error
    IF v_LastValue IS NULL THEN
        ERROR('RecordSource not in LoadControl table');
    END IF;

    -- Return the value as a result set
    SELECT v_LastValue AS LastValue;

END;