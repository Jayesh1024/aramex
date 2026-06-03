-- Miscellaneous.dtsx / Maintain fl_PriceLists
-- SSIS: Fastway.dbo.fl_PriceLists -> CUBE.FastwayDW dbo.fl_PriceLists
CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.vw_dbo_fl_PriceLists` AS
SELECT
  *
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_fl_PriceLists`;