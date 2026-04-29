-- ==========================================================================================
-- Routine:   Load_SAT_Label_Allocation_TMD
-- Description: Loads attributes into Load_SAT_Label_Allocation_TMD from Staging.API_Temando_RequestLabel_Stg
-- Example:   Exec [dv].[Load_SAT_Label_Allocation_TMD] 123 
-- History:
--  06/11/2019  P. Waldron    Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_SAT_Label_Allocation_TMD`(
  p_ProcessID INT64,
  p_RecordSource STRING
)
BEGIN
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Status STRING DEFAULT 'Success';
  DECLARE v_Error_Msg STRING DEFAULT NULL;
  DECLARE v_Inserted_Count INT64 DEFAULT 0;
  DECLARE v_Updated_Count INT64 DEFAULT 0;

  DECLARE v_DefaultValidFrom DATETIME DEFAULT DATETIME('1900-01-01 00:00:00');
  DECLARE v_DefaultValidTo DATETIME DEFAULT DATETIME('9999-12-31 23:59:59');

  BEGIN
    BEGIN TRANSACTION;

      -- 1. Identify Changes (Delta Set)
      CREATE TEMP TABLE temp_SAT_TMD_Toload AS
      WITH Stg AS (
        SELECT DISTINCT
          SHA256(TRIM(Stg.result_LabelNumber)) AS LabelNo_HSK,
          Stg.result_LabelNumber as LabelNo,
          IFNULL(cty.CountryName,'Unknown') as Country,
          -- KEEPING THIS AS INT64 for the target table
          Stg.originCountry as CountryCode,
          Stg.createDateLocal,
          Stg.createDateUTC,
          Stg.requestID,
          Stg.readyDate,
          Stg.originRF,
          Stg.destinationRF,
          Stg.Label_Colour as LabelColour,
          Stg.Label_Type as LabelType,
          Stg.result_Cost as LabelCost,
          Stg.parcelWeight as Weight,
          Stg.parcelHeight as Height,
          Stg.parcelWidth  as Width,
          Stg.parcelLength as Length,
          Stg.globalRequestID 
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_API_Temando_RequestLabel_Stg` Stg 
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Country` cty
          -- CAST only for the JOIN comparison
          ON CAST(cty.CountryCode AS STRING) = CAST(Stg.originCountry AS STRING)
        WHERE result_LabelNumber IS NOT NULL AND result_LabelNumber <> ''
      ),
      Current_Sat AS (
        SELECT * FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_TMD` WHERE IsCurrent = 1
      )
      SELECT 
        S.*,
        CASE WHEN T.LabelNo_HSK IS NULL THEN 'I' ELSE 'U' END AS ActionType
      FROM Stg S
      LEFT JOIN Current_Sat T ON T.LabelNo_HSK = S.LabelNo_HSK
      WHERE T.LabelNo_HSK IS NULL
         OR (
           S.Country != T.Country OR
           -- CAST for comparison logic only
           CAST(S.CountryCode AS STRING) != CAST(T.CountryCode AS STRING) OR
           S.OriginRF != T.OriginRF OR
           S.DestinationRF != T.DestinationRF OR
           S.CreateDateLocal != T.CreateDateLocal OR
           S.CreateDateUTC != T.CreateDateUTC OR
           S.RequestID != T.RequestID OR
           S.LabelColour != T.LabelColour OR
           S.LabelType != T.LabelType OR
           IFNULL(S.LabelCost, 0) != IFNULL(T.LabelCost, 0) OR
           IFNULL(S.Weight, 0) != IFNULL(T.Weight, 0) OR
           IFNULL(S.Height, 0) != IFNULL(T.Height, 0) OR
           IFNULL(S.Width, 0) != IFNULL(T.Width, 0) OR
           IFNULL(S.Length, 0) != IFNULL(T.Length, 0)
         );

      -- 2. Expire old versions
      UPDATE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_TMD` Target
      SET IsCurrent = 0,
          ValidTo = v_Loaded
      FROM temp_SAT_TMD_Toload Source
      WHERE Target.LabelNo_HSK = Source.LabelNo_HSK
        AND Target.IsCurrent = 1
        AND Source.ActionType = 'U';

      SET v_Updated_Count = @@row_count;

      -- 3. Insert new versions
      INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_TMD` (
        LabelNo_HSK, LabelNo, Country, CountryCode, OriginRF, DestinationRF,
        CreateDateLocal, CreateDateUTC, RequestID, LabelColour, LabelType,
        LabelCost, Weight, Length, Width, Height, Loaded, ProcessId,
        RecordSource, RecordSourceId, ValidFrom, ValidTo, IsCurrent
      )
      SELECT 
        LabelNo_HSK, LabelNo, Country, 
        SAFE_CAST(CountryCode AS INT64), -- FORCE INT64 HERE
        OriginRF, DestinationRF,
        CreateDateLocal, CreateDateUTC, RequestID, LabelColour, LabelType,
        LabelCost, Weight, Length, Width, Height, v_Loaded, p_ProcessID,
        p_RecordSource, globalRequestID,
        CASE WHEN ActionType = 'I' THEN v_DefaultValidFrom ELSE v_Loaded END,
        v_DefaultValidTo, 1
      FROM temp_SAT_TMD_Toload;

      SET v_Inserted_Count = @@row_count;

    COMMIT TRANSACTION;

  EXCEPTION WHEN ERROR THEN
    ROLLBACK TRANSACTION;
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
    'dv_Load_SAT_Label_Allocation_TMD', p_ProcessID, v_Started, CURRENT_DATETIME(), v_Status, v_Error_Msg, v_Inserted_Count, v_Updated_Count, 0
  );

  IF v_Status = 'Failed' THEN
    RAISE USING MESSAGE = v_Error_Msg;
  END IF;

END;