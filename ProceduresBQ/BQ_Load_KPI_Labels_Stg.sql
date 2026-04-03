CREATE OR REPLACE PROCEDURE `Staging.Load_KPI_Labels_Stg`(
    IN p_ProcessID INT64,
    IN p_SinceScanDate DATETIME,
    IN p_UntilScanDate DATETIME,
    IN p_UseScanDates INT64   -- Pass 1 for True, 0 for False (replacing bit = 0)
)
BEGIN
    -- Variables Setup
    DECLARE v_Component STRING DEFAULT 'Staging.Load_KPI_Labels_Stg';
    DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;

    DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_MaxID INT64;
    DECLARE v_LastID INT64;

    -- Fetch bounds
    SET v_MaxID = (SELECT MAX(TrackAndTraceID) FROM `dv.LNK_Scan`);
    
    SET v_LastID = (
        SELECT SAFE_CAST(LastValue AS INT64) 
        FROM `Staging.LoadControl` 
        WHERE RecordSource = 'TrackAndTraceID'
    );

    BEGIN
        -- Insert unique KPI labels
        INSERT INTO `Staging.KPI_Labels_Stg` (
            LabelNo, 
            Loaded, 
            ProcessId
        )
        SELECT DISTINCT 
            scan.LabelNo, 
            v_Loaded, 
            p_ProcessId 
        FROM (
            SELECT LabelNo, CountryName 
            FROM `dv.LNK_Scan`
            WHERE CountryName IN ('Australia', 'New Zealand', 'South Africa')
              AND TrackAndTraceID > COALESCE(v_LastID, 0) 
              AND TrackAndTraceID <= COALESCE(v_MaxID, 0)
            
            UNION ALL  -- Using ALL since the outer query handles DISTINCT
            
            SELECT LabelNo, CountryName 
            FROM `dv.LNK_Scan` 
            WHERE p_UseScanDates = 1 
              AND p_SinceScanDate IS NOT NULL 
              AND p_UntilScanDate IS NOT NULL
              AND ScanDate >= DATETIME_SUB(CURRENT_DATETIME(), INTERVAL 3 MONTH)
              AND (
                  (ScanDate BETWEEN p_SinceScanDate AND p_UntilScanDate) 
                  OR 
                  (Loaded BETWEEN p_SinceScanDate AND p_UntilScanDate)
              )
              AND CountryName IN ('Australia', 'New Zealand', 'South Africa')
        ) scan
        WHERE LENGTH(scan.LabelNo) = 12
          AND NOT EXISTS ( 
              SELECT 1 FROM `dbo.KPIExcludedLabels` excl
              WHERE excl.CountryName = scan.CountryName 
                AND excl.LabelPrefix = SUBSTR(scan.LabelNo, 1, 2) 
          )
          AND scan.LabelNo NOT IN ('000000000001', '000000000002') 
          AND SUBSTR(scan.LabelNo, 1, 3) NOT IN ('LEA', 'FWD');

        SET v_Inserted = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Record load metrics in log
    CALL `Staging.SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,
        CURRENT_TIMESTAMP(),
        v_Result,
        v_ErrorMessage,
        v_Inserted,
        0,
        IF(v_Result = 'Success', 0, -1)
    );

END;