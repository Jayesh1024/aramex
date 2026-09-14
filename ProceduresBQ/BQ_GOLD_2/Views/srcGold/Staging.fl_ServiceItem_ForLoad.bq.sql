CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_fl_ServiceItem_ForLoad` AS
SELECT 
  CountryId, 
  ProductId, 
  ServiceItemId, 
  DisplayText, 
  Description
FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_fl_ServiceItem_Stg`

UNION ALL

SELECT 
  r.CountryId, 
  r.ProductId, 
  r.ServiceItemId, 
  r.DisplayText, 
  r.Description
FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_fl_ServiceItem_Recovered` AS r
WHERE NOT EXISTS (
  SELECT 1
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_fl_ServiceItem_Stg` AS s
  WHERE s.CountryId     = r.CountryId
    AND s.ProductId     = r.ProductId
    AND s.ServiceItemId = r.ServiceItemId
);