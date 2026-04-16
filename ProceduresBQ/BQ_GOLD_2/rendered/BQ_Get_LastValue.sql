CREATE OR REPLACE PROCEDURE `searce-sandbox-da-delivery.Aramex_oceania_SP.Staging_Get_LastValue`(
    IN p_RecordSource STRING
)
BEGIN
    -- ------------------------------------------------------------------------------------------
    -- Routine:     Staging_Get_LastValue
    -- Description: Gets the Last Id/Date used to query the source system for latest data
    -- ------------------------------------------------------------------------------------------

    DECLARE v_LastValue STRING;

    -- Applied Option 2 Naming Logic: ..Table_Name (using underscore for schema)
    SET v_LastValue = (
        SELECT LastValue 
        FROM `searce-sandbox-da-delivery.Aramex_oceania.Staging_LoadControl`
        WHERE RecordSource = p_RecordSource
        LIMIT 1
    );

    -- Error Handling using BigQuery native RAISE syntax
    IF v_LastValue IS NULL THEN
        RAISE USING MESSAGE = 'RecordSource not in LoadControl table';
    END IF;

    -- Return the value as a result set
    SELECT v_LastValue AS LastValue;

END;