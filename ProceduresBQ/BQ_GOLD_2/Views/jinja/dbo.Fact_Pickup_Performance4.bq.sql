CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Fact_Pickup_Performance4`
AS

SELECT
    COALESCE (k.FirstReceivedRF, l.Distribution_FranchiseeCode) AS ReceivedRF,
    k.FirstReceivedCF AS ReceivedCF,
    r.CountryCode,
    CAST(COALESCE (k.FirstReceivedDate, k.FirstScanDate) AS DATE) AS PickupDate,
    (CASE WHEN k.FirstReceivedDate IS NULL 
                 THEN 'FirstScan' ELSE 'PickupScan' END) AS PickupType, (CASE WHEN FirstReceivedRF IS NULL THEN 'Invalid' WHEN c.OESCustomerID IS NOT NULL OR
                 lc.FMSCustomerId IS NOT NULL THEN 'Bulk' WHEN FirstReceivedRF = FirstStopRF THEN 'Local' ELSE 'Interbranch' END) AS CustomerType, 
   coalesce (k.FirstStopRF,l.DeliveryRF) AS DeliveryRF,
    k.FirstStopCF AS DeliveryCF,                 
    COUNT(1) AS NumofPickups,
    SUM(CASE WHEN FirstStopDate IS NULL THEN 1 ELSE 0 END) AS NumofUndelivered,
    SUM(l.ParcelWeight) AS ParcelWeight
    
FROM   `{{ project_id }}.{{ dataset_id }}.dbo_Fact_Scan_KPI_partitioned` AS k
LEFT OUTER JOIN `{{ project_id }}.{{ dataset_id }}.dbo_Dim_Label_partitioned` AS l ON k.LabelNo = l.LabelNo
INNER JOIN `{{ project_id }}.{{ dataset_id }}.dbo_Dim_RF` AS r ON COALESCE (k.FirstReceivedRF, l.Distribution_FranchiseeCode) = r.FranchiseeCode
LEFT OUTER JOIN `{{ project_id }}.{{ dataset_id }}.dbo_KPIBulkCustomer` AS c ON l.OESCustomerID = c.OESCustomerID AND l.CountryCode = c.CountryCode 
LEFT OUTER JOIN `{{ project_id }}.{{ dataset_id }}.dbo_KPIBulkLocalCustomer` AS lc ON l.FMSCustomerID = lc.FMSCustomerId AND l.CountryCode = lc.CountryCode

WHERE (k.LastScanStatus NOT IN ('PP2', 'PP3', 'PP4', 'PP5', 'PP6', 'PP7', 'NOC', 'NAA', 'NOH', 'PIO'))
AND k.FirstScanDate >= DATE_ADD(CURRENT_DATETIME(), INTERVAL -2 YEAR)
GROUP BY COALESCE (k.FirstReceivedRF, l.Distribution_FranchiseeCode),
k.FirstReceivedCF,
r.CountryCode, 
CAST(COALESCE (k.FirstReceivedDate, k.FirstScanDate) AS DATE),
(CASE WHEN k.FirstReceivedDate IS NULL THEN 'FirstScan' ELSE 'PickupScan' END),
(CASE WHEN FirstReceivedRF IS NULL THEN 'Invalid' WHEN c.OESCustomerID IS NOT NULL OR
           lc.FMSCustomerId IS NOT NULL THEN 'Bulk' WHEN FirstReceivedRF = FirstStopRF THEN 'Local' ELSE 'Interbranch' END),
coalesce (k.FirstStopRF,l.DeliveryRF),
k.FirstStopCF