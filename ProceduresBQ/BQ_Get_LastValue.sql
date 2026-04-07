{#-- ==========================================================================================
Routine:		Get_LastValue
Description: Gets the Last Id/Date used to query the source system for latest data
History:
	23/11/2018  P. Waldron		Routine Written
	02/07/2019  P. Waldron		Refactor to use RecordSource instead of DatasetName
========================================================================================== --#}

CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id}}.Staging_Get_LastValue`(
    IN p_RecordSource STRING
)
BEGIN
    -- ------------------------------------------------------------------------------------------
    -- Routine:     Get_LastValue
    -- Description: Gets the Last Id/Date used to query the source system for latest data
    -- ------------------------------------------------------------------------------------------

    DECLARE v_LastValue STRING;

    -- Look up the value from the LoadControl table
    -- Table naming rule: Staging.LoadControl -> Staging_LoadControl
    SET v_LastValue = (
        SELECT LastValue 
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_LoadControl`
        WHERE RecordSource = p_RecordSource
        LIMIT 1
    );

    -- Error Handling: In BigQuery, we use RAISE USING MESSAGE
    IF v_LastValue IS NULL THEN
        RAISE USING MESSAGE = 'RecordSource not in LoadControl table';
    END IF;

    -- Return the value as a result set
    SELECT v_LastValue AS LastValue;

END;