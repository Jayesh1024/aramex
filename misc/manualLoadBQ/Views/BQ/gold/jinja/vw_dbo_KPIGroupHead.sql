-- Miscellaneous.dtsx / Maintain KPIGroupHeads
-- SSIS: KRILLIN dbo.KPIGroupHead -> CUBE.FastwayDW dbo.KPIGroupHead
CREATE OR REPLACE VIEW `{{ project_id }}.{{ gold_dataset_id }}.vw_dbo_KPIGroupHead` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ silver_dataset_id }}.KRILLIN_dbo_KPIGroupHead`;
