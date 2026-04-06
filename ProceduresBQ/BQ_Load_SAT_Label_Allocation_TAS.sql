-- ==========================================================================================
-- Routine:		Load_SAT_Label_Allocation_TAS
-- Description: Loads attributes into Load_SAT_Label_Allocation_TAS from [Staging].[tblTasman_Consignment_Stg]
-- Example:		Exec [dv].[Load_SAT_Label_Allocation_TAS] 123 
-- History:
--	06/11/2019  P. Waldron		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `your_project.dv.Load_SAT_Label_Allocation_TAS`(
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

  -- Constants for SCD Type 2
  DECLARE v_DefaultValidFrom TIMESTAMP DEFAULT TIMESTAMP('1900-01-01 00:00:00');
  DECLARE v_DefaultValidTo TIMESTAMP DEFAULT TIMESTAMP('9999-12-31 23:59:59');

  BEGIN
    BEGIN TRANSACTION;

      -- 1. Identify records that are new or have changed attributes
      CREATE TEMP TABLE temp_SAT_TAS_Toload AS
      WITH Stg AS (
        SELECT DISTINCT
          UPPER(TO_HEX(SHA256(TRIM(Stg.LabelNumber)))) AS LabelNo_HSK,
          Stg.LabelNumber AS LabelNo,
          COALESCE(cty.CountryName, 'Unknown') AS Country,
          Stg.Origin_CountryCode AS CountryCode,
          Stg.Origin_FranchiseeCode AS OriginRF,
          Stg.Receiver_FranchiseeCode AS DestinationRF,
          Stg.createDateUTC,
          Stg.OESCustomerId,
          Stg.Price_Cost AS LabelCost,
          Stg.WeightCubic AS Weight,
          Stg.Height,
          Stg.Width,
          Stg.Length,
          Stg.TasmanID
        FROM `your_project.Staging.tblTasman_Consignment_Stg` AS Stg
        LEFT JOIN `your_project.dbo.Dim_Country` AS cty 
          ON cty.CountryCode = Stg.Origin_CountryCode
        WHERE Stg.LabelNumber IS NOT NULL AND Stg.LabelNumber != ''
      ),
      Current_Sat AS (
        SELECT * FROM `your_project.dv.SAT_Label_Allocation_TAS` WHERE IsCurrent = 1
      )
      SELECT 
        S.*,
        CASE WHEN T.LabelNo_HSK IS NULL THEN 'I' ELSE 'U' END AS ActionType
      FROM Stg S
      LEFT JOIN Current_Sat T ON S.LabelNo_HSK = T.LabelNo_HSK
      WHERE T.LabelNo_HSK IS NULL -- New Business Key
         OR (
           -- Change Detection logic (replaces EXCEPT)
           S.Country != T.Country OR
           S.CountryCode != T.CountryCode OR
           S.OriginRF != T.OriginRF OR
           S.DestinationRF != T.DestinationRF OR
           S.OESCustomerId != T.OESCustomerId OR
           S.LabelCost != T.LabelCost OR
           S.Weight != T.Weight OR
           S.Height != T.Height OR
           S.Width != T.Width OR
           S.Length != T.Length
         );

      -- 2. Expire old records (Update ValidTo and IsCurrent)
      UPDATE `your_project.dv.SAT_Label_Allocation_TAS` Target
      SET IsCurrent = 0,
          ValidTo = v_Loaded
      FROM temp_SAT_TAS_Toload Source
      WHERE Target.LabelNo_HSK = Source.LabelNo_HSK
        AND Target.IsCurrent = 1
        AND Source.ActionType = 'U';

      SET v_Updated_Count = @@row_count;

      -- 3. Insert new current records
      INSERT INTO `your_project.dv.SAT_Label_Allocation_TAS` (
        LabelNo_HSK, LabelNo, Country, CountryCode, OriginRF,
        DestinationRF, CreateDateUTC, OESCustomerId, LabelCost,
        Weight, Height, Width, Length,
        Loaded, ProcessId, RecordSource, RecordSourceId,
        ValidFrom, ValidTo, IsCurrent
      )
      SELECT 
        LabelNo_HSK, LabelNo, Country, CountryCode, OriginRF,
        DestinationRF, createDateUTC, OESCustomerId, LabelCost,
        Weight, Height, Width, Length,
        v_Loaded, p_ProcessID, p_RecordSource, TasmanID,
        CASE WHEN ActionType = 'I' THEN v_DefaultValidFrom ELSE v_Loaded END,
        v_DefaultValidTo, 1
      FROM temp_SAT_TAS_Toload;

      SET v_Inserted_Count = @@row_count;

    COMMIT TRANSACTION;

  EXCEPTION WHEN ERROR THEN
    ROLLBACK TRANSACTION;
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- 4. Log results
  CALL `your_project.Staging.SaveLog`(
    'dv.Load_SAT_Label_Allocation_TAS',
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
