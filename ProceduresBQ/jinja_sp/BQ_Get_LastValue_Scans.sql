{#-- ==========================================================================================
Routine:     Staging_Get_LastValue_Scans
Description: Determines starting Date/ID for incremental loads.
History:
  17/06/2019  P. Waldron / AI  Written and converted to BigQuery
========================================================================================== --#}

CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.Staging_Get_LastValue_Scans`(
    IN p_RecordSource STRING,
    IN p_CalcMethod STRING,
    INOUT p_EndDate DATETIME,
    IN p_MaxDays INT64
)
BEGIN
    -- OPTION 2: Ensuring all internal variables are DATETIME
    DECLARE v_LastDate DATETIME;
    DECLARE v_LastId INT64;
    DECLARE v_Offset INT64;

    -- 1. Determine Start ID and Last Date based on Calculation Method
    IF p_CalcMethod = 'ScanDate' THEN
        SET (v_LastId, v_LastDate) = (
            SELECT AS STRUCT 
                -- Added COALESCE to handle empty tables gracefully
                COALESCE(MAX(RecordSourceId), 0), 
                COALESCE(MAX(CAST(ScanDate AS DATETIME)), DATETIME '1900-01-01 00:00:00') 
            FROM `{{ project_id }}.{{ target_dataset_id }}.dv_LNK_Scan` 
            WHERE RecordSource = p_RecordSource
        );

    ELSEIF p_CalcMethod = 'UploadDate' THEN
        SET (v_LastId, v_LastDate) = (
            SELECT AS STRUCT 
                0, 
                CAST(LastValue AS DATETIME)
            FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_LoadControl` 
            WHERE RecordSource = p_RecordSource
        );

    ELSEIF p_CalcMethod = 'RecordId' THEN
        SET (v_LastId, v_LastDate) = (
            SELECT AS STRUCT 
                CAST(LastValue AS INT64),
                p_EndDate 
            FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_LoadControl` 
            WHERE RecordSource = p_RecordSource
        );

    ELSE
        RAISE USING MESSAGE = 'Unsupported CalcMethod supplied';
    END IF;

    -- 2. Validation
    IF v_LastId IS NULL OR v_LastDate IS NULL THEN
        RAISE USING MESSAGE = 'Last Id/Date not found in LoadControl or Source';
    END IF;

    -- 3. Calculate End Date logic
    SET v_Offset = IF(p_CalcMethod = 'UploadDate', -1, 0);

    IF p_MaxDays > -99 THEN
        -- OPTION 2: Using CURRENT_DATETIME() instead of CURRENT_TIMESTAMP()
        -- LEAST returns the minimum value among the arguments.
        SET p_EndDate = LEAST(
            DATETIME_ADD(v_LastDate, INTERVAL (p_MaxDays + v_Offset) DAY),
            DATETIME_ADD(CURRENT_DATETIME(), INTERVAL v_Offset DAY),
            COALESCE(p_EndDate, DATETIME '9999-12-31 23:59:59')
        );
    END IF;

    -- 4. Strip time if method is UploadDate
    IF p_CalcMethod = 'UploadDate' THEN
        SET v_LastDate = DATETIME(DATE(v_LastDate));
        SET p_EndDate = DATETIME(DATE(p_EndDate));
    END IF;

    -- 5. Final Output
    SELECT 
        IFNULL(v_LastId, 0) AS LastId, 
        v_LastDate AS LastDate, 
        p_EndDate AS EndDate;

END;