CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIMatrix` AS
SELECT
  CountryCode,
  PickupFranchise,
  DeliveryFranchise,
  CAST(Days AS INT64) AS Days,
  EconomyDays,
  PriorityDays
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_NonLocalKPIMatrix`
WHERE
  IFNULL(Prefix, '') = ''