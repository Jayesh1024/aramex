-- ==========================================================================================
-- Routine:     BQ_Load_LNK_Scan_Signature
-- Description: Loads relationships into LNK_Scan_Signature.
--              BigQuery compatible version of Load_LNK_Scan_Signature
--              Note: Batch loop removed - BigQuery handles large inserts natively.
-- Example:     CALL dv.BQ_Load_LNK_Scan_Signature(590)
-- History:
--  20/11/2018  P. Waldron      Routine Written
--  20/12/2019  P. Waldron      Replace check of LNK_Scan_Err with check of LNK_Scan
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.BQ_Load_LNK_Scan_Signature`(
    IN ProcessID INT64
)
BEGIN

    DECLARE Loaded       DATETIME DEFAULT CURRENT_DATETIME();

    DECLARE Component    STRING DEFAULT 'dv.Load_LNK_Scan_Signature';
    DECLARE Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING;
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64 DEFAULT 0;

    BEGIN

        -- BigQuery handles large inserts natively; the SQL Server WHILE batch loop
        -- is not needed. Single INSERT replacing the batched approach.
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_LNK_Scan_Signature`
        (
            Scan_HSK,
            TrackAndTraceID,
            Signature
        )
        SELECT
            Src.Scan_HSK,
            Src.TrackAndTraceID,
            Src.Signature
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_LNK_Scan_Stg` AS Src
        WHERE IFNULL(Src.Signature, '') <> ''
          AND NOT EXISTS (
              -- Check already done in Load_LNK_Scan_Stg but kept here in case routine is re-run
              SELECT 1
              FROM `{{ project_id }}.{{ target_dataset_id }}.dv_LNK_Scan_Signature` AS scan
              WHERE scan.Scan_HSK = Src.Scan_HSK
          );

        SET Inserted = @@ROW_COUNT;
        SET Result   = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed';
        SET ErrorMessage = @@error.message;

    END;

    -- Record load metrics in log
    SET Result = 'Success';
    SET Ended  = CURRENT_DATETIME();
    CALL `{{ project_id }}.{{ sp_dataset_id }}.SaveLog`(
        Component,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted
    );

END;
