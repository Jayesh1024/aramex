-- Miscellaneous.dtsx / Maintain TSSDetail
-- SSIS: Fastway.dbo.tssdetail -> CUBE.FastwayDW dbo.Tssdetail (target casing in SSIS)
CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Tssdetail` AS
SELECT
  *
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_tssdetail`;