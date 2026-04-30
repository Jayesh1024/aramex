CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Fact_Scan`
AS
SELECT 
      LabelNo,
	  ScanDate as ScanDateTime, CAST(ScanDate AS DATE) as ScanDate,
	  ScanType,ScanStatus,
	  FranchiseeCode,CourierNumber,CountryName,
	  Latitude,Longitude
FROM `{{ project_id }}.{{ dataset_id }}.dv_LNK_Scan` 
--where ScanDate between '2019-05-22' and '2019-05-25'