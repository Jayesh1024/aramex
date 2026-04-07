-- ==========================================================================================
-- Routine:		Set_LastValue
-- Description: Sets the Last Id/Date used to query the source system for latest data
--              If @ColumName parameter is not provided the one in ControlTable is used
--              If @LastValue parameter is not provided the relevant staging table is queried
-- Example:		Exec [Staging].[Set_LastValue] 'LabelMaster'  
--          	Exec [Staging].[Set_LastValue] 'tsections', 'TSCourierDate'
--          	Exec [Staging].[Set_LastValue] 'tsections', 'TSCourierDate', '2019-03-31 23:32:51'
-- History:
--	23/11/2018  P. Waldron		Routine Written
--	02/07/2019  P. Waldron		Refactor to use RecordSource instead of DatasetName
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ dataset_id }}.staging.Set_LastValue`(
  IN  p_RecordSource  STRING,
  IN  p_ColumnName    STRING,    -- Pass NULL to use value from LoadControl
  IN  p_LastValue     STRING,    -- Pass NULL to derive from staging table
  IN  p_Force         BOOL       -- Pass FALSE for default behaviour
)
BEGIN

  DECLARE v_Msg             STRING;
  DECLARE v_Stg_ColumnName  STRING;
  DECLARE v_Stg_LastValue   STRING;
  DECLARE v_StagingDataset  STRING;
  DECLARE v_StagingTable    STRING;
  DECLARE v_StagingTableFQN STRING;
  DECLARE v_ColumnName      STRING;
  DECLARE v_LastValue       STRING DEFAULT p_LastValue;
  DECLARE v_RowCount        INT64;
  DECLARE v_TableExists     INT64;
  DECLARE v_SQL             STRING;

  -- -----------------------------------------------------------------------
  -- Get current values from LoadControl
  -- -----------------------------------------------------------------------
  SELECT
    COUNT(*)    INTO v_RowCount,
    MAX(ColumnName)  INTO v_Stg_ColumnName,
    MAX(LastValue)   INTO v_Stg_LastValue
  FROM `{{ project_id }}.{{ dataset_id }}.staging.LoadControl`
  WHERE RecordSource = p_RecordSource;

  IF v_RowCount <> 1 THEN
    SET v_Msg = CONCAT('RecordSource ''', p_RecordSource, ''' not in LoadControl table');
    RAISE USING MESSAGE = v_Msg;
  END IF;

  -- -----------------------------------------------------------------------
  -- Locate Staging Table
  -- BQ equivalent of: 'Staging' + RIGHT(DatasetName, CHARINDEX('.', REVERSE(DatasetName))) + '_Stg'
  -- Assumes DatasetName is formatted as 'schema.TableName'
  -- -----------------------------------------------------------------------
  SELECT
    CONCAT(
      'staging.',
      REGEXP_EXTRACT(DatasetName, r'[^.]+$'),   -- extract part after last '.'
      '_Stg'
    ) INTO v_StagingTable
  FROM `{{ project_id }}.{{ dataset_id }}.staging.LoadControl`
  WHERE RecordSource = p_RecordSource;

  SET v_StagingTableFQN = CONCAT('`{{ project_id }}.{{ dataset_id }}.', v_StagingTable, '`');

  -- Verify staging table exists via INFORMATION_SCHEMA
  SELECT COUNT(*) INTO v_TableExists
  FROM `{{ project_id }}.{{ dataset_id }}`.INFORMATION_SCHEMA.TABLES
  WHERE CONCAT(table_schema, '.', table_name) = REPLACE(REPLACE(v_StagingTable, '`', ''), '{{ project_id }}.{{ dataset_id }}.', '');

  IF v_TableExists = 0 THEN
    SET v_Msg = CONCAT('Staging table not found for RecordSource ''', p_RecordSource, '''');
    RAISE USING MESSAGE = v_Msg;
  END IF;

  -- -----------------------------------------------------------------------
  -- Derive LastValue dynamically if not supplied
  -- -----------------------------------------------------------------------
  IF v_LastValue IS NULL THEN

    SET v_ColumnName = IFNULL(p_ColumnName, v_Stg_ColumnName);  -- Fall back to LoadControl column

    SET v_SQL = CONCAT(
      'SET @last_val = (SELECT CAST(MAX(`', v_ColumnName, '`) AS STRING) FROM ', v_StagingTableFQN, ')'
    );

    EXECUTE IMMEDIATE v_SQL INTO v_LastValue;

  END IF;

  -- -----------------------------------------------------------------------
  -- Update LoadControl if a value was found or force flag is set
  -- -----------------------------------------------------------------------
  IF v_LastValue IS NOT NULL OR p_Force = TRUE THEN
    UPDATE `{{ project_id }}.{{ dataset_id }}.staging.LoadControl`
    SET LastValue = v_LastValue
    WHERE RecordSource = p_RecordSource;
  END IF;

END;