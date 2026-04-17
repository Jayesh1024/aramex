-- ==========================================================================================
-- Routine:     dv_Load_SAT_BLKContainerManifestContents
-- Description: Loads SAT_BLKContainerManifestContents from `{{ project_id }}.{{ target_dataset_id }}.Staging_BLK_ContainerManifestContents_Stg`
--              BigQuery compatible version of Load_SAT_BLKContainerManifestContents
--              Note: CTE pattern preserved. WITH (TABLOCK) removed.
--                    dbo.GetHashKey replaced with TO_HEX(MD5(...)).
-- Example:     CALL dv.dv_Load_SAT_BLKContainerManifestContents(-4, 'BLK_ManifestContents')
-- History:
--  30/05/2024  B. Woods        Routine Written
--  [BQ Port]   Converted from SQL Server to BigQuery
--  [BQ Fix]    Removed TRIM() from INT64 column ContainerManifestId (TRIM only accepts STRING).
--              Used CONCAT() instead of || for string concatenation in MD5 hash.
--              WHERE NOT EXISTS comparison uses direct equality for INT64 ContainerManifestId.
--              TO_HEX(MD5(...)) → MD5(...) to match target column type (BYTES).
--              SaveLog → Staging_SaveLog with additional -1, -1 arguments.
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_SAT_BLKContainerManifestContents`(
    IN ProcessID    INT64,
    IN RecordSource STRING
)
BEGIN

    DECLARE Loaded    DATETIME DEFAULT CURRENT_DATETIME();

    DECLARE Component    STRING DEFAULT 'dv.Load_SAT_BLKContainerManifestContents';
    DECLARE Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING;
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64 DEFAULT 0;

    BEGIN

        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_BLKContainerManifestContents`
        SELECT
            -- CONCAT used instead of || for BQ string concatenation
            -- ContainerManifestId is INT64 so CAST to STRING before hashing; no TRIM needed
            -- MD5 used directly (without TO_HEX) to match target column BYTES type
            MD5(CONCAT(CAST(Src.ContainerManifestId AS STRING), TRIM(Src.LabelNo))) AS ContainerManifestContents_HSK,
            Src.ContainerManifestId,
            Src.LabelNo,
            Src.ScanDate,
            Src.ScanUserId,
            Src.Destination,
            Src.MixedManifestId,
            Src.Weight,
            Src.CF,
            Started      AS Loaded,
            ProcessID    AS ProcessID,
            RecordSource AS RecordSource
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_BLK_ContainerManifestContents_Stg` AS Src
        -- Only insert rows whose (ContainerManifestId, LabelNo) key doesn't already exist
        WHERE NOT EXISTS (
            SELECT 1
            FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_BLKContainerManifestContents` AS Dest
            WHERE Dest.ContainerManifestId = Src.ContainerManifestId
              AND TRIM(Dest.LabelNo)       = TRIM(Src.LabelNo)
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
    CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
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