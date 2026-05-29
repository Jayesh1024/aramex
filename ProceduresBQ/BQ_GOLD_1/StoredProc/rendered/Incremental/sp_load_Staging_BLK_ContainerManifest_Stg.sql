CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.sp_load_Staging_BLK_ContainerManifest_Stg`(
)
BEGIN
  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_BLK_ContainerManifest_Stg`
  SELECT ContainerManifestId
        ,ContainerId
        ,ContainerBarcode
        ,Location
        ,Destination
        ,TotalParcels
        ,Status
        ,ActionDate
        ,CAST(IsMixed AS INT64) AS IsMixed
        ,CAST(MixedUnknownDest AS INT64) AS MixedUnknownDest
        ,CurrentLocation
        ,CountryCode
        ,CAST(Sortation AS INT64) AS Sortation
        ,SortationStatus
        ,SortationOpen
        ,SortationClosed
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_BLK_ContainerManifest`
  ;

END;