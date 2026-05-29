CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Fact_Pickup_Performance5_WithPrice_LabelLevel`
AS


SELECT
    l.LabelNo,	
    COALESCE (k.FirstReceivedRF, l.Distribution_FranchiseeCode) AS ReceivedRF,  
    r.CountryCode,
    CAST(COALESCE (k.FirstReceivedDate, k.FirstScanDate) AS DATE) AS PickupDate,	 
   coalesce (k.FirstStopRF,l.DeliveryRF) AS DeliveryRF, 
    IF(l.Price > 900, 0, l.Price) + IFNULL(mf.ServicePrice, 0) + IF(mf.LineNo = 1, IFNULL(sc.Price,0), 0) as Price
    
FROM   `{{ project_id }}.{{ dataset_id }}.dbo_Fact_Scan_KPI_partitioned` AS k
LEFT OUTER JOIN `{{ project_id }}.{{ dataset_id }}.dbo_Dim_Label_partitioned` AS l ON k.LabelNo = l.LabelNo
INNER JOIN `{{ project_id }}.{{ dataset_id }}.dbo_Dim_RF` AS r ON COALESCE (k.FirstReceivedRF, l.Distribution_FranchiseeCode) = r.FranchiseeCode
LEFT JOIN `{{ project_id }}.{{ dataset_id }}.dv_SAT_Label_Allocation_MF_partitioned` mf ON mf.LabelNo =l.LabelNo AND mf.IsCurrent = 1
LEFT JOIN `{{ project_id }}.{{ dataset_id }}.dbo_Fact_ServiceCon` sc ON sc.ConId = mf.ConId 

WHERE (k.LastScanStatus NOT IN ('PP2', 'PP3', 'PP4', 'PP5', 'PP6', 'PP7', 'NOC', 'NAA', 'NOH', 'PIO'))
AND k.FirstScanDate >= DATE_ADD(CURRENT_DATETIME(), INTERVAL -2 YEAR)