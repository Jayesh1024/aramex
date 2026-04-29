-- Miscellaneous.dtsx / Maintain DLBS InvoiceHeader
-- SSIS: FWFastlabel.dbo.fl_DLBSInvoiceHeader -> CUBE.FastwayDW dbo.DLBSInvoiceHeader
CREATE OR REPLACE VIEW `{{ project_id }}.{{ gold_dataset_id }}.vw_dbo_DLBSInvoiceHeader` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ silver_dataset_id }}.FWFastlabel_dbo_fl_DLBSInvoiceHeader`;
