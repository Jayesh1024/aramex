-- Miscellaneous.dtsx / Maintain fl_CustomerZoneSatchelOverrides
-- SSIS: Fastway.dbo.fl_CustomerZoneSatchelOverrides -> CUBE.FastwayDW dbo.fl_CustomerZoneSatchelOverrides
CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_fl_CustomerZoneSatchelOverrides` AS
SELECT
  *
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_fl_CustomerZoneSatchelOverrides`;