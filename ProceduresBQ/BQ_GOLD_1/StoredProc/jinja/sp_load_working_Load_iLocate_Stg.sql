CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_working_Load_iLocate_Stg`(
  NextID INT64
)
BEGIN
  DECLARE EndID INT64;

  SET EndID = NextID  + 4000000;

  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.working_Load_iLocate_Stg`
  SELECT
  ID, iLocate 
  FROM `{{ project_id }}.{{ source_dataset_id }}.FastwayReports_dbo_TrackAndTraceData`
  WHERE ID > NextID AND ID  <= EndID
  AND IFNULL(iLocate,'') != ''
  ;

END;