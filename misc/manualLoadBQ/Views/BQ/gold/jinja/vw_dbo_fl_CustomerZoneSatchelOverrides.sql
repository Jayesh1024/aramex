-- Miscellaneous.dtsx / Maintain fl_CustomerZoneSatchelOverrides
-- SSIS: Fastway.dbo.fl_CustomerZoneSatchelOverrides -> CUBE.FastwayDW dbo.fl_CustomerZoneSatchelOverrides
CREATE OR REPLACE VIEW `{{ project_id }}.{{ gold_dataset_id }}.vw_dbo_fl_CustomerZoneSatchelOverrides` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ silver_dataset_id }}.Fastway_dbo_fl_CustomerZoneSatchelOverrides`;
