-- Miscellaneous.dtsx / Maintain SPK_SprinklRTickets
-- SSIS: KRILLIN dbo.SPK_SprinklRTickets -> CUBE.FastwayDW dbo.SPK_SprinklRTickets
CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_SPK_SprinklRTickets` AS
SELECT
  *
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_SPK_SprinklRTickets`;