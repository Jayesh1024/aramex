-- ==========================================================================================
-- Routine:     Load_LNK_Scan  (BigQuery Version)
-- Description: Loads relationships into LNK_Scan
-- Example:     CALL dv.Load_LNK_Scan(590)
-- History:
--  20/11/2018  P. Waldron      Routine Written
--  20/12/2019  P. Waldron      Replace check of LNK_Scan_Err with check of LNK_Scan
--  [BQ Migration] Converted SQL Server -> BigQuery
--    * dbo.GetHashKey(key, default) -> TO_HEX(MD5(key))
--      If a BQ UDF `GetHashKey` exists in your project, replace with it.
--    * COALESCE(HSK, dbo.GetHashKey(...)) -> COALESCE(HSK, TO_HEX(MD5(...)))
--    * convert(varchar(16),col) -> CAST(col AS STRING)
--    * FORMAT(@n,'N0')          -> CAST(n AS STRING) (simplified)
--    * RAISERROR                -> removed
--    * See file 1 header for full conversion notes
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE dv.Load_LNK_Scan(
    IN ProcessID INT64
)
BEGIN
    DECLARE v_Loaded    DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE LastID      INT64;
    DECLARE Component   STRING   DEFAULT 'dv.Load_LNK_Scan';
    DECLARE Started     DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended       DATETIME;
    DECLARE Result      STRING   DEFAULT 'Success';
    DECLARE ErrorMessage STRING  DEFAULT NULL;
    DECLARE Inserted    INT64    DEFAULT 0;

    SET LastID = (SELECT MAX(RowId) FROM Staging.LNK_Scan_Stg);

    INSERT INTO dv.LNK_Scan
    (
        Scan_HSK,
        FranchiseeCode_HSK,
        Courier_HSK,
        LabelNo_HSK,
        Location_HSK,
        ScanStatus_HSK,
        FranchiseeCode,
        CourierNumber,
        LabelNo,
        Latitude,
        Longitude,
        ScanStatus,
        CountryName,
        ScanDate,
        ScanType,
        Loaded,
        ProcessId,
        RecordSource,
        RecordSourceId,
        TrackAndTraceID,
        iLocate,
        UploadDate
    )
    SELECT
        Src.Scan_HSK,
        -- Fall back to a computed hash if staging did not pre-compute the HSK columns
        COALESCE(Src.FranchiseeCode_HSK, TO_HEX(MD5(Src.FranchiseeCode)))                              AS FranchiseeCode_HSK,
        COALESCE(Src.Courier_HSK,        TO_HEX(MD5(CONCAT(Src.FranchiseeCode, '^', Src.CourierNumber))))  AS Courier_HSK,
        COALESCE(Src.LabelNo_HSK,        TO_HEX(MD5(Src.LabelNo)))                                     AS LabelNo_HSK,
        COALESCE(Src.Location_HSK,       TO_HEX(MD5(CONCAT(CAST(Src.Latitude AS STRING), '^', CAST(Src.Longitude AS STRING))))) AS Location_HSK,
        COALESCE(Src.ScanStatus_HSK,     TO_HEX(MD5(CONCAT(Src.ScanStatus, '^', Src.CountryName))))    AS ScanStatus_HSK,
        Src.FranchiseeCode,
        Src.CourierNumber,
        Src.LabelNo,
        Src.Latitude,
        Src.Longitude,
        Src.ScanStatus,
        Src.CountryName,
        Src.ScanDate,
        Src.ScanType,
        v_Loaded        AS Loaded,
        ProcessID       AS ProcessId,
        Src.RecordSource,
        Src.RecordSourceId,
        Src.TrackAndTraceID,
        Src.iLocate,
        Src.UploadDate
    FROM Staging.LNK_Scan_Stg AS Src
    -- Note: ORDER BY in INSERT is preserved from original; BQ executes it on the SELECT
    -- but does not guarantee physical row order in the stored table.
    ORDER BY Src.ScanDate DESC;

    SET Inserted = Inserted + @@row_count;
    SET Result   = 'Success';

    -- Record load metrics in log
    SET Result = 'Success';   -- preserved from original

    SET Ended = CURRENT_DATETIME();
    CALL Staging.SaveLog(
        Component,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted
    );

END;
