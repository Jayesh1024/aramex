-- ==========================================================================================
-- Routine:   Load_HUB_Address (Parcel from/to locations)
-- Description: Loads address HSKs into HUB_Address  
-- Example:   Exec [dv].[Load_HUB_Address] 278 
-- History:
--  30/10/2019  P. Waldron    Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_HUB_Address`(
  p_ProcessID INT64
)
BEGIN
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Status STRING DEFAULT 'Success';
  DECLARE v_Error_Msg STRING DEFAULT NULL;
  DECLARE v_Inserted_Count INT64 DEFAULT 0;
  DECLARE v_Updated_Count INT64 DEFAULT 0;

  BEGIN
    -- BigQuery MERGE is the modern replacement for WHERE NOT EXISTS logic
    MERGE `{{ project_id }}.{{ target_dataset_id }}.dv_HUB_Address` AS Target
    USING (
      SELECT DISTINCT
        Address_HSK,
        AddressKey,
        RecordSource,
        v_Loaded AS Loaded,
        p_ProcessID AS ProcessID
      FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Label_Address_Stg`
      WHERE AddressSeq = 1
    ) AS Source
    ON Target.Address_HSK = Source.Address_HSK
    WHEN NOT MATCHED THEN
      INSERT (Address_HSK, AddressKey, RecordSource, Loaded, ProcessId)
      VALUES (Source.Address_HSK, Source.AddressKey, Source.RecordSource, Source.Loaded, Source.ProcessID);

    SET v_Inserted_Count = @@row_count;

  EXCEPTION WHEN ERROR THEN
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- Metadata Logging (9 Arguments total)
  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
    'dv_Load_HUB_Address',
    p_ProcessID,
    v_Started,
    CURRENT_DATETIME(),
    v_Status,
    v_Error_Msg,
    v_Inserted_Count,
    v_Updated_Count,
    0                       -- 9. v_Deleted_Count
  );

  IF v_Status = 'Failed' THEN
    RAISE USING MESSAGE = v_Error_Msg;
  END IF;

END;