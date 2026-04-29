CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Aging_Exclusions2`
AS

SELECT     FirstScanDate,
 s.LabelNo,
 s.ServiceType,
 s.SLA,
 s.LastScanDate,
 s.LastScanRF,
 s.LastScanCF,
 s.LastScanType,
 s.LastScanStatus,
 s.PickupDate,
 s.PickupRF,
 s.PickupCF,
 s.FirstDepartedDate,
 s.FirstDepartedRF,
 s.LastDepartedDate,
 s.LastDepartedRF,
 
 s.FirstArrivedDate,
 s.FirstArrivedRF,
 s.LastArrivedDate,
 s.LastArrivedRF,
 s.OutDate,
 s.OutRF,
 s.OutCF,
 s.DestRF,
 s.DeliveryTown,
 s.DeliveryPostcode,
 s.OESCustomerID,
 s.FMSCustomerID,
 s.Electronic_CustomerID,
 s.Electronic_CustomerType,
 
 s.CFDeliveryString,
 s.ToBlu,
 m.Days AS KPI,
 m.EconomyDays,
 m.PriorityDays,
 s.CountryCode,
 s.ParcelWeight,
 s.DeliveryAddress,
 s.MFWDueDate,
 s.LabelPrefix1,
 s.LabelPrefix2

FROM     

    (SELECT   FirstScanDate,
         k.LabelNo,
         fk.ServiceType,
         fk.SLA,
         k.LastScanDate,
         k.LastScanRF,
         k.LastScanCF,
         k.LastScanType,
         k.LastScanStatus,
         k.FirstReceivedDate AS PickupDate,
         (CASE WHEN fk.LabelNo IS NOT NULL THEN l.PickupRF ELSE k.FirstReceivedRF END) AS PickupRF,
         (CASE WHEN fk.LabelNo IS NOT NULL THEN l.PickupCF ELSE k.FirstReceivedCF END) AS PickupCF,
         k.FirstDepartedDate,
         k.FirstDepartedRF,

         k.LastDepartedDate,
         k.LastDepartedRF,
         COALESCE (fk.ActualFirstArrivalDate, k.FirstArrivedDate) AS FirstArrivedDate,
         COALESCE (fk.ActualFirstArrivalRF, k.FirstArrivedRF) AS FirstArrivedRF,

         k.LastArrivedDate, 
         k.LastArrivedRF,
         k.LastOutDate as OutDate,
         k.LastOutRF as OutRF,
         k.LastOutCF as OutCF,

         (CASE WHEN fk.LabelNo IS NOT NULL THEN l.DeliveryRF 
               WHEN FastLabel_DestinationRF IS NOT NULL THEN FastLabel_DestinationRF 
               WHEN DeedRF IS NOT NULL THEN DeedRF 
               WHEN k.LastSortedScanStatus IS NOT NULL AND k.LastSortedScanStatus NOT IN ('UNW', 'MIX') THEN k.LastSortedScanStatus 
               WHEN k.LastOutRF IS NOT NULL THEN k.LastOutRF ELSE '' END
         ) AS DestRF, 

         COALESCE (UPPER(LTRIM(l.DeliveryTown)), d.Town) AS DeliveryTown, 
         COALESCE (l.DeliveryPostcode, d.Postcode) AS DeliveryPostcode,

         l.OESCustomerID,
         l.FMSCustomerID,
         l.Electronic_CustomerID,
         l.Electronic_CustomerType,
         (CASE WHEN l.DeliveryCF IS NOT NULL AND LTRIM(l.DeliveryCF) <> '' THEN l.DeliveryCF ELSE p.CFDeliveryString END) AS CFDeliveryString,
         l.CountryCode,
         l.ParcelWeight,
         D.AddressKey AS DeliveryAddress,
         fk.DueDate AS MFWDueDate,

         ( SELECT        COUNT(1) AS Expr1
           FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Scan_By_LabelNo`
           WHERE ScanDate > DATE_ADD(CURRENT_DATETIME(), INTERVAL -3 MONTH) AND LabelNo = k.LabelNo AND ScanStatus IN ('BBD', 'BB1', 'BB2', 'BB3')
         ) AS ToBlu,
         k.LabelPrefix1,
         k.LabelPrefix2
         

 FROM   `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Aging_Indexed` k LEFT OUTER JOIN
        `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label` AS l ON l.CreateDate > DATE_ADD(CURRENT_DATETIME(), INTERVAL -6 MONTH) AND k.LabelNo = l.LabelNo AND k.CountryCode = l.CountryCode LEFT OUTER JOIN
        `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_TSS_PostCodeMaster` AS p ON l.DeliveryPostcode = RTRIM(p.PostCode) AND UPPER(LTRIM(l.DeliveryTown)) = RTRIM(p.Suburb) AND p.CountryCode = l.CountryCode AND 
        p.DeedRF <> '' LEFT OUTER JOIN
        `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Label_Address` AS A2 ON k.LabelNo = a2.LabelNo LEFT OUTER JOIN
		`prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Address` AS d ON d.Address_HSK = A2.Delivery_Address_HSK LEFT OUTER JOIN	 -- Delivery address only
        `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI` AS fk ON k.LabelNo = fk.LabelNo AND fk.Category IN ('Interbranch', 'Local')

 WHERE (k.FirstStopDate IS NULL)
   AND (k.CountryCode = 1) 
   AND (LabelPrefix2 <> '5A')
   
    OR (k.CountryCode = 6)
   AND (LabelPrefix1 <> '9')
   
    OR (k.FirstStopDate IS NULL) 
   AND (k.CountryCode = 24)

) AS s 
LEFT OUTER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIMatrix` AS m ON s.PickupRF = m.PickupFranchise AND s.DestRF = m.DeliveryFranchise
LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_AgingExcludedLabels` AS ael ON s.LabelNo = ael.LabelNo
WHERE  (ael.LabelNo IS NULL) -- This is the exclusion
  AND  FMSCustomerID NOT IN (106215)