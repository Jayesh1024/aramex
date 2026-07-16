DECLARE src_project STRING DEFAULT 'prj-drgfly-prod-sp-01';
DECLARE src_dataset STRING DEFAULT 'bq_ds_prod_euw2_oceania_cube_gold_1';
DECLARE target_dataset STRING DEFAULT 'bq_ds_prod_euw2_oceania_cube_gold_1_bkp';

-- Loop through all physical tables in the dataset
FOR t IN (
  SELECT table_name 
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.INFORMATION_SCHEMA.TABLES` 
  WHERE table_type = 'BASE TABLE'
) 
DO
  EXECUTE IMMEDIATE FORMAT("""
    CREATE SNAPSHOT TABLE `%s.%s.%s_snapshot`
    CLONE `%s.%s.%s`
  """, src_project, target_dataset, t.table_name, src_project, src_dataset, t.table_name);
END LOOP;