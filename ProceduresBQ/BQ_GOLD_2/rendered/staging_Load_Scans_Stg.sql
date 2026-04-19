-- ==========================================================================================
-- Routine:     staging_Load_Scans_Stg
-- Description: Combines scan data into one table for loading into `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LNK_Scan_Stg`
--              BigQuery compatible version of Load_Scans_Stg
--              Note: WITH (TABLOCK) removed.
--                    ROLLBACK TRANSACTION removed (BQ procedures don't use explicit transactions).
--                    CONVERT(varchar,@LastId) replaced with CAST(... AS STRING).
--                    LEFT() on @Result replaced with STARTS_WITH().
--                    IIF replaced with IF.
-- Example:     CALL Staging.staging_Load_Scans_Stg(123)
-- History:
--  18/07/2020  P. Waldron      Routine Written
--  17/12/2020  B. Woods        Updated to insert rows from new TrackAndTrace_Stg source table
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.staging_Load_Scans_Stg`(
    IN ProcessID INT64
)
BEGIN

    DECLARE Component    STRING DEFAULT 'Staging.Load_Scans_Stg';
    DECLARE Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING;
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64 DEFAULT 0;
    DECLARE LastId       INT64 DEFAULT 0;
    DECLARE Loaded       DATETIME DEFAULT CURRENT_DATETIME();

    BEGIN

        INSERT INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_Scans_Stg`
        (
            FranchiseeCode,
            CourierNo,
            LabelNo,
            CountryName,
            ScanDate,
            ScanType,
            ScanStatus,
            Latitude,
            Longitude,
            RecordSource,
            RecordSourceId,
            Loaded,
            ProcessId,
            TrackAndTraceID,
            iLocate
        )
        SELECT
            FranchiseeCode,
            CourierNo,
            LabelNo,
            CountryName,
            ScanDate,
            ScanType,
            ScanStatus,
            Latitude,
            Longitude,
            RecordSource,
            RecordSourceId,
            Loaded,
            ProcessID,
            TrackAndTraceID,
            iLocate
        FROM (
            SELECT
                stg.FranchiseeCode,
                stg.CourierNo,
                stg.LabelNo,
                DC.CountryName,
                stg.ScanType,
                stg.ScanStatus,
                stg.ScanDate,
                IFNULL(stg.Latitude,  0) AS Latitude,
                IFNULL(stg.Longitude, 0) AS Longitude,
                MAX(stg.RecordId)        AS RecordSourceId,
                'Fastway.dbo.TrackAndTrace' AS RecordSource,
                MAX(stg.ID)              AS TrackAndTraceID,
                stg.iLocate,
                Loaded                   AS Loaded,
                ProcessID                AS ProcessId
            FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_TrackAndTrace_Stg` AS stg
            INNER JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_Dim_Country` DC ON DC.CountryCode = stg.CountryCode
            GROUP BY
                stg.FranchiseeCode,
                stg.CourierNo,
                stg.LabelNo,
                DC.CountryName,
                stg.ScanDate,
                stg.ScanType,
                stg.ScanStatus,
                IFNULL(stg.Latitude,  0),
                IFNULL(stg.Longitude, 0),
                stg.iLocate,
                Loaded,
                ProcessID
        ) Src;

        SET Inserted = @@ROW_COUNT;

        SET LastId = (
            SELECT MAX(ID)
            FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_TrackAndTrace_Stg`
        );

        SET Result       = 'Success';
        SET ErrorMessage = 'LastID = ' || CAST(LastId AS STRING);

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed - Last ID = ' || CAST(LastId AS STRING);
        SET ErrorMessage = @@error.message;

    END;

    -- Record load metrics in log
    SET Ended = CURRENT_DATETIME();
    CALL `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.Staging_SaveLog`(
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