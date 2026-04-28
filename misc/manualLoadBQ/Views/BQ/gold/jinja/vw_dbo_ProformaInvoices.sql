-- Miscellaneous.dtsx / Maintain ProformaInvoice
-- SSIS: KRILLIN dbo.ProformaInvoices -> CUBE.FastwayDW dbo.ProformaInvoices
CREATE OR REPLACE VIEW `{{ project_id }}.{{ gold_dataset_id }}.vw_dbo_ProformaInvoices` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ silver_dataset_id }}.KRILLIN_dbo_ProformaInvoices`;
