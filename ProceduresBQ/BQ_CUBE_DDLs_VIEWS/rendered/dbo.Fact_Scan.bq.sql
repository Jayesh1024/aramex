CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Scan`
AS
SELECT 
      LabelNo,
	  ScanDate as ScanDateTime, CAST(ScanDate AS DATE) as ScanDate,
	  ScanType,ScanStatus,
	  FranchiseeCode,CourierNumber,CountryName,
	  Latitude,Longitude
FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Scan` 
--where ScanDate between '2019-05-22' and '2019-05-25'