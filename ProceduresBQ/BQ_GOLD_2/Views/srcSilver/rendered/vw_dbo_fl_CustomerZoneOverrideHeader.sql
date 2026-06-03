-- Miscellaneous.dtsx / Maintain fl_CustomerZoneOverrideHeader
-- SSIS: Fastway.dbo.fl_CustomerZoneOverrideHeader -> CUBE.FastwayDW dbo.fl_CustomerZoneOverrideHeader
CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.vw_dbo_fl_CustomerZoneOverrideHeader` AS
SELECT
  *
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_fl_CustomerZoneOverrideHeader`;