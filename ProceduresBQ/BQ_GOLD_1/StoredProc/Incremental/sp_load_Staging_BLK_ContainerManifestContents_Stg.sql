CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.sp_load_Staging_BLK_ContainerManifestContents_Stg`(
  IN LastScanDate DATETIME,
  IN Min_ManifestID INT64
)
BEGIN
  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_BLK_ContainerManifestContents_Stg`
  SELECT MC.ContainerManifestId
        ,LabelNo
        ,ScanDate
        ,ScanUserId
        ,MC.Destination
        ,MixedManifestId
        ,Weight
        ,CF
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_BLK_ContainerManifestContents` MC 
  WHERE ScanDate > LastScanDate AND MC.ContainerManifestId > Min_ManifestID
  ORDER BY ScanDate
  ;

END