-- ==========================================================================================
-- Routine:   Load_HUB_CF (courier franchisee)
-- Description: Loads business keys into HUB_CF
-- Example:   Exec [DV].[Load_HUB_CF] 123, 'Fastway'  
-- History:
--  25/10/2018  P. Waldron    Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_HUB_CF`(
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
    -- BigQuery MERGE replaces the EXCEPT logic by checking the Hash Key
    MERGE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_CF` AS Target
    USING (
      SELECT DISTINCT
        -- Hashing: RFCode + '^' + CourierNumber via dbo_GetHashKey
        `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(CONCAT(IFNULL(RFCode, ''), '^', IFNULL(CourierNumber, '')), '^') AS Courier_HSK,
        RFCode,
        CourierNumber,
        v_Loaded AS Loaded,
        p_ProcessID AS ProcessID,
        p_RecordSource AS RecordSource
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Courier_Stg`
      -- Ensure we don't process entirely null business keys
      WHERE RFCode IS NOT NULL OR CourierNumber IS NOT NULL
    ) AS Source
    ON Target.Courier_HSK = Source.Courier_HSK
    WHEN NOT MATCHED THEN
      INSERT (Courier_HSK, RFCode, CourierNumber, Loaded, ProcessID, RecordSource)
      VALUES (Source.Courier_HSK, Source.RFCode, Source.CourierNumber, Source.Loaded, Source.ProcessID, Source.RecordSource);

    SET v_Inserted_Count = @@row_count;

  EXCEPTION WHEN ERROR THEN
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- Metadata Logging
  CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
    'dv_Load_HUB_CF',
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