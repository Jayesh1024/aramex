-- Miscellaneous.dtsx / Maintain PLBS InvoiceHeader
-- SSIS: FWFastlabel.dbo.fl_PLBSInvoiceHeader -> CUBE.FastwayDW dbo.PLBSInvoiceHeader
CREATE OR REPLACE VIEW `{{ project_id }}.{{ target_dataset_id }}.vw_dbo_PLBSInvoiceHeader` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ source_dataset_id }}.FWFastlabel_dbo_fl_PLBSInvoiceHeader`;
