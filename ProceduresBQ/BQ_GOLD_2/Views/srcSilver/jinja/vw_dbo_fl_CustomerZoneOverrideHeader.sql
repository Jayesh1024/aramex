-- Miscellaneous.dtsx / Maintain fl_CustomerZoneOverrideHeader
-- SSIS: Fastway.dbo.fl_CustomerZoneOverrideHeader -> CUBE.FastwayDW dbo.fl_CustomerZoneOverrideHeader
CREATE OR REPLACE VIEW `{{ project_id }}.{{ target_dataset_id }}.vw_dbo_fl_CustomerZoneOverrideHeader` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_fl_CustomerZoneOverrideHeader`;
