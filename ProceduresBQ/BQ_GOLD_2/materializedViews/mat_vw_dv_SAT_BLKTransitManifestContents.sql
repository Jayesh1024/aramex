CREATE OR REPLACE MATERIALIZED VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_BLKTransitManifestContents`
AS
SELECT
    TransitManifestId,
    ContainerManifestId,
    ContainerManiSequenceNo,
    'BLK_TransitContents' AS RecordSource
FROM
    `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_BLK_TransitManifestContents`;