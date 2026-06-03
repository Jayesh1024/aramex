-- Miscellaneous.dtsx / Maintain fl_PriceLists
-- SSIS: Fastway.dbo.fl_PriceLists -> CUBE.FastwayDW dbo.fl_PriceLists
CREATE OR REPLACE VIEW `{{ project_id }}.{{ target_dataset_id }}.vw_dbo_fl_PriceLists` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_fl_PriceLists`;
