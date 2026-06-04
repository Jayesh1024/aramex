-- Miscellaneous.dtsx / Maintain ProformaInvoice
-- SSIS: KRILLIN dbo.ProformaInvoices -> CUBE.FastwayDW dbo.ProformaInvoices
CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_ProformaInvoices` AS
SELECT
  *
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_ProformaInvoices`;