-- ==========================================================================================
-- Routine:     Load_SAT_BLKContainerManifest  (BigQuery Version)
-- Description: Loads SAT_BLKContainerManifest (full-replace pattern)
-- Example:     CALL dv.Load_SAT_BLKContainerManifest(-2, 'BLK_ManifestID')
-- History:
--  30/05/2024  B. Woods      Routine Written
--  [BQ Migration] Converted SQL Server -> BigQuery
--    * TRUNCATE TABLE inside BEGIN TRANSACTION -> replaced with DELETE FROM ... WHERE TRUE
--      BQ does NOT allow DDL (TRUNCATE) inside explicit transactions; DELETE is DML and is
--      transaction-safe. Functionally identical – removes all rows before the INSERT.
--    * INSERT ... WITH (TABLOCK) -> INSERT ... (hint removed; not applicable in BQ)
--    * IIF() -> IF()
--    * OBJECT_NAME(@@PROCID) -> hardcoded string
--    * See file 1 header for full conversion notes
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE dv.Load_SAT_BLKContainerManifest(
    IN ProcessID    INT64,
    IN RecordSource STRING   -- Pass NULL to use default 'BLK_ManifestID'
)
BEGIN
    DECLARE v_Loaded        DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_RecordSource  STRING   DEFAULT IFNULL(RecordSource, 'BLK_ManifestID');
    DECLARE Component       STRING   DEFAULT IF(
                                         TRUE,   -- always has a proc name in BQ
                                         'dv.Load_SAT_BLKContainerManifest',
                                         'dv.Load_SAT_BLKContainerManifest'
                                     );
    DECLARE Started         DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended           DATETIME;
    DECLARE Result          STRING   DEFAULT 'Success';
    DECLARE ErrorMessage    STRING   DEFAULT NULL;
    DECLARE Inserted        INT64    DEFAULT 0;

    BEGIN

        BEGIN TRANSACTION;

        -- Full-replace: delete all rows first (replaces TRUNCATE which can't run in a BQ transaction)
        DELETE FROM dv.SAT_BLKContainerManifest WHERE TRUE;

        INSERT INTO dv.SAT_BLKContainerManifest
        SELECT
            ContainerManifestId,
            ContainerId,
            ContainerBarcode,
            Location,
            Destination,
            TotalParcels,
            Status,
            ActionDate,
            IsMixed,
            MixedUnknownDest,
            CurrentLocation,
            CountryCode,
            Sortation,
            SortationStatus,
            SortationOpen,
            SortationClosed,
            Started         AS Loaded,
            ProcessID       AS ProcessID,
            v_RecordSource  AS RecordSource
        FROM Staging.BLK_ContainerManifest_Stg;

        SET Inserted = @@row_count;

        COMMIT TRANSACTION;
        SET Result = 'Success';

    EXCEPTION WHEN ERROR THEN
        IF @@in_transaction THEN
            ROLLBACK TRANSACTION;
        END IF;
        SET Result       = 'Failed';
        SET ErrorMessage = @@error_message;
    END;

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
