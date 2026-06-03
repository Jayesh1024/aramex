-- Miscellaneous.dtsx / Maintain DLS InvoiceRFHeader
-- SSIS: KRILLIN dbo.DLS_InvoiceRFHeader -> CUBE.FastwayDW dbo.DLS_InvoiceRFHeader
CREATE OR REPLACE VIEW `{{ project_id }}.{{ target_dataset_id }}.vw_dbo_DLS_InvoiceRFHeader` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_DLS_InvoiceRFHeader`;
