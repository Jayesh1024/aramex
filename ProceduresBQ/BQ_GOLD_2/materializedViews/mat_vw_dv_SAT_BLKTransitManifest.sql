CREATE OR REPLACE MATERIALIZED VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_BLKTransitManifest`
AS
SELECT
    CountryId,
    TransitManifestId,
    OrderNumber,
    Location,
    Destination,
    TotalContainersLoaded,
    Status,
    DateOpened,
    DateInTransit,
    DateComplete,
    SendToTms,
    DateLastSentToTms,
    Carrier,
    CarrierRate,
    CostPerContainer,
    CostPerParcel,
    CarrierInvoiceNumber,
    TotalParcels,
    LEAPeriod,
    LegalJourneyHours,
    LegalJourneyMinutes,
    ScheduledDepartureTime,
    'BLK_TransitManifest' AS RecordSource
FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_BLK_TransitManifest`;