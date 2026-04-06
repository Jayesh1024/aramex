-- ==========================================================================================
-- Routine:     Load_LNK_Scan_SignatureAI  (BigQuery Version)
-- Description: Loads attributes into LNK_Scan_SignatureAI
-- Example:     CALL dv.Load_LNK_Scan_SignatureAI(123, 'TTSignatureAI')
-- History:
--  08/04/2025  B. Woods        Cloned
--  [BQ Migration] Converted SQL Server -> BigQuery
--    * CREATE TABLE #temp      -> CREATE TEMP TABLE (BQ temp tables, session-scoped)
--    * IF OBJECT_ID(#tmp)...   -> DROP TABLE IF EXISTS
--    * IIF()                   -> IF()
--    * EXCEPT (set op)         -> EXCEPT DISTINCT
--    * UPDATE ... FROM JOIN    -> BQ UPDATE ... FROM ... WHERE syntax
--    * RAISERROR               -> removed
--    * CONVERT(varchar(10),n)  -> CAST(n AS STRING)
--    * REPLACE(':1:',...)      -> REPLACE with CAST
--    * See file 1 header for full conversion notes
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE dv.Load_LNK_Scan_SignatureAI(
    IN ProcessID    INT64,
    IN RecordSource STRING   -- Pass NULL to use default 'TTSignatureAI'
)
BEGIN
    DECLARE v_Loaded        DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_RecordSource  STRING   DEFAULT IFNULL(RecordSource, 'TTSignatureAI');
    DECLARE Component       STRING   DEFAULT 'LNK_Scan_SignatureAI';
    DECLARE Started         DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended           DATETIME;
    DECLARE Result          STRING   DEFAULT 'Success';
    DECLARE ErrorMessage    STRING   DEFAULT NULL;
    DECLARE Inserted        INT64    DEFAULT 0;
    DECLARE Updated         INT64    DEFAULT 0;

    -- Build the work set (Inserts and Updates)
    DROP TABLE IF EXISTS _ScansToProcess;

    CREATE TEMP TABLE _ScansToProcess (
        TrackAndTraceID INT64,
        ActionType      STRING   -- 'I' = Insert, 'U' = Update
    );

    INSERT INTO _ScansToProcess (TrackAndTraceID, ActionType)
    SELECT
        Stg.TrackAndTraceId,
        IF(Tgt.TrackAndTraceID IS NULL, 'I', 'U') AS ActionType
    FROM InterimStaging.TrackAndTraceData_SignatureAI_Stg AS Stg
    LEFT JOIN dv.LNK_Scan_SignatureAI AS Tgt
        ON Tgt.TrackAndTraceID = Stg.TrackAndTraceID
    ORDER BY Stg.TrackAndTraceId;

    IF (SELECT COUNT(*) FROM _ScansToProcess) = 0 THEN
        SET Result = 'Success';
    ELSE

        BEGIN

            -- ── UPDATE existing records where data has changed ───────────────────────
            UPDATE dv.LNK_Scan_SignatureAI AS Tgt
            SET
                TrackAndTraceId     = Src.TrackAndTraceId,
                AILabel             = Src.AILabel,
                AIScore             = Src.AIScore,
                AIVersion           = Src.AIVersion,
                UserLabel           = Src.UserLabel,
                ValidatedByUsername = Src.ValidatedByUsername,
                CourierNo           = Src.CourierNo,
                FranchiseeCode      = Src.FranchiseeCode,
                ScanDate            = Src.ScanDate,
                LastUpdatedOn       = Src.LastUpdatedOn,
                TrainingLabel       = Src.TrainingLabel,
                Loaded              = v_Loaded,
                ProcessId           = ProcessID,
                RecordSource        = v_RecordSource
            FROM (
                SELECT
                    Stg.TrackAndTraceId,
                    Stg.AILabel,
                    Stg.AIScore,
                    Stg.AIVersion,
                    Stg.UserLabel,
                    Stg.ValidatedByUsername,
                    Stg.CourierNo,
                    Stg.FranchiseeCode,
                    Stg.ScanDate,
                    Stg.LastUpdatedOn,
                    Stg.TrainingLabel
                FROM InterimStaging.TrackAndTraceData_SignatureAI_Stg AS Stg
                JOIN _ScansToProcess AS sel
                    ON sel.TrackAndTraceId = Stg.TrackAndTraceId
                   AND sel.ActionType = 'U'
            ) AS Src
            WHERE Tgt.TrackAndTraceId = Src.TrackAndTraceId
              AND EXISTS (
                  -- Only update if something actually changed (EXCEPT DISTINCT = changed)
                  SELECT Src.AILabel, Src.AIScore, Src.AIVersion,
                         Src.UserLabel, Src.ValidatedByUsername, Src.CourierNo,
                         Src.FranchiseeCode, Src.ScanDate, Src.LastUpdatedOn, Src.TrainingLabel
                  EXCEPT DISTINCT
                  SELECT Tgt.AILabel, Tgt.AIScore, Tgt.AIVersion,
                         Tgt.UserLabel, Tgt.ValidatedByUsername, Tgt.CourierNo,
                         Tgt.FranchiseeCode, Tgt.ScanDate, Tgt.LastUpdatedOn, Tgt.TrainingLabel
              );

            SET Updated = @@row_count;

            -- ── INSERT new records ───────────────────────────────────────────────────
            INSERT INTO dv.LNK_Scan_SignatureAI
            (
                TrackAndTraceId,
                AILabel,
                AIScore,
                AIVersion,
                UserLabel,
                ValidatedByUsername,
                CourierNo,
                FranchiseeCode,
                ScanDate,
                LastUpdatedOn,
                TrainingLabel,
                Loaded,
                ProcessId,
                RecordSource
            )
            SELECT
                Stg.TrackAndTraceId,
                Stg.AILabel,
                Stg.AIScore,
                Stg.AIVersion,
                Stg.UserLabel,
                Stg.ValidatedByUsername,
                Stg.CourierNo,
                Stg.FranchiseeCode,
                Stg.ScanDate,
                Stg.LastUpdatedOn,
                Stg.TrainingLabel,
                v_Loaded,
                ProcessID,
                v_RecordSource
            FROM InterimStaging.TrackAndTraceData_SignatureAI_Stg AS Stg
            JOIN _ScansToProcess AS sel
                ON sel.TrackAndTraceId = Stg.TrackAndTraceId
               AND sel.ActionType = 'I';

            SET Inserted = Inserted + @@row_count;
            SET Result   = 'Success';

        EXCEPTION WHEN ERROR THEN
            SET Result       = 'Failed';
            SET ErrorMessage = @@error_message;
        END;

    END IF;

    DROP TABLE IF EXISTS _ScansToProcess;

    -- Record load metrics in log
    SET Ended = CURRENT_DATETIME();
    CALL Staging.SaveLog(
        Component,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted,
        Updated
    );

END;
