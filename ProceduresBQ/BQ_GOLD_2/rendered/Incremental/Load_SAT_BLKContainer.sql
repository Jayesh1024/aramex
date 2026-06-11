CREATE OR REPLACE MATERIALIZED VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.SAT_BLKContainer`
AS
SELECT
    CountryId,
    ContainerId,
    ContainerBarcode,
    CurrentStatus,
    CurrentLocation,
    CurrentDestination,
    LastScanId,
    LastActionDate,
    LastActionUserId,
    'BLK_Container' AS RecordSource
FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_BLK_Container`

