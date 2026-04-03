-- ==========================================================================================
-- Routine:		Get_LastValue_Scans
-- Description:   
--    Determines the starting Date (and RecordId) to use for reading data from the source system.
--    Three values are returned: StartId, LastDate and EndDate. 
--    For 'ScanDate' calcMethod, StartId and StartDate are obtained from the max RecordSourceId and ScanDate in dv.LNK_Scan
--    For 'UploadDate' calcMethod, StartId is 0 and UploadDate is obtained from Staging.LoadControl 
--    EndDate is the lesser of Now(), lastDate plus MaxDays or the value of @endDate. The latter allows backdated scans to be loaded.
-- Example:	Exec [Staging].[Get_LastValue_Scans] @RecordSource='tsections', @CalcMethod=N'UploadDate', @EndDate='2021-06-10', @MaxDays=5
--			Exec [Staging].[Get_LastValue_Scans] @RecordSource='tsections', @CalcMethod=N'RecordId', @EndDate='2021-06-10', @MaxDays=5
-- History:
--	17/06/2019  P. Waldron		Written 
--  30/10/2020  P. Waldron		Re-introduce 'RecordId' calc method
-- ==========================================================================================



CREATE OR REPLACE PROCEDURE `Staging.Get_LastValue_Scans`(
    IN p_RecordSource STRING,
    IN p_CalcMethod STRING,
    INOUT p_EndDate DATETIME,
    IN p_MaxDays INT64
)
BEGIN
    -- ------------------------------------------------------------------------------------------
    -- Routine:     Get_LastValue_Scans
    -- Description: Determines starting Date/ID for incremental loads.
    -- History:
    --  17/06/2019  P. Waldron / AI  Written and converted to BigQuery
    -- ------------------------------------------------------------------------------------------

    DECLARE v_LastDate DATETIME;
    DECLARE v_LastId INT64;
    DECLARE v_Offset INT64;

    -- 1. Determine Start ID and Last Date based on Calculation Method
    IF p_CalcMethod = 'ScanDate' THEN
        SELECT 
            MAX(RecordSourceId), 
            MAX(CAST(ScanDate AS DATETIME)) 
        INTO v_LastId, v_LastDate
        FROM `dv.LNK_Scan` 
        WHERE RecordSource = p_RecordSource;

    ELSE IF p_CalcMethod = 'UploadDate' THEN
        SELECT 
            0, 
            CAST(LastValue AS DATETIME)
        INTO v_LastId, v_LastDate
        FROM `Staging.LoadControl` 
        WHERE RecordSource = p_RecordSource;

    ELSE IF p_CalcMethod = 'RecordId' THEN
        SELECT 
            CAST(LastValue AS INT64),
            p_EndDate -- not used
        INTO v_LastId, v_LastDate
        FROM `Staging.LoadControl` 
        WHERE RecordSource = p_RecordSource;

    ELSE
        ERROR('Unsupported CalcMethod supplied');
    END IF;

    -- 2. Validation
    IF v_LastId IS NULL OR v_LastDate IS NULL THEN
        ERROR('Last Id/Date not found in LoadControl or Source');
    END IF;

    -- 3. Calculate End Date logic
    SET v_Offset = IF(p_CalcMethod = 'UploadDate', -1, 0);

    IF p_MaxDays > -99 THEN
        -- LEAST returns the minimum value among the arguments. 
        -- We COALESCE p_EndDate to a far-future date to handle NULL inputs correctly.
        SET p_EndDate = LEAST(
            DATETIME_ADD(v_LastDate, INTERVAL (p_MaxDays + v_Offset) DAY),
            DATETIME_ADD(CURRENT_DATETIME(), INTERVAL v_Offset DAY),
            COALESCE(p_EndDate, DATETIME '9999-12-31')
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