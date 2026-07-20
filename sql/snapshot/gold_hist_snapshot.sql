DECLARE src_project STRING DEFAULT 'prj-drgfly-prod-sp-01';
DECLARE src_dataset STRING DEFAULT 'bq_ds_prod_euw2_oceania_cube_gold_1';
DECLARE target_dataset STRING DEFAULT 'bq_ds_prod_euw2_oceania_cube_gold_1_bkp';
DECLARE snapshot_time DATE DEFAULT CURRENT_DATE();

-- Loop through all physical tables in the dataset
FOR t IN (
  SELECT table_name 
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.INFORMATION_SCHEMA.TABLES` 
  WHERE table_type = 'BASE TABLE'
) 
DO
  EXECUTE IMMEDIATE FORMAT("""
    CREATE SNAPSHOT TABLE `%s.%s.%s_snapshot_%s`
    CLONE `%s.%s.%s`
  """, src_project, target_dataset, t.table_name, snapshot_time, src_project, src_dataset, t.table_name);
END FOR;