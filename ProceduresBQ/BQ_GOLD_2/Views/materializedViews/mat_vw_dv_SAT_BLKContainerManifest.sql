CREATE OR REPLACE MATERIALIZED VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_BLKContainerManifest`
AS
SELECT
    ContainerManifestId,
    ContainerId,
    ContainerBarcode,
    Location,
    Destination,
    TotalParcels,
    Status,
    ActionDate,
    IsMixed,
    MixedUnknownDest,
    CurrentLocation,
    CountryCode,
    Sortation,
    SortationStatus,
    SortationOpen,
    SortationClosed,
    'BLK_ManifestID' AS RecordSource
FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_BLK_ContainerManifest`
