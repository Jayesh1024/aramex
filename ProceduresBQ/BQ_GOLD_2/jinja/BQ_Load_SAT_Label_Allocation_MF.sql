-- ==========================================================================================
-- Routine:      Load_SAT_Label_Allocation_MF
-- Description: Loads attributes into SAT_Label_Allocation_MF from Staging.fl_ConItem_Stg 
-- Example:      Exec [dv].[Load_SAT_Label_Allocation_MF] 616 
-- History:
--  25/07/2019  P. Waldron      Routine Written
--  07/11/2019  P. Waldron      Remove CountryName from Label_HSK 
--  15/08/2020  P. Waldron      Add columns from source table s_FMS_Customer
--  09/09/2020  P. Waldron      Add From/To RF/CF columns
--  05/05/2021  B. Woods        Added columns BasePriceDiscounted and ExcessPriceDiscounted
--  30/06/2022  B. Woods        Added multiple columns as per BI-266
--  18/08/2022  B. Woods        Added more columns as per BI-278
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_SAT_Label_Allocation_MF`(
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

      -- 1. Identify Changes (Delta Logic)
      CREATE TEMP TABLE temp_SAT_MF_Labels_Toload AS
      WITH Stg AS (
        SELECT DISTINCT * FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_fl_ConItem_Stg`
      ),
      Current_Sat AS (
        SELECT * FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF` WHERE IsCurrent = 1
      )
      SELECT 
        S.Label AS LabelNo,
        S.CountryId AS CountryCode,
        CASE WHEN T.LabelNo IS NULL THEN 'I' ELSE 'U' END AS RType
      FROM Stg S
      LEFT JOIN Current_Sat T ON S.Label = T.LabelNo AND S.CountryId = T.CountryCode
      WHERE T.LabelNo IS NULL 
         OR (
           IFNULL(S.ConId, 0) != IFNULL(T.ConId, 0) OR 
           IFNULL(S.CustomerId, 0) != IFNULL(T.CustomerId, 0) OR 
           IFNULL(S.BasePrice, 0) != IFNULL(T.BasePrice, 0) OR
           IFNULL(S.Quantity, 0) != IFNULL(T.Quantity, 0) OR
           IFNULL(S.WeightDead, 0) != IFNULL(T.WeightDead, 0)
         );

      -- 2. Update existing records (Expire old version)
      UPDATE `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF` Target
      SET IsCurrent = 0,
          ValidTo = v_Loaded
      FROM temp_SAT_MF_Labels_Toload Source
      WHERE Target.LabelNo = Source.LabelNo 
        AND Target.CountryCode = Source.CountryCode
        AND Source.RType = 'U'
        AND Target.IsCurrent = 1;

      SET v_Updated_Count = @@row_count;

      -- 3. Insert new records
      INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF` (
        LabelNo_HSK, LabelNo, ConId, ConItemId, LineNo, CountryCode, Country,
        CreatedOn, CustomerId, FromRf, FromCf, ToRf, ToCf, FMSInvoiceNo,
        FMSInvoiceDate, Reference, Quantity, ProductId, WeightDead, WeightCubic,
        WeightPriced, Length, Width, Height, FromBusinessName, FromContactName,
        FromStreetAddress, FromLocality, FromStateOrProvince, FromPostalCode,
        FromCountry, FromPhoneNumber, FromEmail, FromLat, FromLng, ToBusinessName,
        ToContactName, ToStreetAddress, ToLocality, ToStateOrProvince, ToPostalCode,
        ToCountry, ToPhoneNumber, ToEmail, ToLat, ToLng, RealisedDate, BasePrice,
        ExcessPrice, PickUpPriceTotal, DeliveryPriceTotal, BasePriceComm,
        ExcessPriceComm, BasePriceDiscounted, ExcessPriceDiscounted, ItemPrice,
        ServicePrice, PLBSBatchId, PLBSInvoiceNo, PLBSInvoiceDate, PLBSPrice,
        PLBSTax, PLBSTotal, DLBSBatchId, DLBSInvoiceNo, DLBSInvoiceDate, DLBSPrice,
        DLBSTax, DLBSTotal, LineHaulPrice, LineHaulTax, LineHaulTotal, Zone,
        SatchelSize, WeightPriceTypeId, SubDepot, ToRfSubDepotCode, BareProfileId,
        ConUpdatedOn, ConItemUpdatedOn, ItemSumPrice, ItemSumTax, ItemSumTotal,
        ItemSumPackageTypeId, LabelExternal, Loaded, ProcessID, RecordSource,
        RecordSourceId, ValidFrom, ValidTo, IsCurrent
      )
      SELECT
        SHA256(TRIM(Stg.Label)) AS LabelNo_HSK,
        Stg.Label, Stg.ConId, Stg.ConItemId, Stg.LineNo, Stg.CountryId,
        IFNULL(cty.CountryName, 'Unknown'),
        Stg.CreatedOn, Stg.CustomerId, Stg.FromRf, Stg.FromCf, Stg.ToRf, Stg.ToCf,
        Stg.FMSInvoiceNo, Stg.FMSInvoiceDate, Stg.Reference, Stg.Quantity,
        Stg.ProductId, Stg.WeightDead, Stg.WeightCubic, Stg.WeightPriced,
        Stg.Length, Stg.Width, Stg.Height, Stg.FromBusinessName, Stg.FromContactName,
        Stg.FromStreetAddress, Stg.FromLocality, Stg.FromStateOrProvince,
        Stg.FromPostalCode, Stg.FromCountry, Stg.FromPhoneNumber, Stg.FromEmail,
        Stg.FromLat, Stg.FromLng, Stg.ToBusinessName, Stg.ToContactName,
        Stg.ToStreetAddress, Stg.ToLocality, Stg.ToStateOrProvince, Stg.ToPostalCode,
        Stg.ToCountry, ToPhoneNumber, ToEmail, ToLat, ToLng,
        Stg.RealisedDate, Stg.BasePrice, Stg.ExcessPrice, Stg.PickUpPriceTotal,
        Stg.DeliveryPriceTotal, Stg.BasePriceComm, Stg.ExcessPriceComm,
        Stg.BasePriceDiscounted, Stg.ExcessPriceDiscounted, Stg.ItemPrice,
        Stg.ServicePrice, Stg.PLBSBatchId, Stg.PLBSInvoiceNo, Stg.PLBSInvoiceDate,
        Stg.PLBSPrice, Stg.PLBSTax, Stg.PLBSTotal, Stg.DLBSBatchId, Stg.DLBSInvoiceNo,
        Stg.DLBSInvoiceDate, Stg.DLBSPrice, Stg.DLBSTax, Stg.DLBSTotal,
        Stg.LineHaulPrice, Stg.LineHaulTax, Stg.LineHaulTotal, Stg.Zone,
        Stg.SatchelSize, Stg.WeightPriceTypeId, Stg.SubDepot, Stg.ToRfSubDepotCode,
        Stg.BareProfileId, Stg.ConUpdatedOn, Stg.ConItemUpdatedOn, Stg.ItemSumPrice,
        Stg.ItemSumTax, Stg.ItemSumTotal, Stg.ItemSumPackageTypeId, Stg.LabelExternal,
        v_Loaded, p_ProcessID, p_RecordSource, Stg.ConItemId,
        CASE WHEN T.RType = 'I' THEN v_DefaultValidFrom ELSE v_Loaded END,
        v_DefaultValidTo, 1
      FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_fl_ConItem_Stg` AS Stg
      JOIN temp_SAT_MF_Labels_Toload T ON T.LabelNo = Stg.Label AND T.CountryCode = Stg.CountryId
      LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` AS cty ON cty.CountryCode = Stg.CountryId;

      SET v_Inserted_Count = @@row_count;

    COMMIT TRANSACTION;

  EXCEPTION WHEN ERROR THEN
    ROLLBACK TRANSACTION;
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- Metadata Logging
  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
    'dv_Load_SAT_Label_Allocation_MF',
    p_ProcessID,
    v_Started,
    CURRENT_DATETIME(),
    v_Status,
    v_Error_Msg,
    v_Inserted_Count,
    v_Updated_Count,
    0
  );

  IF v_Status = 'Failed' THEN
    RAISE USING MESSAGE = v_Error_Msg;
  END IF;

END;