-- ==========================================================================================
-- Routine:     dv_Load_LNK_Scan
-- Description: Loads relationships into LNK_Scan.
--              BigQuery compatible version of Load_LNK_Scan
--              Note: Batch WHILE loop removed - BigQuery handles large inserts natively.
--                    dbo.GetHashKey replaced with TO_HEX(MD5(...)).
--                    FORMAT() and RAISERROR removed (not supported in BQ).
-- Example:     CALL dv.dv_Load_LNK_Scan(590)
-- History:
--  20/11/2018  P. Waldron      Routine Written
--  20/12/2019  P. Waldron      Replace check of LNK_Scan_Err with check of LNK_Scan
--  [BQ Port]   Converted from SQL Server to BigQuery
--  [BQ Fix]    TO_HEX(MD5(...)) → MD5(...) in all COALESCE fallbacks
--              (HSK columns are BYTES; COALESCE cannot mix BYTES and STRING)
--  [BQ Fix]    SaveLog → Staging_SaveLog with additional -1, -1 arguments.
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `searce-sandbox-da-delivery.Aramex_oceania_SP.dv_Load_LNK_Scan`(
    IN ProcessID INT64
)
BEGIN

    DECLARE Loaded       DATETIME DEFAULT CURRENT_DATETIME();

    DECLARE Component    STRING DEFAULT 'dv.Load_LNK_Scan';
    DECLARE Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING;
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64 DEFAULT 0;

    BEGIN

        INSERT INTO `searce-sandbox-da-delivery.Aramex_oceania.dv_LNK_Scan`
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
            Scan_HSK,
            -- MD5 returns BYTES to match target BYTES column type
            -- COALESCE requires both args to be same type (BYTES); TO_HEX removed
            COALESCE(FranchiseeCode_HSK, MD5(FranchiseeCode))                                          AS FranchiseeCode_HSK,
            COALESCE(Courier_HSK,        MD5(FranchiseeCode || '^' || CourierNumber))                  AS Courier_HSK,
            COALESCE(LabelNo_HSK,        MD5(LabelNo))                                                 AS LabelNo_HSK,
            COALESCE(Location_HSK,       MD5(CAST(Latitude AS STRING) || '^' || CAST(Longitude AS STRING))) AS Location_HSK,
            COALESCE(ScanStatus_HSK,     MD5(ScanStatus || '^' || CountryName))                        AS ScanStatus_HSK,
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
            ProcessID,
            RecordSource,
            RecordSourceId,
            TrackAndTraceID,
            iLocate,
            UploadDate
        FROM `searce-sandbox-da-delivery.Aramex_oceania.Staging_LNK_Scan_Stg` AS Src
        ORDER BY Src.ScanDate DESC;

        SET Inserted = @@ROW_COUNT;
        SET Result   = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed';
        SET ErrorMessage = @@error.message;

    END;

    -- Record load metrics in log
    SET Result = 'Success';
    SET Ended  = CURRENT_DATETIME();
    CALL `searce-sandbox-da-delivery.Aramex_oceania_SP.Staging_SaveLog`(
        Component,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted,
        -1,
        -1
    );

END;