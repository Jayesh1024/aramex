CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_BLK_ContainerManifestContents_Stg`(
  LastScanDate STRING
)
BEGIN
  --CAST('2023-05-01T00:00:00' AS DATETIME);

  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_BLK_ContainerManifestContents_Stg`
  SELECT MC.ContainerManifestId
        ,LabelNo
        ,ScanDate
        ,ScanUserId
        ,MC.Destination
        ,MixedManifestId
        ,Weight
        ,CF
    FROM `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_BLK_ContainerManifestContents` MC 
   JOIN `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_BLK_ContainerManifest` M ON M.ContainerManifestId = MC.ContainerManifestId
  WHERE ScanDate > CAST(LastScanDate AS DATETIME)
  LIMIT 200000
  ;

END;