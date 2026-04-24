-- ==========================================================================================
-- Routine:   Load_HUB_Product
-- Description: Loads business keys into HUB_Product
-- Example:   Exec [dv].[Load_HUB_Product] 123, 'ZENLog'
-- History:
--  30/05/2024  B. Woods    Routine Written
-- -- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_HUB_BLKContainerManifestContents`(
  p_ProcessID INT64,
  p_RecordSource STRING
)
BEGIN
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Status STRING DEFAULT 'Success';
  DECLARE v_Error_Msg STRING DEFAULT NULL;
  DECLARE v_Inserted_Count INT64 DEFAULT 0;

  BEGIN
    -- BigQuery MERGE: Atomic check for existing business keys before insertion
    MERGE `{{ project_id }}.{{ target_dataset_id }}.dv_HUB_BLKContainerManifestContents` AS Target
    USING (
      SELECT DISTINCT
        -- Hashing: CONVERT(varchar(10), ContainerManifestId) + RTRIM(LabelNo)
        SHA256(CONCAT(CAST(ContainerManifestId AS STRING), TRIM(LabelNo))) AS ContainerManifestContents_HSK,
        ContainerManifestId,
        TRIM(LabelNo) AS LabelNo,
        v_Started AS Loaded,
        p_ProcessID AS ProcessID,
        p_RecordSource AS RecordSource
      FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_BLK_ContainerManifestContents_Stg` AS Src
      -- Replicating the 'New Keys' check against the Satellite as per original logic
      WHERE NOT EXISTS (
        SELECT 1 FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_BLKContainerManifestContents` AS Dest
        WHERE CAST(Dest.ContainerManifestId AS STRING) = CAST(Src.ContainerManifestId AS STRING)
          AND TRIM(Dest.LabelNo) = TRIM(Src.LabelNo)
      )
    ) AS Source
    ON Target.ContainerManifestContents_HSK = Source.ContainerManifestContents_HSK
    WHEN NOT MATCHED THEN
      INSERT (ContainerManifestContents_HSK, ContainerManifestId, LabelNo, Loaded, ProcessID, RecordSource)
      VALUES (Source.ContainerManifestContents_HSK, Source.ContainerManifestId, Source.LabelNo, Source.Loaded, Source.ProcessID, Source.RecordSource);

    SET v_Inserted_Count = @@row_count;

  EXCEPTION WHEN ERROR THEN
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- Metadata Logging
  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
    'dv_Load_HUB_BLKContainerManifestContents',
    p_ProcessID,
    v_Started,
    CURRENT_DATETIME(),
    v_Status,
    v_Error_Msg,
    v_Inserted_Count,
    0,
    0
  );

  IF v_Status = 'Failed' THEN
    RAISE USING MESSAGE = v_Error_Msg;
  END IF;

END;