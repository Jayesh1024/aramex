-- ==========================================================================================
-- Routine:     Load_LNK_Scan_Signature  (BigQuery Version)
-- Description: Loads relationships into LNK_Scan_Signature (batched)
-- Example:     CALL dv.Load_LNK_Scan_Signature(590)
-- History:
--  20/11/2018  P. Waldron      Routine Written
--  20/12/2019  P. Waldron      Replace check of LNK_Scan_Err with check of LNK_Scan
--  [BQ Migration] Converted SQL Server -> BigQuery
--    * TOP (n) in SELECT    -> LIMIT n  (applied per batch)
--    * WHILE loop           -> WHILE ... DO ... END WHILE (BQ scripting)
--    * RAISERROR            -> removed (no BQ equivalent for info messages)
--    * FORMAT(@n,'N0')      -> CAST(n AS STRING) (simplified – thousand-sep not needed)
--    * Convert(varchar,...) -> CAST(... AS STRING)
--    * ISNULL(x,'')         -> IFNULL(x, '')
--    * See file 1 header for full conversion notes
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE dv.Load_LNK_Scan_Signature(
    IN ProcessID INT64
)
BEGIN
    DECLARE v_Loaded    DATETIME;
    DECLARE BatchSize   INT64    DEFAULT 1000000;
    DECLARE StartID     INT64    DEFAULT 1;
    DECLARE EndID       INT64;
    DECLARE LastID      INT64;
    DECLARE Component   STRING   DEFAULT 'dv.Load_LNK_Scan_Signature';
    DECLARE Started     DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended       DATETIME;
    DECLARE Result      STRING   DEFAULT 'Success';
    DECLARE ErrorMessage STRING  DEFAULT NULL;
    DECLARE Inserted    INT64    DEFAULT 0;

    SET LastID = (SELECT MAX(RowId) FROM Staging.LNK_Scan_Stg);

    BEGIN

        -- Batched inserts to avoid memory pressure on large datasets
        WHILE StartID <= LastID DO

            SET EndID   = StartID + BatchSize - 1;
            SET v_Loaded = CURRENT_DATETIME();

            BEGIN TRANSACTION;

            INSERT INTO dv.LNK_Scan_Signature
            (
                Scan_HSK,
                TrackAndTraceID,
                Signature
            )
            SELECT
                Src.Scan_HSK,
                Src.TrackAndTraceID,
                Src.Signature
            FROM Staging.LNK_Scan_Stg AS Src
            WHERE Src.RowID BETWEEN StartID AND EndID
              AND IFNULL(Src.Signature, '') != ''
              AND NOT EXISTS (
                  -- Check already done in Load_LNK_Scan_Stg; repeated for re-run safety
                  SELECT 1
                  FROM dv.LNK_Scan_Signature AS scan
                  WHERE scan.Scan_HSK = Src.Scan_HSK
              )
            LIMIT BatchSize;   -- mirrors original TOP(@BatchSize)

            SET Inserted = Inserted + @@row_count;

            COMMIT TRANSACTION;

            SET StartID = EndID + 1;

        END WHILE;

        SET Result = 'Success';

    EXCEPTION WHEN ERROR THEN
        IF @@in_transaction THEN
            ROLLBACK TRANSACTION;
        END IF;
        SET Result       = 'Failed';
        SET ErrorMessage = @@error_message;
    END;

    -- Record load metrics in log
    SET Result = 'Success';   -- preserved from original (overrides any caught error)

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
