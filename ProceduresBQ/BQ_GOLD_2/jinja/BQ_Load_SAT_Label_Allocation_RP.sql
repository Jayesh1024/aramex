-- ==========================================================================================
-- Routine:   Load_SAT_Label_Allocation_RP
-- Description: Loads attributes into Load_SAT_Label_Allocation_RP from Staging.tblOnlineEnquiry_RP_Stg
-- Example:   Exec [dv].[Load_SAT_Label_Allocation_RP] 123
-- History:
--  23/10/2019  P. Waldron    Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_SAT_Label_Allocation_RP`(
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

  -- Constants for SCD Type 2
  DECLARE v_DefaultValidFrom DATETIME DEFAULT DATETIME('1900-01-01 00:00:00');
  DECLARE v_DefaultValidTo DATETIME DEFAULT DATETIME('9999-12-31 23:59:59');

  BEGIN
    BEGIN TRANSACTION;

      -- 1. Identify Changes (Delta Set)
      CREATE TEMP TABLE temp_SAT_RP_Toload AS
      WITH Stg AS (
        SELECT * EXCEPT(rn) FROM (
          SELECT 
            S.*, 
            IFNULL(cty.CountryName, 'Unknown') AS CountryResolved,
            ROW_NUMBER() OVER (PARTITION BY label_number ORDER BY RPID) AS rn
          FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_tblOnlineEnquiry_RP_Stg` S
          LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` cty ON cty.CountryCode = S.CountryId
          WHERE label_number IS NOT NULL AND label_number != ''
        ) WHERE rn = 1
      ),
      Current_Sat AS (
        SELECT * FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_RP` WHERE IsCurrent = 1
      )
      SELECT 
        -- Standardized to BYTES (Removed UPPER(TO_HEX))
        `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(TRIM(Stg.label_number), '^') AS LabelNo_HSK,
        Stg.*,
        CASE WHEN T.LabelNo_HSK IS NULL THEN 'I' ELSE 'U' END AS ActionType
      FROM Stg
      LEFT JOIN Current_Sat T ON T.LabelNo_HSK = `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(TRIM(Stg.label_number), '^')
      WHERE T.LabelNo_HSK IS NULL -- New Business Key
         OR (
           -- Change Detection Logic
           Stg.label_number != T.LabelNo OR
           Stg.CountryResolved != T.Country OR
           Stg.PickupFranchiseeCode != T.PickupRF OR
           Stg.DeliveryFranchiseeCode != T.DeliveryRF OR
           IFNULL(Stg.parcel_weight, 0) != IFNULL(T.Weight, 0) OR
           IFNULL(Stg.parcel_height, 0) != IFNULL(T.Height, 0) OR
           IFNULL(Stg.parcel_width, 0) != IFNULL(T.Width, 0) OR
           IFNULL(Stg.parcel_length, 0) != IFNULL(T.Length, 0)
         );

      -- 2. Expire old versions (SCD Type 2 Update)
      UPDATE `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_RP` Target
      SET IsCurrent = 0,
          ValidTo = v_Loaded
      FROM temp_SAT_RP_Toload Source
      WHERE Target.LabelNo_HSK = Source.LabelNo_HSK
        AND Target.IsCurrent = 1
        AND Source.ActionType = 'U';

      SET v_Updated_Count = @@row_count;

      -- 3. Insert new versions
      INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_RP` (
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

  -- Metadata Logging
  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
    'dv_Load_SAT_Label_Allocation_RP',
    p_ProcessID,
    v_Started,
    CURRENT_DATETIME(),
    v_Status,
    v_Error_Msg,
    v_Inserted_Count,
    v_Updated_Count,
    0 -- Added 9th argument
  );

  IF v_Status = 'Failed' THEN
    RAISE USING MESSAGE = v_Error_Msg;
  END IF;

END;