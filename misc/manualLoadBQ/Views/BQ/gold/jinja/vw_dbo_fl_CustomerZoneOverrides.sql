-- Miscellaneous.dtsx / Maintain fl_CustomerZoneOverrides
-- SSIS: Fastway.dbo.fl_CustomerZoneOverrides -> CUBE.FastwayDW dbo.fl_CustomerZoneOverrides
CREATE OR REPLACE VIEW `{{ project_id }}.{{ gold_dataset_id }}.vw_dbo_fl_CustomerZoneOverrides` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ silver_dataset_id }}.Fastway_dbo_fl_CustomerZoneOverrides`;
