CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Scan_Recent`
AS
SELECT 
      LabelNo, 
      ScanDate as ScanDateTime, CAST(ScanDate AS DATE) as ScanDate,
      ScanType,ScanStatus,
      FranchiseeCode,CourierNumber,CountryName, RecordSourceId,
      Latitude,Longitude,TrackAndTraceID
FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Scan` 
WHERE  ScanDate >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 MONTH)