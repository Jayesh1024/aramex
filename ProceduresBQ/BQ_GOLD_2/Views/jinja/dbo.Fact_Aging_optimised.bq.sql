CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Fact_Aging_optimised`  
AS
SELECT        
	s.LabelNo, s.ServiceType, s.SLA, s.LastScanDate, s.LastScanRF, s.LastScanCF, s.LastScanType, s.LastScanStatus, s.PickupDate, s.PickupRF, s.PickupCF, s.FirstDepartedDate, s.FirstDepartedRF, s.LastDepartedDate, s.LastDepartedRF, 
    s.FirstArrivedDate, s.FirstArrivedRF, s.LastArrivedDate, s.LastArrivedRF, s.OutDate, s.OutRF, s.OutCF, s.DestRF, s.DeliveryTown, s.DeliveryPostcode, s.OESCustomerID, s.FMSCustomerID, s.Electronic_CustomerID, 
    s.Electronic_CustomerType, s.CFDeliveryString, s.ToBlu, m.Days AS KPI, m.EconomyDays, m.PriorityDays, s.CountryCode, s.ParcelWeight, s.DeliveryAddress, s.MFWDueDate
FROM 
(
	SELECT        
		k.LabelNo, fk.ServiceType, fk.SLA, k.LastScanDate, k.LastScanRF, k.LastScanCF, k.LastScanType, k.LastScanStatus, k.FirstReceivedDate AS PickupDate, 
		(CASE WHEN fk.LabelNo IS NOT NULL THEN l.PickupRF ELSE k.FirstReceivedRF END) AS PickupRF, 
		(CASE WHEN fk.LabelNo IS NOT NULL THEN l.PickupCF ELSE k.FirstReceivedCF END) AS PickupCF, k.FirstDepartedDate, k.FirstDepartedRF, 
        k.LastDepartedDate, k.LastDepartedRF, COALESCE (fk.ActualFirstArrivalDate, k.FirstArrivedDate) AS FirstArrivedDate, COALESCE (fk.ActualFirstArrivalRF, k.FirstArrivedRF) AS FirstArrivedRF, k.LastArrivedDate, 
        k.LastArrivedRF, k.LastOutDate AS OutDate, k.LastOutRF AS OutRF, k.LastOutCF AS OutCF, 
		(CASE WHEN fk.LabelNo IS NOT NULL THEN l.DeliveryRF 
			WHEN FastLabel_DestinationRF IS NOT NULL THEN FastLabel_DestinationRF 
			WHEN DeedRF IS NOT NULL THEN DeedRF 
			WHEN k.LastSortedScanStatus IS NOT NULL AND k.LastSortedScanStatus NOT IN ('UNW', 'MIX') THEN k.LastSortedScanStatus 
			WHEN k.LastOutRF IS NOT NULL THEN k.LastOutRF ELSE '' END) AS DestRF, 
		COALESCE (UPPER(LTRIM(l.DeliveryTown)), a.DelTown) AS DeliveryTown, 
        COALESCE (l.DeliveryPostcode, a.DelPostcode) AS DeliveryPostcode, l.OESCustomerID, l.FMSCustomerID, l.Electronic_CustomerID, l.Electronic_CustomerType, 
		(CASE WHEN l.DeliveryCF IS NOT NULL AND LTRIM(l.DeliveryCF) <> '' THEN l.DeliveryCF ELSE p.CFDeliveryString END) AS CFDeliveryString, 
		l.CountryCode, l.ParcelWeight, a.DeliveryAddress, fk.DueDate AS MFWDueDate,
		(SELECT COUNT(1) FROM `{{ project_id }}.{{ dataset_id }}.dbo_Fact_Scan`
            WHERE LabelNo = k.LabelNo AND ScanStatus IN ('BBD', 'BB1', 'BB2', 'BB3') AND ScanDateTime >= DATE_ADD(CURRENT_DATETIME(), INTERVAL -6 MONTH)
		) AS ToBlu
	FROM `{{ project_id }}.{{ dataset_id }}.dbo_Fact_Scan_KPI` AS k 
		INNER JOIN `{{ project_id }}.{{ dataset_id }}.dbo_Dim_RF` AS r ON k.FirstReceivedRF = r.FranchiseeCode 
		LEFT OUTER JOIN `{{ project_id }}.{{ dataset_id }}.dbo_Dim_Label` AS l ON k.LabelNo = l.LabelNo AND r.CountryCode = l.CountryCode 
		LEFT OUTER JOIN `{{ project_id }}.{{ dataset_id }}.dbo_TSS_PostCodeMaster` AS p ON l.DeliveryPostcode = RTRIM(p.PostCode) AND UPPER(LTRIM(l.DeliveryTown)) = RTRIM(p.Suburb) AND p.CountryCode = l.CountryCode AND p.DeedRF <> '' 
		LEFT OUTER JOIN `{{ project_id }}.{{ dataset_id }}.dbo_Dim_Label_Address` AS a ON k.LabelNo = a.LabelNo 
		LEFT OUTER JOIN `{{ project_id }}.{{ dataset_id }}.dbo_Fact_KPI` AS fk ON k.LabelNo = fk.LabelNo AND fk.Category IN ('Interbranch', 'Local')
	WHERE 
		k.FirstScanDate >= DATE_ADD(CURRENT_DATETIME(), INTERVAL -6 MONTH) AND 
		k.FirstStopDate IS NULL AND
		( CASE 
			WHEN ( r.CountryCode = 1  AND LEFT(k.LabelNo, 2) <> '5A' AND k.FirstScanDate >= DATE_ADD(CURRENT_DATETIME(), INTERVAL -3 MONTH) ) THEN 1
			WHEN ( r.CountryCode = 6  AND LEFT(k.LabelNo, 1) <> '9' ) THEN 1 
			WHEN ( r.CountryCode = 24 ) THEN 1 
			ELSE 0 
		END ) = 1
) 
AS s 
LEFT OUTER JOIN `{{ project_id }}.{{ dataset_id }}.dbo_KPIMatrix` AS m ON s.PickupRF = m.PickupFranchise AND s.DestRF = m.DeliveryFranchise