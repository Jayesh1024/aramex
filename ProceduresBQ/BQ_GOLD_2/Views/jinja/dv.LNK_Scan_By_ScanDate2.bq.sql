CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dv_LNK_Scan_By_ScanDate2` AS
  /*
  SELECT * FROM (
	select * from `{{ project_id }}.{{ dataset_id }}.dv_LNK_Scan_2018`
	union all
	select * from `{{ project_id }}.{{ dataset_id }}.dv_LNK_Scan`
  ) s
  */
  SELECT * FROM `{{ project_id }}.{{ dataset_id }}.dv_LNK_Scan` --WITH (INDEX(IX_ScanDate))
  WHERE ScanDate > DATE_ADD(CURRENT_DATETIME(), INTERVAL -1 YEAR)