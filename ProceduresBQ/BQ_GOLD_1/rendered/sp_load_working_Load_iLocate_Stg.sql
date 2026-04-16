CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.sp_load_working_Load_iLocate_Stg`(
  NextID INT64
)
BEGIN
  DECLARE EndID INT64;

  SET EndID = NextID  + 4000000;

  INSERT INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.working_Load_iLocate_Stg`
  SELECT
  ID, iLocate 
  FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_vegeta_silver.FastwayReports_dbo_TrackAndTraceData`
  WHERE ID > NextID AND ID  <= EndID
  AND IFNULL(iLocate,'') != ''
  ;

END;