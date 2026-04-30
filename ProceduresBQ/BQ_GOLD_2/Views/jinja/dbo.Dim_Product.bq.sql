CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Dim_Product`
AS
SELECT hub.Country, hub.ProductCode, sat.ProductId, sat.Description, sat.ItemType, sat.LabelPrefix, sat.LabelsPerBook, sat.Price, sat.FMSBookPrice, sat.FMSDeliveryPrice, sat.FMSPickupPrice, sat.IncludesGST, sat.FMSSalesType, sat.ProductCategory, sat.NotSoldByFSO, sat.SAPGroup, sat.SAPProductGroup, sat.SAPSubProduct
FROM   `{{ project_id }}.{{ dataset_id }}.dv_HUB_Product` AS hub INNER JOIN
             `{{ project_id }}.{{ dataset_id }}.dv_SAT_Product` AS sat ON hub.Product_HSK = sat.Product_HSK
WHERE (sat.IsCurrent = 1)