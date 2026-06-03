DECLARE year_start INT64 DEFAULT 2000;
DECLARE year_end INT64 DEFAULT 2030;
DECLARE curr_year INT64;

SET curr_year = year_start;
WHILE curr_year <= year_end DO
  CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_Load_Dim_Time`(1, curr_year, FALSE);
  SET curr_year = curr_year + 1;
END WHILE;