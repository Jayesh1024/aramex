CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Product`
AS
SELECT hub.Country, hub.ProductCode, sat.ProductId, sat.Description, sat.ItemType, sat.LabelPrefix, sat.LabelsPerBook, sat.Price, sat.FMSBookPrice, sat.FMSDeliveryPrice, sat.FMSPickupPrice, sat.IncludesGST, sat.FMSSalesType, sat.ProductCategory, sat.NotSoldByFSO, sat.SAPGroup, sat.SAPProductGroup, sat.SAPSubProduct
FROM   `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_Product` AS hub INNER JOIN
             `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Product` AS sat ON hub.Product_HSK = sat.Product_HSK
WHERE (sat.IsCurrent = 1)