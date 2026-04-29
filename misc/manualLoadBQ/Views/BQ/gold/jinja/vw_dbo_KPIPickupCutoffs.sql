-- Miscellaneous.dtsx / Maintain KPI Tables
-- SSIS OLE DB Source: dbo.KPIPickupCutoffs (KRILLIN; SqlCommand with CAST CountryCode)
CREATE OR REPLACE VIEW `{{ project_id }}.{{ gold_dataset_id }}.vw_dbo_KPIPickupCutoffs` AS
SELECT
  CAST(CountryCode AS INT64) AS CountryCode,
  RFCode,
  CutoffTime
FROM
  `{{ project_id }}.{{ silver_dataset_id }}.KRILLIN_dbo_KPIPickupCutoffs`;
