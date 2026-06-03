-- Miscellaneous.dtsx / Maintain Postcodes
-- SSIS: Fastway.dbo.TSS_PostCodeMaster (WHERE ISNULL(Suburb,'') != '') -> CUBE.FastwayDW dbo.TSS_PostCodeMaster
CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.vw_dbo_TSS_PostCodeMaster` AS
SELECT
  *
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_TSS_PostCodeMaster`
WHERE
  IFNULL(TRIM(CAST(Suburb AS STRING)), '') != '';