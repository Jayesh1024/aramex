CREATE OR REPLACE VIEW `bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Pickup_Performance4` AS
SELECT
  COALESCE(k.FirstReceivedRF, l.Distribution_FranchiseeCode) AS ReceivedRF,
  k.FirstReceivedCF AS ReceivedCF,
  r.CountryCode,
  DATE(COALESCE(k.FirstReceivedDate, k.FirstScanDate)) AS PickupDate,
  CASE
    WHEN k.FirstReceivedDate IS NULL THEN 'FirstScan'
    ELSE 'PickupScan'
  END AS PickupType,
  CASE
    WHEN k.FirstReceivedRF IS NULL THEN 'Invalid'
    WHEN c.OESCustomerID IS NOT NULL OR lc.FMSCustomerId IS NOT NULL THEN 'Bulk'
    WHEN k.FirstReceivedRF = k.FirstStopRF THEN 'Local'
    ELSE 'Interbranch'
  END AS CustomerType,
  COALESCE(k.FirstStopRF, l.DeliveryRF) AS DeliveryRF,
  k.FirstStopCF AS DeliveryCF,
  COUNT(1) AS NumofPickups,
  SUM(CASE WHEN k.FirstStopDate IS NULL THEN 1 ELSE 0 END) AS NumofUndelivered,
  SUM(l.ParcelWeight) AS ParcelWeight
FROM `bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Scan_KPI` AS k
LEFT OUTER JOIN `bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label` AS l
  ON k.LabelNo = l.LabelNo
INNER JOIN `bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_RF` AS r
  ON COALESCE(k.FirstReceivedRF, l.Distribution_FranchiseeCode) = r.FranchiseeCode
LEFT OUTER JOIN `bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIBulkCustomer` AS c
  ON l.OESCustomerID = c.OESCustomerID
 AND l.CountryCode = c.CountryCode
LEFT OUTER JOIN `bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIBulkLocalCustomer` AS lc
  ON l.FMSCustomerID = lc.FMSCustomerId
 AND l.CountryCode = lc.CountryCode
WHERE k.LastScanStatus IS NOT NULL AND
  NOT EXISTS (
      SELECT 1
      FROM `bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_ScanStatus` AS s
      WHERE s.ScanStatus = k.LastScanStatus
        AND s.IsCurrent = 1
        AND s.ExcludeFromMFYBilling = 1
        AND s.CountryName = l.Country
    )
  AND DATE(k.FirstScanDate) >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 3 YEAR), YEAR)
GROUP BY 1, 2, 3, 4, 5, 6, 7, 8;