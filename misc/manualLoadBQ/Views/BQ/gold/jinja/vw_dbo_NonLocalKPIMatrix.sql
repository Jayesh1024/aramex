-- Miscellaneous.dtsx / Maintain KPI Tables (source extract for KPIMatrix sync)
-- SSIS OLE DB Source: dbo.NonLocalKPIMatrix WHERE Prefix = '' (KRILLIN)
CREATE OR REPLACE VIEW `{{ project_id }}.{{ gold_dataset_id }}.vw_dbo_NonLocalKPIMatrix` AS
SELECT
  CountryCode,
  PickupFranchise,
  DeliveryFranchise,
  CAST(Days AS INT64) AS Days,
  EconomyDays,
  PriorityDays
FROM
  `{{ project_id }}.{{ silver_dataset_id }}.KRILLIN_dbo_NonLocalKPIMatrix`
WHERE
  IFNULL(Prefix, '') = '';
