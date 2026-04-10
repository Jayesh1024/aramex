-- ==========================================================================================
-- Routine:		Load_SAT_Label_Allocation_TAS
-- Description: Loads attributes into Load_SAT_Label_Allocation_TAS from [Staging].[tblTasman_Consignment_Stg]
-- Example:		Exec [dv].[Load_SAT_Label_Allocation_TAS] 123 
-- History:
--	06/11/2019  P. Waldron		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_SAT_Label_Allocation_TAS`(
  p_ProcessID INT64,
  p_RecordSource STRING
)
BEGIN
  DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
  DECLARE v_Loaded TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
  DECLARE v_Status STRING DEFAULT 'Success';
  DECLARE v_Error_Msg STRING DEFAULT NULL;
  DECLARE v_Inserted_Count INT64 DEFAULT 0;
  DECLARE v_Updated_Count INT64 DEFAULT 0;

  -- Static Record Source as defined in the source file's default parameter
  DECLARE v_StaticRecordSource STRING DEFAULT 'Tasman';

  -- Constants for SCD Type 2
  DECLARE v_DefaultValidFrom TIMESTAMP DEFAULT TIMESTAMP('1900-01-01 00:00:00');
  DECLARE v_DefaultValidTo TIMESTAMP DEFAULT TIMESTAMP('9999-12-31 23:59:59');

  BEGIN
    BEGIN TRANSACTION;

      -- 1. Identify Changes (Delta Logic)
      -- Replicates the MERGE...EXCEPT logic to find truly new or changed data
      CREATE TEMP TABLE temp_SAT_TAS_Toload AS
      WITH Stg AS (
        SELECT DISTINCT
          UPPER(TO_HEX(SHA256(TRIM(Stg.LabelNumber)))) AS LabelNo_HSK,
          Stg.LabelNumber as LabelNo,
          IFNULL(cty.CountryName,'Unknown') as Country,
          stg.Origin_CountryCode as CountryCode,
          stg.createDateUTC,
          stg.Origin_FranchiseeCode as OriginRF,
          stg.Receiver_FranchiseeCode as DestinationRF,
          stg.OESCustomerId,
          stg.Price_Cost as LabelCost,
          Stg.WeightCubic as [Weight],
          Stg.[Height],
          Stg.[Width],
          Stg.[Length],
          stg.TasmanID 
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_tblTasman_Consignment_Stg` Stg 
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` cty
          ON cty.CountryCode = Stg.Origin_CountryCode 
        WHERE stg.LabelNumber IS NOT NULL AND stg.LabelNumber <> ''
      ),
      Current_Sat AS (
        SELECT * FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_TAS` WHERE IsCurrent = 1
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
           S.CreateDateUTC != T.CreateDateUTC OR
           S.OESCustomerId != T.OESCustomerId OR
           IFNULL(S.LabelCost, 0) != IFNULL(T.LabelCost, 0) OR
           IFNULL(S.[Weight], 0) != IFNULL(T.[Weight], 0) OR
           IFNULL(S.[Height], 0) != IFNULL(T.[Height], 0) OR
           IFNULL(S.[Width], 0) != IFNULL(T.[Width], 0) OR
           IFNULL(S.[Length], 0) != IFNULL(T.[Length], 0)
         );

      -- 2. Expire old versions (SCD Type 2 Update)
      UPDATE `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_TAS` Target
      SET IsCurrent = 0,
          ValidTo = v_Loaded
      FROM temp_SAT_TAS_Toload Source
      WHERE Target.LabelNo_HSK = Source.LabelNo_HSK
        AND Target.IsCurrent = 1
        AND Source.ActionType = 'U';

      SET v_Updated_Count = @@row_count;

      -- 3. Insert new versions
      INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_TAS` (
        [LabelNo_HSK],
        [LabelNo],
        [Country],
        [CountryCode],
        [OriginRF],
        [DestinationRF],
        [CreateDateUTC],
        [OESCustomerID],
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
        CreateDateUTC,
        OESCustomerID,
        LabelCost,
        [Weight],
        [Length],
        [Width],
        [Height],
        v_Loaded,
        p_ProcessID,
        v_StaticRecordSource,
        TasmanID,
        CASE WHEN ActionType = 'I' THEN v_DefaultValidFrom ELSE v_Loaded END,
        v_DefaultValidTo,
        1
      FROM temp_SAT_TAS_Toload;

      SET v_Inserted_Count = @@row_count;

    COMMIT TRANSACTION;

  EXCEPTION WHEN ERROR THEN
    ROLLBACK TRANSACTION;
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- Metadata Logging
  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
    'dv_Load_SAT_Label_Allocation_TAS',
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