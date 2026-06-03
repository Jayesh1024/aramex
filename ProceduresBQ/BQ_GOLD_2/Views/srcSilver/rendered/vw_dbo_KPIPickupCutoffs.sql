-- Miscellaneous.dtsx / Maintain KPI Tables
-- SSIS OLE DB Source: dbo.KPIPickupCutoffs (KRILLIN; SqlCommand with CAST CountryCode)
CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.vw_dbo_KPIPickupCutoffs` AS
SELECT
  CAST(CountryCode AS INT64) AS CountryCode,
  RFCode,
  CutoffTime
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_KPIPickupCutoffs`;