-- ==========================================================================================
-- Routine:		Load_HUB_Customer 
-- Description: Loads business keys into Load_HUB_Customer
-- Example:		Exec [DV].[Load_HUB_Customer] 123
-- History:
--	25/10/2018  P. Waldron		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `your_project.dv.Load_HUB_Customer`(
  p_ProcessID INT64,
  p_RecordSource STRING
)
BEGIN
  DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
  DECLARE v_Inserted_Count INT64 DEFAULT 0;
  DECLARE v_Status STRING DEFAULT 'Success';
  DECLARE v_Error_Msg STRING DEFAULT NULL;

  BEGIN
    -- BigQuery MERGE: Atomic check for existing CustomerKey_HSK before insertion
    MERGE `your_project.dv.HUB_Customer` AS Target
    USING (
      SELECT DISTINCT
        -- Generate SHA256 Hash Key for the Business Key
        UPPER(TO_HEX(SHA256(TRIM(CAST(CustomerKey AS STRING))))) AS CustomerKey_HSK,
        CustomerKey,
        v_Started AS Loaded,
        p_ProcessID AS ProcessID,
        p_RecordSource AS RecordSource
      FROM `your_project.Staging.FMS_Customer_Stg`
      WHERE CustomerKey IS NOT NULL
    ) AS Source
    ON Target.CustomerKey_HSK = Source.CustomerKey_HSK
    WHEN NOT MATCHED THEN
      INSERT (CustomerKey_HSK, CustomerKey, Loaded, ProcessID, RecordSource)
      VALUES (Source.CustomerKey_HSK, Source.CustomerKey, Source.Loaded, Source.ProcessID, Source.RecordSource);

    SET v_Inserted_Count = @@row_count;

  EXCEPTION WHEN ERROR THEN
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- Metadata Logging
  CALL `your_project.Staging.SaveLog`(
    'dv.Load_HUB_Customer',
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
