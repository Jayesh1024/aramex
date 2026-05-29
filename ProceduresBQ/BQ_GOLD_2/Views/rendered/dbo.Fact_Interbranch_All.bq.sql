CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Interbranch_All`
AS
SELECT        (CASE WHEN SAFE_CAST(s.CountryCode AS INT64) = 1 THEN 'Australia' ELSE 'New Zealand' END) AS Country, s.CountryCode, s.InvoiceFromRF, s.InvoiceToRF, s.BatchId, s.LabelNo, s.Category, s.InvoiceNumber, s.InvoiceDate, s.DeliveryDate, s.DeliveryTime, s.ProductID, (CASE WHEN m.LabelNo IS NOT NULL 
                         THEN m.DLBSPrice ELSE s.Price END) AS Price
FROM                     `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Interbranch` AS s LEFT OUTER JOIN
                         `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF_partitioned` AS m ON s.LabelNo = m.LabelNo AND m.IsCurrent = 1