-- ==========================================================================================
-- Routine:		Load_HUB_RF
-- Description: Loads business keys into HUB_RF
-- Example:		Exec [DV].[Load_HUB_RF] 123, 'Fastway'  
-- History:
--	09/11/2018  P. Waldron		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `your_project.dv.Load_HUB_RF`(
  p_ProcessID INT64,
  p_RecordSource STRING
)
BEGIN
  DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
  DECLARE v_Inserted_Count INT64 DEFAULT 0;
  DECLARE v_Status STRING DEFAULT 'Success';
  DECLARE v_Error_Msg STRING DEFAULT NULL;

  BEGIN
    -- Using MERGE to handle the "New Keys" check (replaces LEFT JOIN/IS NULL)
    MERGE `your_project.dv.HUB_RF` AS Target
    USING (
      SELECT DISTINCT
        -- Hashing the Business Key
        UPPER(TO_HEX(SHA256(TRIM(FranchiseeCode)))) AS FranchiseeCode_HSK,
        TRIM(FranchiseeCode) AS FranchiseeCode,
        v_Started AS Loaded,
        p_ProcessID AS ProcessID,
        p_RecordSource AS RecordSource
      FROM `your_project.Staging.Franchisee_Stg`
      WHERE FranchiseeCode IS NOT NULL 
        AND TRIM(FranchiseeCode) != ''
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
  CALL `your_project.Staging.SaveLog`(
    'dv.Load_HUB_RF',
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
