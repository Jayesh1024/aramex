-- ==========================================================================================
-- Routine:		Load_HUB_Address (Parcel from/to locations)
-- Description: Loads address HSKs into HUB_Address  
-- Example:		Exec [dv].[Load_HUB_Address] 278 
-- History:
--	30/10/2019  P. Waldron		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `your_project.dv.Load_HUB_Address`(
  p_ProcessID INT64
)
BEGIN
  DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
  DECLARE v_Inserted_Count INT64 DEFAULT 0;
  DECLARE v_Status STRING DEFAULT 'Success';
  DECLARE v_Error_Msg STRING DEFAULT NULL;

  BEGIN
    -- BigQuery MERGE is the modern replacement for WHERE NOT EXISTS logic
    MERGE `your_project.dv.HUB_Address` AS Target
    USING (
      SELECT DISTINCT
        Address_HSK,
        AddressKey,
        RecordSource,
        CURRENT_TIMESTAMP() AS Loaded,
        p_ProcessID AS ProcessID
      FROM `your_project.Staging.Label_Address_Stg`
      WHERE AddressSeq = 1
    ) AS Source
    ON Target.Address_HSK = Source.Address_HSK
    WHEN NOT MATCHED THEN
      INSERT (Address_HSK, AddressKey, RecordSource, Loaded, ProcessId)
      VALUES (Address_HSK, AddressKey, RecordSource, Loaded, ProcessID);

    SET v_Inserted_Count = @@row_count;

  EXCEPTION WHEN ERROR THEN
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- Metadata Logging
  CALL `your_project.Staging.SaveLog`(
    'dv.Load_HUB_Address',
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
