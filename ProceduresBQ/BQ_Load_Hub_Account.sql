-- ==========================================================================================
-- Routine:		Load_HUB_Account
-- Description: Loads business keys into HUB_Account
-- Example:		Exec [DV].[Load_HUB_Account] 273, 'Fastway'  
-- History:
--	24/10/2019  P. Waldron		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `your_project.dv.Load_HUB_Account`(
  p_ProcessID INT64,
  p_RecordSource STRING
)
BEGIN
  DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
  DECLARE v_Inserted_Count INT64 DEFAULT 0;
  DECLARE v_Status STRING DEFAULT 'Success';
  DECLARE v_Error_Msg STRING DEFAULT NULL;

  BEGIN
    -- Perform Idempotent Insert using MERGE
    MERGE `your_project.dv.HUB_Account` AS Target
    USING (
      SELECT DISTINCT
        -- Hashing Business Keys: DV 2.0 Standard (SHA256)
        UPPER(TO_HEX(SHA256(CONCAT(CustomerType, '^', CleanedCustomerCode)))) AS Account_HSK,
        CustomerType,
        CleanedCustomerCode AS CustomerCode,
        CURRENT_TIMESTAMP() AS Loaded,
        p_ProcessID AS ProcessID,
        p_RecordSource AS RecordSource
      FROM (
        SELECT 
          CustomerType,
          -- Native BQ cleaning (replaces dbo.CleanString)
          TRIM(REGEXP_REPLACE(IFSCustomerCode, r'\s+', ' ')) AS CleanedCustomerCode
        FROM `your_project.Staging.IFSCustomers_Stg`
      )
      WHERE CleanedCustomerCode != ''
    ) AS Source
    ON Target.Account_HSK = Source.Account_HSK
    WHEN NOT MATCHED THEN
      INSERT (Account_HSK, CustomerType, CustomerCode, Loaded, ProcessID, RecordSource)
      VALUES (Account_HSK, CustomerType, CustomerCode, Loaded, ProcessID, RecordSource);

    SET v_Inserted_Count = @@row_count;

  EXCEPTION WHEN ERROR THEN
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- Metadata Logging
  CALL `your_project.Staging.SaveLog`(
    'dv.Load_HUB_Account',
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
