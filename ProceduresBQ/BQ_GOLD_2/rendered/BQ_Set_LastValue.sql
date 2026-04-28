-- ==========================================================================================
-- Routine:		Set_LastValue
-- Description: Sets the Last Id/Date used to query the source system for latest data
--              If @ColumName parameter is not provided the one in ControlTable is used
--              If @LastValue parameter is not provided the relevant Staging table is queried
-- Example:		Exec [Staging].[Set_LastValue] LabelMaster
--          	Exec [Staging].[Set_LastValue] tsections, TSCourierDate
--          	Exec [Staging].[Set_LastValue] tsections, TSCourierDate, 2019-03-31 23:32:51
-- History:
--	23/11/2018  P. Waldron		Routine Written
--	02/07/2019  P. Waldron		Refactor to use RecordSource instead of DatasetName
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.Staging_Set_LastValue`(
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
  DECLARE v_LastValue       STRING DEFAULT p_LastValue;
  DECLARE v_RowCount        INT64;
  DECLARE v_TableExists     INT64;
  DECLARE v_SQL             STRING;

  -- -----------------------------------------------------------------------
  -- Get current values from LoadControl
  -- -----------------------------------------------------------------------
  SET v_RowCount = (
    SELECT COUNT(*)
    FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
    WHERE RecordSource = p_RecordSource
  );

  SET v_Stg_ColumnName = (
    SELECT MAX(ColumnName)
    FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
    WHERE RecordSource = p_RecordSource
  );

  SET v_Stg_LastValue = (
    SELECT MAX(LastValue)
    FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
    WHERE RecordSource = p_RecordSource
  );

  IF v_RowCount <> 1 THEN
    SET v_Msg = CONCAT('RecordSource ', p_RecordSource, ' not in LoadControl table');
    RAISE USING MESSAGE = v_Msg;
  END IF;

  -- -----------------------------------------------------------------------
  -- Locate Staging Table
  -- Assumes DatasetName is formatted as schema.TableName
  -- -----------------------------------------------------------------------
  SET v_StagingTable = (
    SELECT
      CASE 
        WHEN p_RecordSource = 'EBAY' THEN
          CONCAT(
            'Staging_',
            (SELECT STRING_AGG(CONCAT(UPPER(SUBSTR(word, 1, 1)), LOWER(SUBSTR(word, 2))), "_" ORDER BY OFFSET)
                FROM UNNEST(SPLIT(ARRAY_REVERSE(SPLIT(DatasetName, '.'))[OFFSET(0)], "_")) AS word
                WITH OFFSET),
            '_Stg'
          )
        ELSE
          CONCAT('Staging_', ARRAY_REVERSE(SPLIT(DatasetName, '.'))[OFFSET(0)],'_Stg')
      END
   
    FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
    WHERE RecordSource = p_RecordSource
  );

  SET v_StagingTableFQN = FORMAT('prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.%s', v_StagingTable);

  -- Verify Staging table exists via INFORMATION_SCHEMA
  SET v_TableExists = (
    SELECT COUNT(*)
    FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.`.INFORMATION_SCHEMA.TABLES
    WHERE table_name = ARRAY_REVERSE(SPLIT(v_StagingTable, '.'))[OFFSET(0)]
  );

  IF v_TableExists = 0 THEN
    SET v_Msg = CONCAT('Staging table not found for RecordSource ', p_RecordSource);
    RAISE USING MESSAGE = v_Msg;
  END IF;

  -- -----------------------------------------------------------------------
  -- Derive LastValue dynamically if not supplied
  -- -----------------------------------------------------------------------
  IF v_LastValue IS NULL THEN

    SET v_ColumnName = IFNULL(p_ColumnName, v_Stg_ColumnName);

    SET v_SQL = FORMAT('SELECT CAST(MAX(%s) AS STRING) FROM `%s`', v_ColumnName, v_StagingTableFQN);

    EXECUTE IMMEDIATE v_SQL INTO v_LastValue;

  END IF;

  -- -----------------------------------------------------------------------
  -- Update LoadControl if a value was found or force flag is set
  -- -----------------------------------------------------------------------
  IF v_LastValue IS NOT NULL OR p_Force = TRUE THEN
    UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
    SET LastValue = v_LastValue
    WHERE RecordSource = p_RecordSource;
  END IF;

END;