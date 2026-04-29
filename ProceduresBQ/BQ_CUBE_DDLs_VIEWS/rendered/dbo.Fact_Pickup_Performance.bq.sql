CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Pickup_Performance`
AS
SELECT        COALESCE (k.FirstReceivedRF, l.Distribution_FranchiseeCode) AS ReceivedRF, k.FirstReceivedCF AS ReceivedCF, r.CountryCode, CAST(COALESCE (k.FirstReceivedDate, k.FirstScanDate) AS DATE) AS PickupDate, 
                         (CASE WHEN k.FirstReceivedDate IS NULL THEN 'FirstScan' ELSE 'PickupScan' END) AS PickupType, (CASE WHEN FirstReceivedRF IS NULL THEN 'Invalid' WHEN c.OESCustomerID IS NOT NULL OR
                         lc.FMSCustomerId IS NOT NULL THEN 'Bulk' WHEN FirstReceivedRF = FirstStopRF THEN 'Local' ELSE 'Interbranch' END) AS CustomerType, COUNT(1) AS NumofPickups, SUM(CASE WHEN FirstStopDate IS NULL 
                         THEN 1 ELSE 0 END) AS NumofUndelivered, SUM(l.ParcelWeight) AS ParcelWeight
FROM            `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Scan_KPI` AS k LEFT OUTER JOIN
                         `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label` AS l ON k.LabelNo = l.LabelNo INNER JOIN
                         `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_RF` AS r ON COALESCE (k.FirstReceivedRF, l.Distribution_FranchiseeCode) = r.FranchiseeCode LEFT OUTER JOIN
                         `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIBulkCustomer` AS c ON l.OESCustomerID = c.OESCustomerID AND l.CountryCode = c.CountryCode LEFT OUTER JOIN
                         `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIBulkLocalCustomer` AS lc ON l.FMSCustomerID = lc.FMSCustomerId AND l.CountryCode = lc.CountryCode
WHERE        (k.LastScanStatus NOT IN ('PP2', 'PP3', 'PP4', 'PP5', 'PP6', 'PP7', 'NOC', 'NAA', 'NOH', 'PIO'))
GROUP BY COALESCE (k.FirstReceivedRF, l.Distribution_FranchiseeCode), k.FirstReceivedCF, r.CountryCode, CAST(COALESCE (k.FirstReceivedDate, k.FirstScanDate) AS DATE), (CASE WHEN k.FirstReceivedDate IS NULL 
                         THEN 'FirstScan' ELSE 'PickupScan' END), (CASE WHEN FirstReceivedRF IS NULL THEN 'Invalid' WHEN c.OESCustomerID IS NOT NULL OR
                         lc.FMSCustomerId IS NOT NULL THEN 'Bulk' WHEN FirstReceivedRF = FirstStopRF THEN 'Local' ELSE 'Interbranch' END)