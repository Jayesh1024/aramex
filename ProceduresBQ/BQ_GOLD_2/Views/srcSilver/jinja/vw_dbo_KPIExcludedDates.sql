-- Miscellaneous.dtsx / Maintain KPIExcludedDates
-- SSIS: KRILLIN dbo.KPIExcludedDates -> CUBE.FastwayDW dbo.KPIExcludedDates
-- BQ view name: vw_dbo_KPIExcludedDates (schema dbo -> dbo_ prefix per project convention)
CREATE OR REPLACE VIEW `{{ project_id }}.{{ target_dataset_id }}.vw_dbo_KPIExcludedDates` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_KPIExcludedDates`;
