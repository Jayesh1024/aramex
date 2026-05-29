CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Pickup_Performance5_WithPrice`
AS


SELECT
    COALESCE (k.FirstReceivedRF, l.Distribution_FranchiseeCode) AS ReceivedRF,  
    r.CountryCode,
    CAST(COALESCE (k.FirstReceivedDate, k.FirstScanDate) AS DATE) AS PickupDate,	 
   coalesce (k.FirstStopRF,l.DeliveryRF) AS DeliveryRF,             
    COUNT(1) AS NumofPickups,
    SUM(CASE WHEN FirstStopDate IS NULL THEN 1 ELSE 0 END) AS NumofUndelivered,
    SUM(IF(l.Price > 900, 0, l.Price) + IFNULL(mf.ServicePrice, 0) + IF(mf.LineNo = 1, IFNULL(sc.Price,0), 0) ) as Price
    
FROM   `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Scan_KPI_partitioned` AS k
LEFT OUTER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label_partitioned` AS l ON k.LabelNo = l.LabelNo
INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_RF` AS r ON COALESCE (k.FirstReceivedRF, l.Distribution_FranchiseeCode) = r.FranchiseeCode
LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF_partitioned` mf ON mf.LabelNo =l.LabelNo AND mf.IsCurrent = 1
LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_ServiceCon` sc ON sc.ConId = mf.ConId 

WHERE (k.LastScanStatus NOT IN ('PP2', 'PP3', 'PP4', 'PP5', 'PP6', 'PP7', 'NOC', 'NAA', 'NOH', 'PIO'))
AND k.FirstScanDate >= DATE_ADD(CURRENT_DATETIME(), INTERVAL -2 YEAR)
GROUP BY COALESCE (k.FirstReceivedRF, l.Distribution_FranchiseeCode),
r.CountryCode, 
CAST(COALESCE (k.FirstReceivedDate, k.FirstScanDate) AS DATE),
coalesce (k.FirstStopRF,l.DeliveryRF)