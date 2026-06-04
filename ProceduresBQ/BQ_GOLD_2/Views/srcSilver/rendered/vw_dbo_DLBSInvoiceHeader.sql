-- Miscellaneous.dtsx / Maintain DLBS InvoiceHeader
-- SSIS: FWFastlabel.dbo.fl_DLBSInvoiceHeader -> CUBE.FastwayDW dbo.DLBSInvoiceHeader
CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_DLBSInvoiceHeader` AS
SELECT
  *
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.FWFastlabel_dbo_fl_DLBSInvoiceHeader`;