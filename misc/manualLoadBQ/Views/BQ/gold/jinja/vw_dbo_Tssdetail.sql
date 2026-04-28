-- Miscellaneous.dtsx / Maintain TSSDetail
-- SSIS: Fastway.dbo.tssdetail -> CUBE.FastwayDW dbo.Tssdetail (target casing in SSIS)
CREATE OR REPLACE VIEW `{{ project_id }}.{{ gold_dataset_id }}.vw_dbo_Tssdetail` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ silver_dataset_id }}.Fastway_dbo_tssdetail`;
