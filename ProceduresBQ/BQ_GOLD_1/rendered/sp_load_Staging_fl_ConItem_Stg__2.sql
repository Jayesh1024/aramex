CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.sp_load_Staging_fl_ConItem_Stg__2`(
)
BEGIN
  DECLARE startDate DATETIME;
  DECLARE BatchDays INT64;
  DECLARE endDate DATETIME;
  DECLARE ConId INT64;
  DECLARE EndConId INT64;
  SET startDate = CAST('1900-01-01 00:00:00' AS DATETIME);
  SET BatchDays = -120;
  SET endDate = startDate;

  IF startDate = CAST('1900-01-01 00:00:00' AS DATETIME) THEN
    SET startDate = DATE_ADD(CURRENT_DATETIME(), INTERVAL BatchDays DAY);
    SET endDate = CURRENT_DATETIME();
  ELSE
    SET startDate = DATE_ADD(CURRENT_DATETIME(), INTERVAL BatchDays DAY);
  END IF;

  SET ConId = (
    SELECT ConId
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.FWFastlabel_dbo_fl_Con`
    WHERE CreatedOn >= startDate
    ORDER BY CreatedOn
    LIMIT 1
  );

  SET EndConId = (
    SELECT ConId
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.FWFastlabel_dbo_fl_Con`
    WHERE CreatedOn <= endDate
    ORDER BY CreatedOn DESC
    LIMIT 1
  );

  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_fl_ConItem_Stg`
  SELECT
    ci.Label,
    con.ConId,
    ci.ConItemId,
    ci.LineNo,
    con.CountryId,
    con.CreatedOn,
    con.CustomerId,
    ci.FromRf,
    ci.FromCf,
    ci.ToRf,
    ci.ToCf,
    ci.FMSInvoiceNo,
    ci.FMSInvoiceDate,
    cis.Reference,
    cis.Quantity,
    cis.ProductId,
    cis.WeightDead,
    cis.WeightCubic,
    cis.WeightPriced,
    cis.Width,
    cis.Length,
    cis.Height,
    con.FromBusinessName,
    con.FromContactName,
    con.FromStreetAddress,
    con.FromLocality,
    con.FromStateOrProvince,
    con.FromPostalCode,
    con.FromCountry,
    con.FromPhoneNumber,
    con.FromEmail,
    con.FromLat,
    con.FromLng,
    con.ToBusinessName,
    con.ToContactName,
    con.ToStreetAddress,
    con.ToLocality,
    con.ToStateOrProvince,
    con.ToPostalCode,
    con.ToCountry,
    con.ToPhoneNumber,
    con.ToEmail,
    con.ToLat,
    con.ToLng,
    con.RealisedDate,
    ci.RealisedDate AS ItemRealisedDate,
    ci.BasePrice,
    ci.ExcessPrice,
    ci.PickUpPriceTotal,
    ci.DeliveryPriceTotal,
    ci.BasePriceComm,
    ci.ExcessPriceComm,
    ci.BasePriceDiscounted,
    ci.ExcessPriceDiscounted,
    ci.ItemPrice,
    ci.ServicePrice,
    ci.PLBSBatchId,
    ci.PLBSInvoiceNo,
    ci.PLBSInvoiceDate,
    ci.PLBSPrice,
    ci.PLBSTax,
    ci.PLBSTotal,
    ci.DLBSBatchId,
    ci.DLBSInvoiceNo,
    ci.DLBSInvoiceDate,
    ci.DLBSPrice,
    ci.DLBSTax,
    ci.DLBSTotal,
    ci.LineHaulPrice,
    ci.LineHaulTax,
    ci.LineHaulTotal,
    ci.Zone,
    cis.SatchelSize,
    cis.WeightPriceTypeId,
    ci.SubDepot,
    ci.ToRfSubDepotCode,
    ci.BareProfileId,
    con.UpdatedOn AS ConUpdatedOn,
    ci.UpdatedOn AS ConItemUpdatedOn,
    cis.Price AS ItemSumPrice,
    cis.Tax AS ItemSumTax,
    cis.Total AS ItemSumTotal,
    cis.PackageTypeId AS ItemSumPackageTypeId,
    ci.LabelExternal
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.FWFastlabel_dbo_fl_Con` con
  JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.FWFastlabel_dbo_fl_ConItemSum` cis ON cis.ConId = con.ConId
  JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.FWFastlabel_dbo_fl_ConItem` ci ON ci.ConId = cis.ConId AND ci.LineNo = cis.LineNo
  WHERE con.ConId >= ConId
    AND con.ConId < EndConId
    AND con.RealisedDate IS NOT NULL
  ;

END;