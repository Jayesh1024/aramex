CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.sp_load_Staging_Label_Interbranch_Stg_Hist`(
  RecordSource STRING
)
BEGIN
  DECLARE CountryCode INT64;
  SET CountryCode = 0;

  IF RecordSource = 'InterBranchAU' THEN
    SET CountryCode = 1;
  END IF;
  IF RecordSource = 'InterBranchNZ' THEN
    SET CountryCode = 6;
  END IF;

  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Label_Interbranch_Stg`
  SELECT CountryCode,
  CASE CountryCode WHEN 1 THEN 'Australia' WHEN 6 THEN 'New Zealand' END AS Country,
  d.LabelNo,
  d.Franchise AS InvoiceFromRF,
  i.PickupRFCode AS InvoiceToRF,
  d.BatchId,
  (CASE WHEN d.Franchise = i.PickupRFCode THEN 'Internal' ELSE 'Invoiced' END) AS Category,
  i.Date,
  d.InvoiceNumber,
  d.ProductId,
  DATE(d.CourierDate) AS DeliveryDate,
  d.CourierTime AS DeliveryTime,
  CAST(v.DeliveryCostPerProduct AS NUMERIC) AS Price
  
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_invbtch` b 
  
  INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.invhead` i  on  b.BatchId = i.InvoiceBatchID and b.CountryCode = i.Country 
  INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_labels` d  ON IFNULL(d.BatchID,0) = b.BatchID and d.InvoiceNumber = i.InvoiceNumber and d.CountryCode = b.countryCode and d.InvoiceFranchiseAccountNumber = i.DeliveryFranchisee
  LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.prods` p  on d.ProductId = p.ProductId and d.CountryCode = p.CountryCode
  LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.invdet` v  on d.InvoiceNumber = v.InvoiceNumber and i.DeliveryFranchisee = v.DeliveryFranchisee and i.Country = v.CountryCode and p.LabelPrefix = v.Prefix
  
  WHERE b.CountryCode = CountryCode  and d.PickupDelivery = 'D'
  AND b.released = 1
  ;

END;

