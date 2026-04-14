-- ==========================================================================================
-- Routine:     dv_Load_LNK_Scan_SignatureAI
-- Description: Loads attributes into LNK_Scan_SignatureAI
--              BigQuery compatible version of Load_LNK_Scan_SignatureAI
--              Note: Temp table replaced with CTE / subquery approach.
--                    UPDATE ... FROM replaced with MERGE (BQ requires MERGE for UPDATE with JOIN).
--                    EXCEPT-based change detection preserved in MERGE WHEN MATCHED condition.
-- Example:     CALL dv.dv_Load_LNK_Scan_SignatureAI(123, 'TTSignatureAI')
-- History:
--  08/04/2025  B. Woods        Cloned
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `searce-sandbox-da-delivery.Aramex_oceania_SP.dv_Load_LNK_Scan_SignatureAI`(
    IN ProcessID  INT64,
    IN RecordSource STRING
)
BEGIN

    DECLARE Loaded       DATETIME DEFAULT CURRENT_DATETIME();

    DECLARE Component    STRING DEFAULT 'LNK_Scan_SignatureAI';
    DECLARE Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING;
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64 DEFAULT 0;
    DECLARE Updated      INT64 DEFAULT 0;

    BEGIN

        -- -----------------------------------------------------------------------
        -- UPDATES: rows that already exist in the target and have changed values.
        -- Uses MERGE to replicate the SQL Server UPDATE ... FROM ... WHERE EXISTS (EXCEPT).
        -- -----------------------------------------------------------------------
        MERGE `searce-sandbox-da-delivery.Aramex_oceania.dv_LNK_Scan_SignatureAI` AS Tgt
        USING (
            SELECT
                 Stg.TrackAndTraceId
                ,Stg.AILabel
                ,Stg.AIScore
                ,Stg.AIVersion
                ,Stg.UserLabel
                ,Stg.ValidatedByUsername
                ,Stg.CourierNo
                ,Stg.FranchiseeCode
                ,Stg.ScanDate
                ,Stg.LastUpdatedOn
                ,Stg.TrainingLabel
            FROM `searce-sandbox-da-delivery.Aramex_oceania.InterimStaging_TrackAndTraceData_SignatureAI_Stg` Stg
            INNER JOIN `searce-sandbox-da-delivery.Aramex_oceania.dv_LNK_Scan_SignatureAI` Existing
                ON Existing.TrackAndTraceID = Stg.TrackAndTraceId
        ) AS Src
        ON Tgt.TrackAndTraceId = Src.TrackAndTraceId
        WHEN MATCHED AND (
            -- Replicate EXCEPT change-detection: update only when at least one column differs
            IFNULL(CAST(Tgt.AILabel AS STRING), '')             <> IFNULL(CAST(Src.AILabel AS STRING), '')
         OR IFNULL(CAST(Tgt.AIScore AS STRING), '')             <> IFNULL(CAST(Src.AIScore AS STRING), '')
         OR IFNULL(CAST(Tgt.AIVersion AS STRING), '')           <> IFNULL(CAST(Src.AIVersion AS STRING), '')
         OR IFNULL(CAST(Tgt.UserLabel AS STRING), '')           <> IFNULL(CAST(Src.UserLabel AS STRING), '')
         OR IFNULL(CAST(Tgt.ValidatedByUsername AS STRING), '') <> IFNULL(CAST(Src.ValidatedByUsername AS STRING), '')
         OR IFNULL(CAST(Tgt.CourierNo AS STRING), '')           <> IFNULL(CAST(Src.CourierNo AS STRING), '')
         OR IFNULL(CAST(Tgt.FranchiseeCode AS STRING), '')      <> IFNULL(CAST(Src.FranchiseeCode AS STRING), '')
         OR IFNULL(CAST(Tgt.ScanDate AS STRING), '')            <> IFNULL(CAST(Src.ScanDate AS STRING), '')
         OR IFNULL(CAST(Tgt.LastUpdatedOn AS STRING), '')       <> IFNULL(CAST(Src.LastUpdatedOn AS STRING), '')
         OR IFNULL(CAST(Tgt.TrainingLabel AS STRING), '')       <> IFNULL(CAST(Src.TrainingLabel AS STRING), '')
        )
        THEN UPDATE SET
             Tgt.TrackAndTraceId     = Src.TrackAndTraceId
            ,Tgt.AILabel             = Src.AILabel
            ,Tgt.AIScore             = Src.AIScore
            ,Tgt.AIVersion           = Src.AIVersion
            ,Tgt.UserLabel           = Src.UserLabel
            ,Tgt.ValidatedByUsername = Src.ValidatedByUsername
            ,Tgt.CourierNo           = Src.CourierNo
            ,Tgt.FranchiseeCode      = Src.FranchiseeCode
            ,Tgt.ScanDate            = Src.ScanDate
            ,Tgt.LastUpdatedOn       = Src.LastUpdatedOn
            ,Tgt.TrainingLabel       = Src.TrainingLabel
            ,Tgt.Loaded              = Loaded
            ,Tgt.ProcessId           = ProcessID
            ,Tgt.RecordSource        = RecordSource;

        SET Updated = @@ROW_COUNT;

        -- -----------------------------------------------------------------------
        -- INSERTS: rows that do not yet exist in the target.
        -- -----------------------------------------------------------------------
        INSERT INTO `searce-sandbox-da-delivery.Aramex_oceania.dv_LNK_Scan_SignatureAI`
        (
             TrackAndTraceId
            ,AILabel
            ,AIScore
            ,AIVersion
            ,UserLabel
            ,ValidatedByUsername
            ,CourierNo
            ,FranchiseeCode
            ,ScanDate
            ,LastUpdatedOn
            ,TrainingLabel
            ,Loaded
            ,ProcessId
            ,RecordSource
        )
        SELECT
             Stg.TrackAndTraceId
            ,Stg.AILabel
            ,Stg.AIScore
            ,Stg.AIVersion
            ,Stg.UserLabel
            ,Stg.ValidatedByUsername
            ,Stg.CourierNo
            ,Stg.FranchiseeCode
            ,Stg.ScanDate
            ,Stg.LastUpdatedOn
            ,Stg.TrainingLabel
            ,Loaded
            ,ProcessID
            ,RecordSource
        FROM `searce-sandbox-da-delivery.Aramex_oceania.InterimStaging_TrackAndTraceData_SignatureAI_Stg` Stg
        WHERE NOT EXISTS (
            SELECT 1
            FROM `searce-sandbox-da-delivery.Aramex_oceania.dv_LNK_Scan_SignatureAI` Tgt
            WHERE Tgt.TrackAndTraceID = Stg.TrackAndTraceId
        );

        SET Inserted = @@ROW_COUNT;
        SET Result   = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed';
        SET ErrorMessage = @@error.message;

    END;

    -- Record load metrics in log
    SET Ended = CURRENT_DATETIME();
    CALL `searce-sandbox-da-delivery.Aramex_oceania_SP.Staging_SaveLog`(
        Component,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted,
        Updated,
        -1
    );

END;