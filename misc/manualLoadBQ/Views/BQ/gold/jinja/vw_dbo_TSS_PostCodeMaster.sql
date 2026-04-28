-- Miscellaneous.dtsx / Maintain Postcodes
-- SSIS: Fastway.dbo.TSS_PostCodeMaster (WHERE ISNULL(Suburb,'') != '') -> CUBE.FastwayDW dbo.TSS_PostCodeMaster
CREATE OR REPLACE VIEW `{{ project_id }}.{{ gold_dataset_id }}.vw_dbo_TSS_PostCodeMaster` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ silver_dataset_id }}.Fastway_dbo_TSS_PostCodeMaster`
WHERE
  IFNULL(TRIM(CAST(Suburb AS STRING)), '') != '';
