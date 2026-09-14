CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIExcludedDates` AS
SELECT
  CAST(Country as INT64) AS CountryCode,
  Franchise,
  Date,
  Comment
FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_KPIExcludedDates`
