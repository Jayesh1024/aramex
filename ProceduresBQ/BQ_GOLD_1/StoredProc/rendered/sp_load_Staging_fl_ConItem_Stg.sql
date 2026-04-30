CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.sp_load_Staging_fl_ConItem_Stg`(
  startDate DATETIME
)
BEGIN
  DECLARE startDate2 DATETIME;
  DECLARE v_ConId INT64;

  SET v_ConId = (
    SELECT ConId
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.FWFastlabel_dbo_fl_Con`
    WHERE CreatedOn >= startDate2
    ORDER BY CreatedOn
    LIMIT 1
  );

  SET startDate2 = DATE_SUB(CURRENT_DATETIME(), INTERVAL 60 DAY);

  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_fl_ConItem_Stg`
  SELECT
  ci.Label,
  con.ConId,
  ci.ConItemId,
  ci.LineNo,
  con.CountryId,
  con.CreatedOn,
  ci.FromRf,
  ci.FromCf,
  ci.ToRf,
  ci.ToCf,
  con.CustomerId,
  ci.FMSInvoiceNo,
  ci.FMSInvoiceDate,
  cis.Reference,
  cis.Quantity,
  cis.ProductId,
  CAST(cis.WeightDead AS NUMERIC) AS WeightDead,
  CAST(cis.WeightCubic AS NUMERIC) AS WeightCubic,
  CAST(cis.WeightPriced AS NUMERIC) AS WeightPriced,
  CAST(cis.Length AS NUMERIC) AS Length,
  CAST(cis.Width AS NUMERIC) AS Width,
  CAST(cis.Height AS NUMERIC) AS Height,
  con.FromBusinessName,
  con.FromContactName,
  con.FromStreetAddress,
  con.FromLocality,
  con.FromStateOrProvince,
  con.FromPostalCode,
  con.FromCountry,
  con.FromPhoneNumber,
  con.FromEmail,
  CAST(con.FromLat AS NUMERIC) AS FromLat,
  CAST(con.FromLng AS NUMERIC) AS FromLng,
  con.ToBusinessName,
  con.ToContactName,
  con.ToStreetAddress,
  con.ToLocality,
  con.ToStateOrProvince,
  con.ToPostalCode,
  con.ToCountry,
  con.ToPhoneNumber,
  con.ToEmail,
  CAST(con.ToLng AS NUMERIC) AS ToLng,
  CAST(con.ToLat AS NUMERIC) AS ToLat,
  con.RealisedDate,
  CAST(ci.BasePrice AS NUMERIC) AS BasePrice,
  CAST(ci.ExcessPrice AS NUMERIC) AS ExcessPrice,
  CAST(ci.PickUpPriceTotal AS NUMERIC) AS PickUpPriceTotal,
  CAST(ci.DeliveryPriceTotal AS NUMERIC) AS DeliveryPriceTotal,
  CAST(ci.BasePriceComm AS NUMERIC) AS BasePriceComm,
  CAST(ci.ExcessPriceComm AS NUMERIC) AS ExcessPriceComm,
  CAST(ci.BasePriceDiscounted AS NUMERIC) AS BasePriceDiscounted,
  CAST(ci.ExcessPriceDiscounted AS NUMERIC) AS ExcessPriceDiscounted,
  CAST(ci.ItemPrice AS NUMERIC) AS ItemPrice,
  CAST(ci.ServicePrice AS NUMERIC) AS ServicePrice,
  ci.PLBSBatchId,
  ci.PLBSInvoiceNo,
  ci.PLBSInvoiceDate,
  CAST(ci.PLBSPrice AS NUMERIC) AS PLBSPrice,
  CAST(ci.PLBSTax AS NUMERIC) AS PLBSTax,
  CAST(ci.PLBSTotal AS NUMERIC) AS PLBSTotal,
  ci.DLBSBatchId,
  ci.DLBSInvoiceNo,
  ci.DLBSInvoiceDate,
  CAST(ci.DLBSPrice AS NUMERIC) AS DLBSPrice,
  CAST(ci.DLBSTax AS NUMERIC) AS DLBSTax,
  CAST(ci.DLBSTotal AS NUMERIC) AS DLBSTotal,
  CAST(ci.LineHaulPrice AS NUMERIC) AS LineHaulPrice,
  CAST(ci.LineHaulTax AS NUMERIC) AS LineHaulTax,
  CAST(ci.LineHaulTotal AS NUMERIC) AS LineHaulTotal,
  ci.Zone,
  cis.SatchelSize,
  cis.WeightPriceTypeId,
  ci.SubDepot,
  ci.ToRfSubDepotCode,
  ci.BareProfileId,
  con.UpdatedOn as ConUpdatedOn,
  ci.UpdatedOn as ConItemUpdatedOn,
  CAST(cis.Price AS NUMERIC) AS ItemSumPrice,
  CAST(cis.Tax AS NUMERIC) AS ItemSumTax,
  CAST(cis.Total AS NUMERIC) AS ItemSumTotal,
  CAST(NULL AS NUMERIC) AS ItemSumDeclaredValue,
  cis.PackageTypeId AS ItemSumPackageTypeId,
  CAST(NULL AS STRING) AS ItemSumHSCodeInternal,
  CAST(NULL AS STRING) AS ItemSumHSCodeExternal,
  CAST(NULL AS STRING) AS ItemSumDescriptionOfGoods,
  ci.LabelExternal
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.FWFastlabel_dbo_fl_Con` con  
  JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.FWFastlabel_dbo_fl_ConItemSum` cis  on cis.ConId = con.ConId
  JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.FWFastlabel_dbo_fl_ConItem` ci  on ci.ConId = cis.ConId and ci.LineNo = cis.LineNo
  WHERE con.ConId >= v_ConId
  ;

END;