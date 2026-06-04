-- Miscellaneous.dtsx / Maintain KPIGroupHeads
-- SSIS: KRILLIN dbo.KPIGroupHead -> CUBE.FastwayDW dbo.KPIGroupHead
CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIGroupHead` AS
SELECT
  *
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_KPIGroupHead`;