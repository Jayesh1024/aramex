CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_Label_Interbranch_Stg`(
  LastBatchID INT64,
  RecordSource STRING
)
BEGIN
  DECLARE Batchsize INT64;
  DECLARE CountryCode INT64;
  SET Batchsize = 5000000;
  SET CountryCode = 0;

  IF RecordSource = 'InterBranchAU' THEN
    SET CountryCode = 1;
  END IF;
  IF RecordSource = 'InterBranchNZ' THEN
    SET CountryCode = 6;
  END IF;

  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_Label_Interbranch_Stg`
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
  
  FROM `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_invbtch` b 
  
  INNER JOIN `{{ project_id }}.{{ source_dataset_id }}.invhead` i  on  b.BatchId = i.InvoiceBatchID and b.CountryCode = i.Country 
  INNER JOIN `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_labels` d  ON IFNULL(d.BatchID,0) = b.BatchID and d.InvoiceNumber = i.InvoiceNumber and d.CountryCode = b.countryCode and d.InvoiceFranchiseAccountNumber = i.DeliveryFranchisee
  LEFT JOIN `{{ project_id }}.{{ source_dataset_id }}.prods` p  on d.ProductId = p.ProductId and d.CountryCode = p.CountryCode
  LEFT JOIN `{{ project_id }}.{{ source_dataset_id }}.invdet` v  on d.InvoiceNumber = v.InvoiceNumber and i.DeliveryFranchisee = v.DeliveryFranchisee and i.Country = v.CountryCode and p.LabelPrefix = v.Prefix
  
  WHERE b.CountryCode = CountryCode  and d.PickupDelivery = 'D'
  AND b.BatchID = LastBatchID
  AND b.released = 1
  ;

END;