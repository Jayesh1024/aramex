CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_BLK_ContainerManifest_Stg`(
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_BLK_ContainerManifest_Stg`
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
    FROM `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_BLK_ContainerManifest`
  ;

END;