CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Label_Product_ServiceItem_Stg_Combined`
AS

SELECT Label_Product_ServiceItem_HSK
      ,LabelNo_HSK
      ,Product_HSK
      ,ServiceItem_HSK
      ,LabelNo
      ,ConId
      ,ConItemId
      ,LineNo
      ,CountryCode
      ,Country
      ,ProductId
      ,ProductCode
      ,ServiceItemId
      ,ServiceItem
      ,CreatedOn
      ,FMSInvoiceNo
      ,FMSInvoiceDate
      ,Price
      ,Tax
      ,Total
      ,PickUpPrice
      ,DeliveryPrice
      ,DLBSBatchId
      ,DLBSInvoiceNo
      ,DLBSInvoiceDate
      ,DLBSPrice
      ,DLBSTax
      ,DLBSTotal
      ,PLBSBatchId
      ,PLBSInvoiceNo
      ,PLBSInvoiceDate
      ,PLBSPrice
      ,PLBSTax
      ,PLBSTotal
      ,BareProfileId
      ,ServicePrice
      ,ServicePriceComm
      ,ServicePriceCommPercent
      ,ServicePriceDiscountFixed
      ,ServicePriceDiscountPercent
      ,UpdatedOn
      ,Loaded
      ,ProcessId
      ,RecordSource
      ,RecordSourceId
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Label_Product_ServiceItem_Stg`

UNION DISTINCT

SELECT Label_Product_ServiceItem_HSK
      ,LabelNo_HSK
      ,Product_HSK
      ,ServiceItem_HSK
      ,LabelNo
      ,ConId
      ,ConItemId
      ,LineNo
      ,CountryCode
      ,Country
      ,ProductId
      ,ProductCode
      ,ServiceItemId
      ,ServiceItem
      ,CreatedOn
      ,FMSInvoiceNo
      ,FMSInvoiceDate
      ,Price
      ,Tax
      ,Total
      ,PickUpPrice
      ,DeliveryPrice
      ,DLBSBatchId
      ,DLBSInvoiceNo
      ,DLBSInvoiceDate
      ,DLBSPrice
      ,DLBSTax
      ,DLBSTotal
      ,PLBSBatchId
      ,PLBSInvoiceNo
      ,PLBSInvoiceDate
      ,PLBSPrice
      ,PLBSTax
      ,PLBSTotal
      ,BareProfileId
      ,ServicePrice
      ,ServicePriceComm
      ,ServicePriceCommPercent
      ,ServicePriceDiscountFixed
      ,ServicePriceDiscountPercent
      ,UpdatedOn
      ,Loaded
      ,ProcessId
      ,RecordSource
      ,RecordSourceId
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Label_Product_ServiceItem_Stg_Interim`