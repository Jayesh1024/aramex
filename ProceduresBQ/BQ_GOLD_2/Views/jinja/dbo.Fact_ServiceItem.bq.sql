CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Fact_ServiceItem`
AS
SELECT       s.LabelNo, s.Country,s.ProductCode, s.ServiceItem, s.CountryCode, s.ProductId, s.ServiceItemId, s.CreatedOn, s.ConId, s.LineNo, s.FMSInvoiceNo, s.FMSInvoiceDate, s.Price, s.PickUpPrice, s.DeliveryPrice, s.DLBSPrice
FROM         `{{ project_id }}.{{ dataset_id }}.dv_LSAT_Label_Product_ServiceItem` AS s
WHERE        (s.IsCurrent = 1)