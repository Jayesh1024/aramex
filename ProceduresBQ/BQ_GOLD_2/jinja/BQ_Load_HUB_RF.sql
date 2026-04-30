-- ==========================================================================================
-- Routine:   Load_HUB_RF
-- Description: Loads business keys into HUB_RF
-- Example:   Exec [DV].[Load_HUB_RF] 123, 'Fastway'  
-- History:
--  09/11/2018  P. Waldron    Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_HUB_RF`(
  p_ProcessID INT64,
  p_RecordSource STRING
)
BEGIN
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Status STRING DEFAULT 'Success';
  DECLARE v_Error_Msg STRING DEFAULT NULL;
  DECLARE v_Inserted_Count INT64 DEFAULT 0;

  BEGIN
    -- BigQuery MERGE handles the deduplication and 'Not Exists' logic efficiently
    MERGE `{{ project_id }}.{{ target_dataset_id }}.dv_HUB_RF` AS Target
    USING (
      SELECT DISTINCT
        -- Hashing: FranchiseeCode via dbo_GetHashKey (BYTES)
        `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(TRIM(FranchiseeCode), '^') AS FranchiseeCode_HSK,
        TRIM(FranchiseeCode) AS FranchiseeCode,
        v_Loaded AS Loaded,
        p_ProcessID AS ProcessID,
        p_RecordSource AS RecordSource
      FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Franchisee_Stg`
      WHERE FranchiseeCode IS NOT NULL AND TRIM(FranchiseeCode) != ''
    ) AS Source
    ON Target.FranchiseeCode_HSK = Source.FranchiseeCode_HSK
    WHEN NOT MATCHED THEN
      INSERT (FranchiseeCode_HSK, FranchiseeCode, Loaded, ProcessID, RecordSource)
      VALUES (Source.FranchiseeCode_HSK, Source.FranchiseeCode, Source.Loaded, Source.ProcessID, Source.RecordSource);

    SET v_Inserted_Count = @@row_count;

  EXCEPTION WHEN ERROR THEN
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- Metadata Logging
  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
    'dv_Load_HUB_RF',
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