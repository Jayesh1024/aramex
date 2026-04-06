-- ==========================================================================================
-- Routine:      Load_HUB_Product
-- Description: Loads business keys into HUB_Product
-- Example:      Exec [dv].[Load_HUB_Product] 123, 'ZENLog'  
-- History:
--  30/05/2024  B. Woods      Routine Written
--
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `your_project.dv.Load_HUB_BLKContainerManifestContents`(
  p_ProcessID INT64,
  p_RecordSource STRING
)
BEGIN
  DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
  DECLARE v_Inserted_Count INT64 DEFAULT 0;
  DECLARE v_Status STRING DEFAULT 'Success';
  DECLARE v_Error_Msg STRING DEFAULT NULL;

  BEGIN
    -- BigQuery MERGE handles the deduplication and 'Not Exists' logic in one pass
    MERGE `your_project.dv.HUB_BLKContainerManifestContents` AS Target
    USING (
      SELECT DISTINCT
        -- Hashing: CONVERT(varchar(10), ContainerManifestId) + RTRIM(LabelNo)
        UPPER(TO_HEX(SHA256(CONCAT(CAST(ContainerManifestId AS STRING), TRIM(LabelNo))))) AS ContainerManifestContents_HSK,
        ContainerManifestId,
        TRIM(LabelNo) AS LabelNo,
        v_Started AS Loaded,
        p_ProcessID AS ProcessID,
        p_RecordSource AS RecordSource
      FROM `your_project.Staging.BLK_ContainerManifestContents_Stg` AS Src
      -- Replicating the "New Keys" check from the original logic
      WHERE NOT EXISTS (
        SELECT 1 FROM `your_project.dv.SAT_BLKContainerManifestContents` AS Dest
        WHERE Dest.ContainerManifestId = CAST(Src.ContainerManifestId AS STRING) 
          AND TRIM(Dest.LabelNo) = TRIM(Src.LabelNo)
      )
    ) AS Source
    ON Target.ContainerManifestContents_HSK = Source.ContainerManifestContents_HSK
    WHEN NOT MATCHED THEN
      INSERT (ContainerManifestContents_HSK, ContainerManifestId, LabelNo, Loaded, ProcessID, RecordSource)
      VALUES (ContainerManifestContents_HSK, ContainerManifestId, LabelNo, Loaded, ProcessID, RecordSource);

    SET v_Inserted_Count = @@row_count;

  EXCEPTION WHEN ERROR THEN
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- Metadata Logging
  CALL `your_project.Staging.SaveLog`(
    'dv.Load_HUB_BLKContainerManifestContents',
    p_ProcessID,
    v_Started,
    CURRENT_TIMESTAMP(),
    v_Status,
    v_Error_Msg,
    v_Inserted_Count
  );

  IF v_Status = 'Failed' THEN
    ERROR(v_Error_Msg);
  END IF;

END;
