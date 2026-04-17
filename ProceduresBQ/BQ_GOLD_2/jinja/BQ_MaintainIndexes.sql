-- ==========================================================================================
-- Function:    MaintainIndexes
-- Description: Disables or Rebuilds one or all nonclustered indexes for a table
--              Defrags all indexes for one or all tables (rebuilds are done offline)
--              Updates Statistics
-- Example:
--      EXEC [dbo].[MaintainIndexes] @Operation = 'REBUILD', @TableName = 'Fact_Scan_KPI'
--      EXEC [dbo].[MaintainIndexes] @Operation = 'DEFRAG', @SchemaName = 'dv', @TableName = 'HUB_Location', @IndexName = 'IX_LatLong'
--      EXEC [dbo].[MaintainIndexes] @Operation = 'DISABLE', @SchemaName = 'dv', @TableName = 'ALL'
--      EXEC [dbo].[MaintainIndexes] @Operation = 'STATS', @SchemaName = 'dbo' 
--      EXEC [dbo].[MaintainIndexes] @Operation = 'DEFRAG', @SchemaName = 'dv', @Whatif = 1
-- History:
--  12/02/2019  P. Waldron      Routine Written
--  03/02/2020  P. Waldron      Implement more accurate frag check for ColumnstoreIndexes 
--  12/11/2020  P. Waldron      Improve selection of partioned indexes
-- ==========================================================================================

CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dbo_MaintainIndexes`(
  p_Operation STRING,
  p_SchemaName STRING,
  p_TableName STRING,
  p_IndexName STRING,
  p_Whatif INT64
)
BEGIN
  /*
  ** Routine: MaintainIndexes
  ** Description: No-Op in BigQuery. Retained for orchestration logging.
  */

  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Component_Start STRING DEFAULT CONCAT('START: ', IFNULL(p_SchemaName, 'dbo'), '.', IFNULL(p_TableName, 'ALL'), ' ', p_Operation);
  DECLARE v_Component_End STRING DEFAULT CONCAT('END: ', IFNULL(p_SchemaName, 'dbo'), '.', IFNULL(p_TableName, 'ALL'), ' ', p_Operation);
  DECLARE v_Result STRING DEFAULT 'Success';
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_Inserted INT64 DEFAULT 0;
  DECLARE v_Updated INT64 DEFAULT 0;

  -- Initial logging to track start of maintenance task
  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(v_Component_Start, 0, v_Started, NULL, NULL, NULL, 0, 0, -1);

  BEGIN
    -- BIGQUERY NOTE: This procedure is intentionally a No-Op. 
    -- BigQuery is a serverless managed service that handles its own storage, indexing, 
    -- partitioning, and statistics automatically. Manual index maintenance 
    -- logic (REBUILD, DISABLE, DEFRAG, STATS) is not applicable.
    
    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result = 'Failed';
    SET v_ErrorMessage = @@error.message;
  END;

  -- End logging covering both success and failure paths.
  SET v_Ended = CURRENT_DATETIME();
  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
    v_Component_End, 
    0, 
    v_Started, 
    v_Ended, 
    v_Result, 
    v_ErrorMessage, 
    v_Inserted, 
    v_Updated, 
    -1
  );

END;