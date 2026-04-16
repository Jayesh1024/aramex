CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_Export_KPI_Delivery_Perf_Data`(
  ProcessID INT64
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_Export_KPI_Delivery_Perf_Data`
  -- TODO: Convert EXEC dbo_Load_FMS_RFBatchingPerformanceBonus to CALL or inline logic
    -- Original: EXEC dbo_Load_FMS_RFBatchingPerformanceBonus ProcessID
  ;

END;