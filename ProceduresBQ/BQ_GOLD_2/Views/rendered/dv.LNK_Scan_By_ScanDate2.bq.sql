CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Scan_By_ScanDate2` AS
  /*
  SELECT * FROM (
	select * from `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Scan_2018`
	union all
	select * from `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Scan`
  ) s
  */
  SELECT * FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Scan` --WITH (INDEX(IX_ScanDate))
  WHERE ScanDate > DATE_ADD(CURRENT_DATETIME(), INTERVAL -1 YEAR)