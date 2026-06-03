-- Miscellaneous.dtsx / Maintain SPK_SprinklRTickets
-- SSIS: KRILLIN dbo.SPK_SprinklRTickets -> CUBE.FastwayDW dbo.SPK_SprinklRTickets
CREATE OR REPLACE VIEW `{{ project_id }}.{{ target_dataset_id }}.vw_dbo_SPK_SprinklRTickets` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_SPK_SprinklRTickets`;
