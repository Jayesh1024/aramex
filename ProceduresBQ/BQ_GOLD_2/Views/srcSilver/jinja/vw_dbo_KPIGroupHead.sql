-- Miscellaneous.dtsx / Maintain KPIGroupHeads
-- SSIS: KRILLIN dbo.KPIGroupHead -> CUBE.FastwayDW dbo.KPIGroupHead
CREATE OR REPLACE VIEW `{{ project_id }}.{{ target_dataset_id }}.vw_dbo_KPIGroupHead` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_KPIGroupHead`;
