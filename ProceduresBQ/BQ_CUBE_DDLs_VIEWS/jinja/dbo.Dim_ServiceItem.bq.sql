CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Dim_ServiceItem`
AS
SELECT        l.LabelNo, l.Country, l.ProductCode, l.ServiceItem, s.CountryCode, s.ProductId, s.ServiceItemId, s.CreatedOn, s.ConId, s.LineNo, s.FMSInvoiceNo, s.FMSInvoiceDate, s.Price, s.PickupPrice, s.DeliveryPrice, s.DLBSPrice
FROM            `{{ project_id }}.{{ dataset_id }}.dv_LNK_Label_Product_ServiceItem` AS l INNER JOIN
                         `{{ project_id }}.{{ dataset_id }}.dv_LSAT_Label_Product_ServiceItem` AS s ON l.Label_Product_ServiceItem_HSK = s.Label_Product_ServiceItem_HSK
WHERE        (s.IsCurrent = 1)