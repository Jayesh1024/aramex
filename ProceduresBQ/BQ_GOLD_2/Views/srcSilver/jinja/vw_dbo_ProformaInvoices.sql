-- Miscellaneous.dtsx / Maintain ProformaInvoice
-- SSIS: KRILLIN dbo.ProformaInvoices -> CUBE.FastwayDW dbo.ProformaInvoices
CREATE OR REPLACE VIEW `{{ project_id }}.{{ target_dataset_id }}.vw_dbo_ProformaInvoices` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_ProformaInvoices`;
