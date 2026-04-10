-- ==========================================================================================
-- Routine:		Load_SAT_Label_Allocation_TMD
-- Description: Loads attributes into Load_SAT_Label_Allocation_TMD from Staging.API_Temando_RequestLabel_Stg
-- Example:		Exec [dv].[Load_SAT_Label_Allocation_TMD] 123 
-- History:
--	06/11/2019  P. Waldron		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_SAT_Label_Allocation_TMD`(
  p_ProcessID INT64,
  p_RecordSource STRING -- Parameter kept for signature, but internal static used
)
BEGIN
  DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
  DECLARE v_Loaded TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
  DECLARE v_Status STRING DEFAULT 'Success';
  DECLARE v_Error_Msg STRING DEFAULT NULL;
  DECLARE v_Inserted_Count INT64 DEFAULT 0;
  DECLARE v_Updated_Count INT64 DEFAULT 0;

  -- Static Record Source as defined in the source file's default parameter
  DECLARE v_StaticRecordSource STRING DEFAULT 'Temando';

  -- Constants for SCD Type 2
  DECLARE v_DefaultValidFrom TIMESTAMP DEFAULT TIMESTAMP('1900-01-01 00:00:00');
  DECLARE v_DefaultValidTo TIMESTAMP DEFAULT TIMESTAMP('9999-12-31 23:59:59');

  BEGIN
    BEGIN TRANSACTION;

      -- 1. Identify Changes (Delta Set)
      -- Replicates the MERGE...EXCEPT logic to find truly new or changed data
      CREATE TEMP TABLE temp_SAT_TMD_Toload AS
      WITH Stg AS (
        SELECT DISTINCT
          UPPER(TO_HEX(SHA256(TRIM(Stg.result_LabelNumber)))) AS LabelNo_HSK,
          Stg.result_LabelNumber as LabelNo,
          IFNULL(cty.CountryName,'Unknown') as Country,
          stg.originCountry as CountryCode,
          stg.createDateLocal,
          stg.createDateUTC,
          stg.requestID,
          stg.readyDate,
          stg.originRF,
          stg.destinationRF,
          stg.Label_Colour as LabelColour,
          stg.Label_Type as LabelType,
          stg.result_Cost as LabelCost,
          Stg.parcelWeight as [Weight],
          Stg.parcelHeight as [Height],
          Stg.parcelWidth  as [Width],
          Stg.parcelLength as [Length],
          stg.globalRequestID 
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_API_Temando_RequestLabel_Stg` Stg 
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` cty
          ON cty.CountryCode = Stg.originCountry 
        WHERE result_LabelNumber IS NOT NULL AND result_LabelNumber <> ''
      ),
      Current_Sat AS (
        SELECT * FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_TMD` WHERE IsCurrent = 1
      )
      SELECT 
        S.*,
        CASE WHEN T.LabelNo_HSK IS NULL THEN 'I' ELSE 'U' END AS ActionType
      FROM Stg S
      LEFT JOIN Current_Sat T ON T.LabelNo_HSK = S.LabelNo_HSK
      WHERE T.LabelNo_HSK IS NULL -- New Business Key
         OR (
           -- Change Detection Logic (Replaces EXCEPT)
           S.Country != T.Country OR
           S.CountryCode != T.CountryCode OR
           S.OriginRF != T.OriginRF OR
           S.DestinationRF != T.DestinationRF OR
           S.CreateDateLocal != T.CreateDateLocal OR
           S.CreateDateUTC != T.CreateDateUTC OR
           S.RequestID != T.RequestID OR
           S.LabelColour != T.LabelColour OR
           S.LabelType != T.LabelType OR
           IFNULL(S.LabelCost, 0) != IFNULL(T.LabelCost, 0) OR
           IFNULL(S.[Weight], 0) != IFNULL(T.[Weight], 0) OR
           IFNULL(S.[Height], 0) != IFNULL(T.[Height], 0) OR
           IFNULL(S.[Width], 0) != IFNULL(T.[Width], 0) OR
           IFNULL(S.[Length], 0) != IFNULL(T.[Length], 0)
         );

      -- 2. Expire old versions (SCD Type 2 Update)
      UPDATE `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_TMD` Target
      SET IsCurrent = 0,
          ValidTo = v_Loaded
      FROM temp_SAT_TMD_Toload Source
      WHERE Target.LabelNo_HSK = Source.LabelNo_HSK
        AND Target.IsCurrent = 1
        AND Source.ActionType = 'U';

      SET v_Updated_Count = @@row_count;

      -- 3. Insert new versions (Current records)
      INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_TMD` (
        [LabelNo_HSK],
        [LabelNo],
        [Country],
        [CountryCode],
        [OriginRF],
        [DestinationRF],
        [CreateDateLocal],
        [CreateDateUTC],
        [RequestID],
        [LabelColour],
        [LabelType],
        [LabelCost],
        [Weight],
        [Length],
        [Width],
        [Height],
        [Loaded],
        [ProcessId],
        [RecordSource],
        [RecordSourceId],
        [ValidFrom],
        [ValidTo],
        [IsCurrent]
      )
      SELECT 
        LabelNo_HSK,
        LabelNo,
        Country,
        CountryCode,
        OriginRF,
        DestinationRF,
        CreateDateLocal,
        CreateDateUTC,
        RequestID,
        LabelColour,
        LabelType,
        LabelCost,
        [Weight],
        [Length],
        [Width],
        [Height],
        v_Loaded,
        p_ProcessID,
        v_StaticRecordSource,
        globalRequestID,
        CASE WHEN ActionType = 'I' THEN v_DefaultValidFrom ELSE v_Loaded END,
        v_DefaultValidTo,
        1
      FROM temp_SAT_TMD_Toload;

      SET v_Inserted_Count = @@row_count;

    COMMIT TRANSACTION;

  EXCEPTION WHEN ERROR THEN
    ROLLBACK TRANSACTION;
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- Metadata Logging
  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
    'dv_Load_SAT_Label_Allocation_TMD',
    p_ProcessID,
    v_Started,
    CURRENT_TIMESTAMP(),
    v_Status,
    v_Error_Msg,
    v_Inserted_Count,
    v_Updated_Count
  );

  IF v_Status = 'Failed' THEN
    ERROR(v_Error_Msg);
  END IF;

END;