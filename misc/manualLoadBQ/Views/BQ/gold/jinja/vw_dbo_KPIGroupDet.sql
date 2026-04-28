-- Miscellaneous.dtsx / Maintain KPIGroupDetails
-- SSIS: KRILLIN dbo.KPIGroupDet -> CUBE.FastwayDW dbo.KPIGroupDet
CREATE OR REPLACE VIEW `{{ project_id }}.{{ gold_dataset_id }}.vw_dbo_KPIGroupDet` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ silver_dataset_id }}.KRILLIN_dbo_KPIGroupDet`;
