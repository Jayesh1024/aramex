-- ==========================================================================================
-- Routine:   Load_HUB_Customer 
-- Description: Loads business keys into Load_HUB_Customer
-- Example:   Exec [DV].[Load_HUB_Customer] 123
-- History:
--  25/10/2018  P. Waldron    Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.dv_Load_HUB_Customer`(
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
    -- BigQuery MERGE: Atomic check for existing Customer_HSK before insertion
    MERGE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dv_HUB_Customer` AS Target
    USING (
      SELECT DISTINCT
        -- Generate SHA256 Hash Key for the Business Key
        SHA256(TRIM(CAST(CustomerKey AS STRING))) AS CustomerKey_HSK,
        CustomerKey,
        v_Loaded AS Loaded,
        p_ProcessID AS ProcessID,
        p_RecordSource AS RecordSource
      FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_FMS_Customer_Stg`
      WHERE CustomerKey IS NOT NULL
    ) AS Source
    ON Target.Customer_HSK = Source.CustomerKey_HSK
    WHEN NOT MATCHED THEN
      INSERT (Customer_HSK, CustomerKey, Loaded, ProcessID, RecordSource)
      VALUES (Source.CustomerKey_HSK, Source.CustomerKey, Source.Loaded, Source.ProcessID, Source.RecordSource);

    SET v_Inserted_Count = @@row_count;

  EXCEPTION WHEN ERROR THEN
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- Metadata Logging
  CALL `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.Staging_SaveLog`(
    'dv_Load_HUB_Customer',
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