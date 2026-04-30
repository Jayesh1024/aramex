CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Fact_Scan_Recent`
AS
SELECT 
      LabelNo, 
      ScanDate as ScanDateTime, CAST(ScanDate AS DATE) as ScanDate,
      ScanType,ScanStatus,
      FranchiseeCode,CourierNumber,CountryName, RecordSourceId,
      Latitude,Longitude
FROM `{{ project_id }}.{{ dataset_id }}.dv_LNK_Scan` 
WHERE  ScanDate >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 MONTH)