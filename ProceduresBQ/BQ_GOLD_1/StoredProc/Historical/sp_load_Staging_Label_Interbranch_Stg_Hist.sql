CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.sp_load_Staging_Label_Interbranch_Stg_Hist`(
  RecordSource STRING
)
BEGIN
  DECLARE v_CountryCode INT64;
  SET v_CountryCode = 0;

  IF UPPER(RecordSource) = 'INTERBRANCHAU' THEN
    SET v_CountryCode = 1;
  END IF;
  IF UPPER(RecordSource) = 'INTERBRANCHNZ' THEN
    SET v_CountryCode = 6;
  END IF;

  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Label_Interbranch_Stg` (
    LabelNo,
    Country,
    CountryCode,
    BatchID,
    Category,
    InvoiceNumber,
    InvoiceDate,
    InvoiceFromRF,
    InvoiceToRF,
    ProductID,
    DeliveryDate,
    DeliveryTime,
    Price
  )
  SELECT
    d.LabelNo,
    CASE v_CountryCode WHEN 1 THEN 'Australia' WHEN 6 THEN 'New Zealand' END AS Country,
    v_CountryCode as CountryCode,
    d.BatchId,
    (CASE WHEN d.Franchise = i.PickupRFCode THEN 'Internal' ELSE 'Invoiced' END) AS Category,
    d.InvoiceNumber,
    CAST(i.Date AS DATETIME) AS InvoiceDate,
    d.Franchise AS InvoiceFromRF,
    i.PickupRFCode AS InvoiceToRF,
    d.ProductId,
    DATE(d.CourierDate) AS DeliveryDate,
    d.CourierTime AS DeliveryTime,
    COALESCE(CAST(v.DeliveryCostPerProduct AS FLOAT64), 0) AS Price
  
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_invbtch` b 
  
  INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_invhead` i  on  b.BatchId = i.InvoiceBatchID and b.CountryCode = i.Country 
  INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_labels` d  ON IFNULL(d.BatchID,0) = b.BatchID and d.InvoiceNumber = i.InvoiceNumber and d.CountryCode = b.countryCode and d.InvoiceFranchiseAccountNumber = i.DeliveryFranchisee and d.CourierDate IS NOT NULL
  LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_prods` p  on d.ProductId = p.ProductId and d.CountryCode = p.CountryCode
  LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_invdet` v  on d.InvoiceNumber = v.InvoiceNumber and i.DeliveryFranchisee = v.DeliveryFranchisee and i.Country = v.CountryCode and p.LabelPrefix = v.Prefix
  
  WHERE b.CountryCode = v_CountryCode AND UPPER(d.PickupDelivery) = 'D'
  AND b.released = TRUE
  ;

END;
