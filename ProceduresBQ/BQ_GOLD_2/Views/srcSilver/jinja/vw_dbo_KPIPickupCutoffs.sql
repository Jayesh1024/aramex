-- Miscellaneous.dtsx / Maintain KPI Tables
-- SSIS OLE DB Source: dbo.KPIPickupCutoffs (KRILLIN; SqlCommand with CAST CountryCode)
CREATE OR REPLACE VIEW `{{ project_id }}.{{ target_dataset_id }}.vw_dbo_KPIPickupCutoffs` AS
SELECT
  CAST(CountryCode AS INT64) AS CountryCode,
  RFCode,
  CutoffTime
FROM
  `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_KPIPickupCutoffs`;
