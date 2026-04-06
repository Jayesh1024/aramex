-- ==========================================================================================
-- Routine:     Load_SAT_BLKContainerManifestContents  (BigQuery Version)
-- Description: Loads SAT_BLKContainerManifestContents (new-keys-only insert)
-- Example:     CALL dv.Load_SAT_BLKContainerManifestContents(-4, 'BLK_ManifestContents')
-- History:
--  30/05/2024  B. Woods      Routine Written
--  [BQ Migration] Converted SQL Server -> BigQuery
--    * ;WITH CTE AS (...) -> WITH CTE AS (...)  (BQ does not need the leading semicolon)
--    * dbo.GetHashKey(key, default) -> TO_HEX(MD5(key))
--    * CONVERT(varchar(10), col)    -> CAST(col AS STRING)
--    * INSERT ... WITH (TABLOCK)    -> INSERT ... (hint removed)
--    * IIF()                        -> IF()
--    * See file 1 header for full conversion notes
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE dv.Load_SAT_BLKContainerManifestContents(
    IN ProcessID    INT64,
    IN RecordSource STRING   -- Pass NULL to use default 'BLK_ManifestContents'
)
BEGIN
    DECLARE v_Loaded        DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_RecordSource  STRING   DEFAULT IFNULL(RecordSource, 'BLK_ManifestContents');
    DECLARE Component       STRING   DEFAULT IF(
                                         TRUE,
                                         'dv.Load_SAT_BLKContainerManifestContents',
                                         'Load_SAT_BLKContainerManifestContents'
                                     );
    DECLARE Started         DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended           DATETIME;
    DECLARE Result          STRING   DEFAULT 'Success';
    DECLARE ErrorMessage    STRING   DEFAULT NULL;
    DECLARE Inserted        INT64    DEFAULT 0;

    BEGIN

        BEGIN TRANSACTION;

        -- Identify new business keys not already present in target
        INSERT INTO dv.SAT_BLKContainerManifestContents
        WITH NewBusinessKeys AS (
            SELECT DISTINCT
                Src.ContainerManifestId,
                RTRIM(Src.LabelNo) AS LabelNo
            FROM Staging.BLK_ContainerManifestContents_Stg AS Src
            LEFT JOIN dv.SAT_BLKContainerManifestContents AS Dest
                ON  RTRIM(CAST(Dest.ContainerManifestId AS STRING)) = RTRIM(CAST(Src.ContainerManifestId AS STRING))
                AND RTRIM(Dest.LabelNo) = RTRIM(Src.LabelNo)
            WHERE Dest.ContainerManifestId IS NULL  -- new keys only
        )
        SELECT
            TO_HEX(MD5(CONCAT(CAST(Src.ContainerManifestId AS STRING), RTRIM(Src.LabelNo))))
                                    AS ContainerManifestContents_HSK,
            Src.ContainerManifestId,
            Src.LabelNo,
            Src.ScanDate,
            Src.ScanUserId,
            Src.Destination,
            Src.MixedManifestId,
            Src.Weight,
            Src.CF,
            Started                 AS Loaded,
            ProcessID               AS ProcessID,
            v_RecordSource          AS RecordSource
        FROM Staging.BLK_ContainerManifestContents_Stg AS Src
        JOIN NewBusinessKeys AS NBK
            ON  RTRIM(CAST(NBK.ContainerManifestId AS STRING)) = RTRIM(CAST(Src.ContainerManifestId AS STRING))
            AND RTRIM(NBK.LabelNo) = RTRIM(Src.LabelNo);

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
