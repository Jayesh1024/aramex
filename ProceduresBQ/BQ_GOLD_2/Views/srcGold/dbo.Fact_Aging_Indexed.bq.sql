CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Aging_Indexed`
AS
  SELECT
  k.FirstScanDate,
  k.LabelNo,
  k.LastScanDate,
  k.LastScanRF,
  k.LastScanCF,
  k.LastScanType,
  k.LastScanStatus,
  k.FirstReceivedDate,
  k.FirstReceivedRF,
  k.FirstReceivedCF,
  k.FirstDepartedDate,
  k.FirstDepartedRF,
  k.LastDepartedDate,
  k.LastDepartedRF,
  k.FirstArrivedDate,
  k.FirstArrivedRF,
  k.LastArrivedDate,
  k.LastArrivedRF,
  k.LastOutDate,
  k.LastOutRF,
  k.LastOutCF,
  k.LastSortedScanStatus,
  k.FirstStopDate,
  r.CountryCode,
  r.FranchiseeCode,
  LEFT(k.LabelNo, 1) AS LabelPrefix1,
  LEFT(k.LabelNo, 2) AS LabelPrefix2
FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Scan_KPI` AS k
INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_IndexedViewDateRangeLimit` AS fc
  ON k.FirstScanDate >= fc.DateLimit2
  AND k.FirstReceivedDate >= fc.DateLimit2
  AND fc.TargetName = 'Fact_Aging_Indexed'
INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_RF` AS r
  ON k.FirstReceivedRF = r.FranchiseeCode
  AND r.IsCurrent = 1
WHERE
  (k.FirstStopDate IS NULL)