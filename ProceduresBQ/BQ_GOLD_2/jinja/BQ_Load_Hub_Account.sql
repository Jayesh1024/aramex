-- ==========================================================================================
-- Routine:   Load_HUB_Account
-- Description: Loads business keys into HUB_Account
-- Example:   Exec [DV].[Load_HUB_Account] 273, 'Fastway'  
-- History:
--  24/10/2019  P. Waldron    Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_HUB_Account`(
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
    -- Perform Idempotent Insert using MERGE
    MERGE `{{ project_id }}.{{ target_dataset_id }}.dv_HUB_Account` AS Target
    USING (
      SELECT DISTINCT
        -- Hashing business keys via dbo_GetHashKey (BYTES)
        `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(CONCAT(IFNULL(CustomerType, ''), '^', IFNULL(CleanedCustomerCode, '')), '^') AS Account_HSK,
        CustomerType,
        CleanedCustomerCode AS CustomerCode,
        v_Loaded AS Loaded,
        p_ProcessID AS ProcessID,
        p_RecordSource AS RecordSource
      FROM (
        SELECT 
          CustomerType,
          -- Native BQ cleaning (replaces dbo.CleanString and LTRIM/RTRIM)
          TRIM(REGEXP_REPLACE(IFSCustomerCode, r'\s+', ' ')) AS CleanedCustomerCode
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_IFSCustomers_Stg`
      )
      WHERE CleanedCustomerCode != ''
    ) AS Source
    ON Target.Account_HSK = Source.Account_HSK
    WHEN NOT MATCHED THEN
      INSERT (Account_HSK, CustomerType, CustomerCode, Loaded, ProcessID, RecordSource)
      VALUES (Source.Account_HSK, Source.CustomerType, Source.CustomerCode, Source.Loaded, Source.ProcessID, Source.RecordSource);

    SET v_Inserted_Count = @@row_count;

  EXCEPTION WHEN ERROR THEN
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- Metadata Logging (Signature updated to 9 arguments)
  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
    'dv_Load_HUB_Account',
    p_ProcessID,
    v_Started,
    CURRENT_DATETIME(),
    v_Status,
    v_Error_Msg,
    v_Inserted_Count,
    0,                      -- 8. v_Updated_Count
    0                       -- 9. v_Deleted_Count
  );

  IF v_Status = 'Failed' THEN
    RAISE USING MESSAGE = v_Error_Msg;
  END IF;

END;