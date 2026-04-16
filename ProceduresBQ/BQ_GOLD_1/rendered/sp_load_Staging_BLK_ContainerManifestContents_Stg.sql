CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.sp_load_Staging_BLK_ContainerManifestContents_Stg`(
  LastScanDate STRING
)
BEGIN
  --CAST('2023-05-01T00:00:00' AS DATETIME);

  INSERT INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_BLK_ContainerManifestContents_Stg`
  SELECT MC.ContainerManifestId
        ,LabelNo
        ,ScanDate
        ,ScanUserId
        ,MC.Destination
        ,MixedManifestId
        ,Weight
        ,CF
    FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_krillin_silver.Fastway_dbo_BLK_ContainerManifestContents` MC 
   JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_krillin_silver.Fastway_dbo_BLK_ContainerManifest` M ON M.ContainerManifestId = MC.ContainerManifestId
  WHERE ScanDate > CAST(LastScanDate AS DATETIME)
  LIMIT 200000
  ;

END;