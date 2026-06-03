-- Miscellaneous.dtsx / Maintain fl_PriceZones (loads fl_PriceListZones)
-- SSIS: Fastway.dbo.fl_PriceListZones -> CUBE.FastwayDW dbo.fl_PriceListZones
CREATE OR REPLACE VIEW `{{ project_id }}.{{ target_dataset_id }}.vw_dbo_fl_PriceListZones` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_fl_PriceListZones`;
