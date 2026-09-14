CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_Get_LastValue`(
    IN p_RecordSource STRING
)
BEGIN
    -- ------------------------------------------------------------------------------------------
    -- Routine:     Staging_Get_LastValue
    -- Description: Gets the Last Id/Date used to query the source system for latest data
    -- ------------------------------------------------------------------------------------------

    DECLARE v_LastValue STRING;

    SET v_LastValue = (
        SELECT LastValue 
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_LoadControl`
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