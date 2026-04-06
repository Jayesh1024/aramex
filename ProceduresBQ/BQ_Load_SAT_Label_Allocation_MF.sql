-- ==========================================================================================
-- Routine:     Load_SAT_Label_Allocation_MF
-- Description: Loads attributes into SAT_Label_Allocation_MF from Staging.fl_ConItem_Stg 
-- Example:     Exec [dv].[Load_SAT_Label_Allocation_MF] 616 
-- History:
--  25/07/2019  P. Waldron      Routine Written
--  07/11/2019  P. Waldron      Remove CountryName from Label_HSK 
--  15/08/2020  P. Waldron      Add columns from source table s_FMS_Customer
--  09/09/2020  P. Waldron      Add From/To RF/CF columns
--  05/05/2021  B. Woods        Added columns BasePriceDiscounted and ExcessPriceDiscounted
--  30/06/2022  B. Woods        Added multiple columns as per BI-266
--  18/08/2022  B. Woods        Added more columns as per BI-278
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `your_project.dv.Load_SAT_Label_Allocation_MF`(
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
    -- Start Transaction for SCD Type 2 Consistency
    BEGIN TRANSACTION;

      -- 1. Identify Changes (Delta Logic)
      -- We create a temporary table in memory to hold the Label IDs that need processing
      CREATE TEMP TABLE temp_SAT_MF_Labels_Toload AS
      WITH Stg AS (
        SELECT DISTINCT * FROM `your_project.Staging.fl_ConItem_Stg`
      ),
      Current_Sat AS (
        SELECT * FROM `your_project.dv.SAT_Label_Allocation_MF` WHERE IsCurrent = 1
      )
      SELECT 
        S.Label AS LabelNo,
        S.CountryId AS CountryCode,
        CASE WHEN T.LabelNo IS NULL THEN 'I' ELSE 'U' END AS RType
      FROM Stg S
      LEFT JOIN Current_Sat T ON S.Label = T.LabelNo AND S.CountryId = T.CountryCode
      WHERE T.LabelNo IS NULL -- New Record
         OR (
           -- Check for changes in any attribute (Simplified example of the original EXCEPT logic)
           -- In a real BQ prod environment, we often compare a HashDiff column here.
           S.ConId != T.ConId OR S.CustomerId != T.CustomerId OR S.BasePrice != T.BasePrice -- add other columns as needed
         );

      -- 2. Update existing records (Retire old version)
      UPDATE `your_project.dv.SAT_Label_Allocation_MF` Target
      SET IsCurrent = 0,
          ValidTo = v_Loaded
      FROM temp_SAT_MF_Labels_Toload Source
      WHERE Target.LabelNo = Source.LabelNo 
        AND Target.CountryCode = Source.CountryCode
        AND Source.RType = 'U'
        AND Target.IsCurrent = 1;

      SET v_Updated_Count = @@row_count;

      -- 3. Insert new records (New version)
      INSERT INTO `your_project.dv.SAT_Label_Allocation_MF` (
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
        UPPER(TO_HEX(SHA256(TRIM(Stg.Label)))) AS LabelNo_HSK,
        Stg.Label, Stg.ConId, Stg.ConItemId, Stg.LineNo, Stg.CountryId,
        COALESCE(cty.CountryName, 'Unknown'),
        Stg.CreatedOn, Stg.CustomerId, Stg.FromRf, Stg.FromCf, Stg.ToRf, Stg.ToCf,
        Stg.FMSInvoiceNo, Stg.FMSInvoiceDate, Stg.Reference, Stg.Quantity,
        Stg.ProductId, Stg.WeightDead, Stg.WeightCubic, Stg.WeightPriced,
        Stg.Length, Stg.Width, Stg.Height, Stg.FromBusinessName, Stg.FromContactName,
        Stg.FromStreetAddress, Stg.FromLocality, Stg.FromStateOrProvince,
        Stg.FromPostalCode, Stg.FromCountry, Stg.FromPhoneNumber, Stg.FromEmail,
        Stg.FromLat, Stg.FromLng, Stg.ToBusinessName, Stg.ToContactName,
        Stg.ToStreetAddress, Stg.ToLocality, Stg.ToStateOrProvince, Stg.ToPostalCode,
        Stg.ToCountry, Stg.ToPhoneNumber, Stg.ToEmail, Stg.ToLat, Stg.ToLng,
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
      FROM `your_project.Staging.fl_ConItem_Stg` AS Stg
      JOIN temp_SAT_MF_Labels_Toload T ON T.LabelNo = Stg.Label AND T.CountryCode = Stg.CountryId
      LEFT JOIN `your_project.dbo.Dim_Country` AS cty ON cty.CountryCode = Stg.CountryId;

      SET v_Inserted_Count = @@row_count;

    COMMIT TRANSACTION;

  EXCEPTION WHEN ERROR THEN
    ROLLBACK TRANSACTION;
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- Log Results
  CALL `your_project.Staging.SaveLog`(
    'dv.Load_SAT_Label_Allocation_MF', p_ProcessID, v_Started, CURRENT_TIMESTAMP(),
    v_Status, v_Error_Msg, v_Inserted_Count, v_Updated_Count
  );

END;
