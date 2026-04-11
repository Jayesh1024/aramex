-- ==========================================================================================
-- Routine:		Set_LastValue
-- Description: Sets the Last Id/Date used to query the source system for latest data
--              If @ColumName parameter is not provided the one in ControlTable is used
--              If @LastValue parameter is not provided the relevant Staging table is queried
-- Example:		Exec [Staging].[Set_LastValue] 'LabelMaster'  
--          	Exec [Staging].[Set_LastValue] 'tsections', 'TSCourierDate'
--          	Exec [Staging].[Set_LastValue] 'tsections', 'TSCourierDate', '2019-03-31 23:32:51'
-- History:
--	23/11/2018  P. Waldron		Routine Written
--	02/07/2019  P. Waldron		Refactor to use RecordSource instead of DatasetName
-- ==========================================================================================
<<<<<<< HEAD:ProceduresBQ/Rendered Sandbox SPs/BQ_Interim_Set_LastValue.sql
CREATE OR REPLACE PROCEDURE `searce-sandbox-da-delivery.Aramex_oceania_SP.interimStaging_Set_LastValue`(
=======
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ dataset_id }}.staging_Set_LastValue`(
>>>>>>> refs/remotes/origin/dev_manas:ProceduresBQ/BQ_Set_LastValue.sql
  IN  p_RecordSource  STRING,
  IN  p_ColumnName    STRING,
  IN  p_LastValue     STRING,
  IN  p_Force         BOOL
)
BEGIN

  DECLARE v_Msg             STRING;
  DECLARE v_Stg_ColumnName  STRING;
  DECLARE v_Stg_LastValue   STRING;
  DECLARE v_StagingDataset  STRING;
  DECLARE v_StagingTable    STRING;
  DECLARE v_StagingTableFQN STRING;
  DECLARE v_ColumnName      STRING;
  DECLARE v_LastValue       STRING;
  DECLARE v_RowCount        INT64;
  DECLARE v_TableExists     INT64;
  DECLARE v_SQL             STRING;

  SET v_LastValue = p_LastValue;

  -- -----------------------------------------------------------------------
  -- Get current values from LoadControl
  -- -----------------------------------------------------------------------
<<<<<<< HEAD:ProceduresBQ/Rendered Sandbox SPs/BQ_Interim_Set_LastValue.sql
  SET v_RowCount = (
    SELECT COUNT(*)
    FROM `searce-sandbox-da-delivery.Aramex_oceania.Staging_LoadControl`
    WHERE RecordSource = p_RecordSource
  );

  SET v_Stg_ColumnName = (
    SELECT MAX(ColumnName)
    FROM `searce-sandbox-da-delivery.Aramex_oceania.Staging_LoadControl`
    WHERE RecordSource = p_RecordSource
  );

  SET v_Stg_LastValue = (
    SELECT MAX(LastValue)
    FROM `searce-sandbox-da-delivery.Aramex_oceania.Staging_LoadControl`
    WHERE RecordSource = p_RecordSource
  );
=======
  SELECT
    COUNT(*)    INTO v_RowCount,
    MAX(ColumnName)  INTO v_Stg_ColumnName,
    MAX(LastValue)   INTO v_Stg_LastValue
  FROM `{{ project_id }}.{{ dataset_id }}.staging_LoadControl`
  WHERE RecordSource = p_RecordSource;
>>>>>>> refs/remotes/origin/dev_manas:ProceduresBQ/BQ_Set_LastValue.sql

  IF v_RowCount <> 1 THEN
    SET v_Msg = CONCAT("RecordSource '", p_RecordSource, "' not in LoadControl table");
    RAISE USING MESSAGE = v_Msg;
  END IF;

  -- -----------------------------------------------------------------------
  -- Locate Staging Table
  -- -----------------------------------------------------------------------
<<<<<<< HEAD:ProceduresBQ/Rendered Sandbox SPs/BQ_Interim_Set_LastValue.sql
  SET v_StagingTable = (
    SELECT CONCAT('Staging_', REGEXP_EXTRACT(DatasetName, r'[^.]+$'), '_Stg')
    FROM `searce-sandbox-da-delivery.Aramex_oceania.Staging_LoadControl`
    WHERE RecordSource = p_RecordSource
  );

  SET v_StagingTableFQN = CONCAT('`searce-sandbox-da-delivery.Aramex_oceania.', v_StagingTable, '`');

  -- Verify staging table exists via INFORMATION_SCHEMA
  SET v_TableExists = (
    SELECT COUNT(*)
    FROM `searce-sandbox-da-delivery.`.INFORMATION_SCHEMA.TABLES
    WHERE CONCAT(table_schema, '.', table_name) = REPLACE(REPLACE(v_StagingTable, '`', ''), 'searce-sandbox-da-delivery.Aramex_oceania.', '')
  );
=======
  SELECT
    CONCAT(
      'staging.',
      REGEXP_EXTRACT(DatasetName, r'[^.]+$'),   -- extract part after last '.'
      '_Stg'
    ) INTO v_StagingTable
  FROM `{{ project_id }}.{{ dataset_id }}.staging_LoadControl`
  WHERE RecordSource = p_RecordSource;

  SET v_StagingTableFQN = CONCAT('`{{ project_id }}.{{ dataset_id }}.', v_StagingTable, '`');

  -- Verify staging table exists via INFORMATION_SCHEMA
  SELECT COUNT(*) INTO v_TableExists
  FROM `{{ project_id }}.{{ dataset_id }}`.INFORMATION_SCHEMA.TABLES
  WHERE CONCAT(table_schema, '.', table_name) = REPLACE(REPLACE(v_StagingTable, '`', ''), '{{ project_id }}.{{ dataset_id }}.', '');
>>>>>>> refs/remotes/origin/dev_manas:ProceduresBQ/BQ_Set_LastValue.sql

  IF v_TableExists = 0 THEN
    SET v_Msg = CONCAT("Staging table not found for RecordSource '", p_RecordSource, "'");
    RAISE USING MESSAGE = v_Msg;
  END IF;

  -- -----------------------------------------------------------------------
  -- Derive LastValue dynamically if not supplied
  -- -----------------------------------------------------------------------
  IF v_LastValue IS NULL THEN

    SET v_ColumnName = IFNULL(p_ColumnName, v_Stg_ColumnName);

    SET v_SQL = CONCAT(
      'SELECT CAST(MAX(`', v_ColumnName, '`) AS STRING) FROM ', v_StagingTableFQN
    );

    EXECUTE IMMEDIATE v_SQL INTO v_LastValue;

  END IF;

  -- -----------------------------------------------------------------------
  -- Update LoadControl if a value was found or force flag is set
  -- -----------------------------------------------------------------------
  IF v_LastValue IS NOT NULL OR p_Force = TRUE THEN
<<<<<<< HEAD:ProceduresBQ/Rendered Sandbox SPs/BQ_Interim_Set_LastValue.sql
    UPDATE `searce-sandbox-da-delivery.Aramex_oceania.Staging_LoadControl`
=======
    UPDATE `{{ project_id }}.{{ dataset_id }}.staging_LoadControl`
>>>>>>> refs/remotes/origin/dev_manas:ProceduresBQ/BQ_Set_LastValue.sql
    SET LastValue = v_LastValue
    WHERE RecordSource = p_RecordSource;
  END IF;

END;