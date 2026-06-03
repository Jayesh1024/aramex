-- Miscellaneous.dtsx / Maintain DLS InvoiceRFHeader
-- SSIS: KRILLIN dbo.DLS_InvoiceRFHeader -> CUBE.FastwayDW dbo.DLS_InvoiceRFHeader
CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.vw_dbo_DLS_InvoiceRFHeader` AS
SELECT
  *
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_DLS_InvoiceRFHeader`;