-- Miscellaneous.dtsx / Maintain KPIExcludedDates
-- SSIS: KRILLIN dbo.KPIExcludedDates -> CUBE.FastwayDW dbo.KPIExcludedDates
-- BQ view name: vw_dbo_KPIExcludedDates (schema dbo -> dbo_ prefix per project convention)
CREATE OR REPLACE VIEW `{{ project_id }}.{{ gold_dataset_id }}.vw_dbo_KPIExcludedDates` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ silver_dataset_id }}.KRILLIN_dbo_KPIExcludedDates`;
