-- Miscellaneous.dtsx / Maintain fl_PriceZones (loads fl_PriceListZones)
-- SSIS: Fastway.dbo.fl_PriceListZones -> CUBE.FastwayDW dbo.fl_PriceListZones
CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.vw_dbo_fl_PriceListZones` AS
SELECT
  *
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_fl_PriceListZones`;