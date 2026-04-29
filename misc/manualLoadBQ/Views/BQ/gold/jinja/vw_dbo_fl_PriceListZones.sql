-- Miscellaneous.dtsx / Maintain fl_PriceZones (loads fl_PriceListZones)
-- SSIS: Fastway.dbo.fl_PriceListZones -> CUBE.FastwayDW dbo.fl_PriceListZones
CREATE OR REPLACE VIEW `{{ project_id }}.{{ gold_dataset_id }}.vw_dbo_fl_PriceListZones` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ silver_dataset_id }}.Fastway_dbo_fl_PriceListZones`;
