-- Miscellaneous.dtsx / Maintain SPK_SprinklRTickets
-- SSIS: KRILLIN dbo.SPK_SprinklRTickets -> CUBE.FastwayDW dbo.SPK_SprinklRTickets
CREATE OR REPLACE VIEW `{{ project_id }}.{{ gold_dataset_id }}.vw_dbo_SPK_SprinklRTickets` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ silver_dataset_id }}.KRILLIN_dbo_SPK_SprinklRTickets`;
