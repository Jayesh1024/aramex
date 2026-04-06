-- ==========================================================================================
-- Routine:		Load_SAT_Label_Allocation_RP
-- Description: Loads attributes into Load_SAT_Label_Allocation_RP from Staging.tblOnlineEnquiry_RP_Stg
-- Example:		Exec [dv].[Load_SAT_Label_Allocation_RP] 123
-- History:
--	23/10/2019  P. Waldron		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `your_project.dv.Load_SAT_Label_Allocation_RP`(
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

      -- 1. Create a Delta Set of records that actually changed or are new
      CREATE TEMP TABLE temp_SAT_RP_Toload AS
      WITH Stg AS (
        SELECT * EXCEPT(rn) FROM (
          SELECT 
            S.*, 
            COALESCE(cty.CountryName, 'Unknown') AS CountryResolved,
            ROW_NUMBER() OVER (PARTITION BY label_number ORDER BY RPID) AS rn
          FROM `your_project.Staging.tblOnlineEnquiry_RP_Stg` S
          LEFT JOIN `your_project.dbo.Dim_Country` cty ON cty.CountryCode = S.CountryId
          WHERE label_number IS NOT NULL AND label_number != ''
        ) WHERE rn = 1
      ),
      Current_Sat AS (
        SELECT * FROM `your_project.dv.SAT_Label_Allocation_RP` WHERE IsCurrent = 1
      )
      SELECT 
        UPPER(TO_HEX(SHA256(TRIM(Stg.label_number)))) AS LabelNo_HSK,
        Stg.*,
        CASE WHEN T.LabelNo_HSK IS NULL THEN 'I' ELSE 'U' END AS ActionType
      FROM Stg
      LEFT JOIN Current_Sat T ON T.LabelNo_HSK = UPPER(TO_HEX(SHA256(TRIM(Stg.label_number))))
      WHERE T.LabelNo_HSK IS NULL -- New Business Key
         OR (
           -- Change Detection Logic (Replaces EXCEPT)
           Stg.label_number != T.LabelNo OR
           Stg.CountryResolved != T.Country OR
           Stg.PickupFranchiseeCode != T.PickupRF OR
           Stg.DeliveryFranchiseeCode != T.DeliveryRF OR
           Stg.parcel_weight != T.Weight OR
           Stg.parcel_height != T.Height OR
           Stg.parcel_width != T.Width OR
           Stg.parcel_length != T.Length
           -- Add other columns here as per your business requirements
         );

      -- 2. Expire old versions (SCD Type 2 Update)
      UPDATE `your_project.dv.SAT_Label_Allocation_RP` Target
      SET IsCurrent = 0,
          ValidTo = v_Loaded
      FROM temp_SAT_RP_Toload Source
      WHERE Target.LabelNo_HSK = Source.LabelNo_HSK
        AND Target.IsCurrent = 1
        AND Source.ActionType = 'U';

      SET v_Updated_Count = @@row_count;

      -- 3. Insert new versions
      INSERT INTO `your_project.dv.SAT_Label_Allocation_RP` (
        LabelNo_HSK, LabelNo, Country, CountryCode, CreateDateUTC,
        PickupRF, DeliveryRF, PickupCF, DeliveryCF, SenderLocalRF,
        ReceiverLocalRF, CustomerID, PickupDateLocal, LabelColour,
        LabelCost, Weight, Height, Width, Length,
        Loaded, ProcessId, RecordSource, RecordSourceId,
        ValidFrom, ValidTo, IsCurrent
      )
      SELECT 
        LabelNo_HSK, label_number, CountryResolved, CountryId, CreateDateUTC,
        PickupFranchiseeCode, DeliveryFranchiseeCode, PickupCourierNumber, DeliveryCourierNumber, Sender_LocalRF,
        Receiver_LocalRF, CustomerID, PickupDateLocal, label_colour,
        label_cost, parcel_weight, parcel_height, parcel_width, parcel_length,
        v_Loaded, p_ProcessID, p_RecordSource, RPID,
        CASE WHEN ActionType = 'I' THEN v_DefaultValidFrom ELSE v_Loaded END,
        v_DefaultValidTo, 1
      FROM temp_SAT_RP_Toload;

      SET v_Inserted_Count = @@row_count;

    COMMIT TRANSACTION;

  EXCEPTION WHEN ERROR THEN
    ROLLBACK TRANSACTION;
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- 4. Logging
  CALL `your_project.Staging.SaveLog`(
    'dv.Load_SAT_Label_Allocation_RP',
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
