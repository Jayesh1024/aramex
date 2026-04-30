CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Fact_ServiceCon`
AS
SELECT s.ConId
      ,s.Country
      ,l.ProductCode
      ,l.ServiceItem
      ,l.ServiceItemId
      ,CountryId
      ,ProductId
      ,CreatedOn
      ,FMSInvoiceNo
      ,FMSInvoiceDate
      ,Price
      ,Tax
      ,Total
      ,PickUpPrice
      ,DeliveryPrice
      ,PLBSBatchId
      ,PLBSInvoiceNo
      ,PLBSInvoiceDate
      ,PLBSPrice
      ,PLBSTax
      ,PLBSTotal
      ,DLBSBatchId
      ,DLBSInvoiceNo
      ,DLBSInvoiceDate
      ,DLBSPrice
      ,DLBSTax
      ,DLBSTotal
      ,ServicePrice
      ,ServicePriceDiscountPercent
      ,ServicePriceDiscountFixed
      ,ServicePriceCommPercent
      ,ServicePriceComm
      ,UpdatedOn
  FROM `{{ project_id }}.{{ dataset_id }}.dv_LNK_Product_ServiceCon` l
  LEFT JOIN `{{ project_id }}.{{ dataset_id }}.dv_LSAT_Product_ServiceCon` s ON l.Product_ServiceCon_HSK = s.Product_ServiceCon_HSK
  WHERE s.IsCurrent = 1