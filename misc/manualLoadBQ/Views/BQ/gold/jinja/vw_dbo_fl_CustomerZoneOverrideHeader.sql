-- Miscellaneous.dtsx / Maintain fl_CustomerZoneOverrideHeader
-- SSIS: Fastway.dbo.fl_CustomerZoneOverrideHeader -> CUBE.FastwayDW dbo.fl_CustomerZoneOverrideHeader
CREATE OR REPLACE VIEW `{{ project_id }}.{{ gold_dataset_id }}.vw_dbo_fl_CustomerZoneOverrideHeader` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ silver_dataset_id }}.Fastway_dbo_fl_CustomerZoneOverrideHeader`;
