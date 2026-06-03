-- Miscellaneous.dtsx / Maintain KPIGroupDetails
-- SSIS: KRILLIN dbo.KPIGroupDet -> CUBE.FastwayDW dbo.KPIGroupDet
CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.vw_dbo_KPIGroupDet` AS
SELECT
  *
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_KPIGroupDet`;