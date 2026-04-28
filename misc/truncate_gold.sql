BEGIN
  -- Declare a variable to hold the dynamic SQL string
  DECLARE query_string STRING;

  -- Loop through the result of your metadata query
  FOR record IN (
    SELECT 
      table_name,
      CONCAT("TRUNCATE TABLE `", table_catalog, ".", table_schema, ".", table_name, "`") AS cmd
    FROM 
      `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.INFORMATION_SCHEMA.TABLES`
    WHERE 
      table_type = 'BASE TABLE'
  )
  DO
    -- Assign the command to the variable and execute it
    SET query_string = record.cmd;

    IF record.table_name = 'Staging_LoadControl' THEN ITERATE; END IF;
    EXECUTE IMMEDIATE query_string;
    
  END FOR;
END;