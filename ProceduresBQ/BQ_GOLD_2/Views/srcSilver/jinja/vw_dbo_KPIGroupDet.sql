-- Miscellaneous.dtsx / Maintain KPIGroupDetails
-- SSIS: KRILLIN dbo.KPIGroupDet -> CUBE.FastwayDW dbo.KPIGroupDet
CREATE OR REPLACE VIEW `{{ project_id }}.{{ target_dataset_id }}.vw_dbo_KPIGroupDet` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_KPIGroupDet`;
