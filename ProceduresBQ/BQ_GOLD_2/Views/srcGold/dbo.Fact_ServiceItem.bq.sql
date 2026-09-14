CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_ServiceItem`
AS
SELECT       s.LabelNo, s.Country,s.ProductCode, s.ServiceItem, s.CountryCode, s.ProductId, s.ServiceItemId, s.CreatedOn, s.ConId, s.LineNo, s.FMSInvoiceNo, s.FMSInvoiceDate, s.Price, s.PickUpPrice, s.DeliveryPrice, s.DLBSPrice
FROM         `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Product_ServiceItem` AS s
WHERE        (s.IsCurrent = 1)