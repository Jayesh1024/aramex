CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Aging_All`
AS
SELECT        s.LabelNo, s.LastScanDate, s.LastScanRF, s.LastScanCF, s.LastScanType, s.LastScanStatus, s.PickupDate, s.PickupRF, s.PickupCF, s.FirstDepartedDate, s.FirstDepartedRF, s.LastDepartedDate, s.LastDepartedRF, 
                         s.FirstArrivedRF, s.LastArrivedRF, s.OutDate, s.OutRF, s.OutCF, s.DestRF, s.DeliveryTown, s.DeliveryPostcode, s.OESCustomerID, s.FMSCustomerID, s.CFDeliveryString, s.ToBlu, m.Days AS KPI, s.CountryCode, 
                         s.ParcelWeight, s.DeliveryAddress
FROM            (SELECT        k.LabelNo, k.LastScanDate, k.LastScanRF, k.LastScanCF, k.LastScanType, k.LastScanStatus, k.FirstReceivedDate AS PickupDate, k.FirstReceivedRF AS PickupRF, k.FirstReceivedCF AS PickupCF, 
                                                    k.FirstDepartedDate, k.FirstDepartedRF, k.LastDepartedDate, k.LastDepartedRF, k.FirstArrivedRF, k.LastArrivedRF, k.FirstOutDate AS OutDate, k.FirstOutRF AS OutRF, k.FirstOutCF AS OutCF, 
                                                    (CASE WHEN FastLabel_DestinationRF IS NOT NULL THEN FastLabel_DestinationRF WHEN DeedRF IS NOT NULL THEN DeedRF WHEN k.LastSortedScanStatus IS NOT NULL AND 
                                                    k.LastSortedScanStatus NOT IN ('UNW', 'MIX') THEN k.LastSortedScanStatus WHEN k.FirstOutRF IS NOT NULL THEN k.FirstOutRF ELSE '' END) AS DestRF, COALESCE (UPPER(LTRIM(l.DeliveryTown)), a.DelTown) 
                                                    AS DeliveryTown, COALESCE (l.DeliveryPostcode, a.DelPostcode) AS DeliveryPostcode, l.OESCustomerID, l.FMSCustomerID, p.CFDeliveryString, l.CountryCode, l.ParcelWeight, a.DeliveryAddress,
                                                        (SELECT        COUNT(1) AS Expr1
                                                          FROM            `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Scan`
                                                          WHERE        (LabelNo = k.LabelNo) AND (ScanStatus IN ('BBD', 'BB1', 'BB2', 'BB3'))) AS ToBlu
                          FROM            `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Scan_KPI_partitioned` AS k INNER JOIN
                                                    `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_RF` AS r ON k.FirstReceivedRF = r.FranchiseeCode LEFT OUTER JOIN
                                                    `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label_partitioned` AS l ON k.LabelNo = l.LabelNo LEFT OUTER JOIN
                                                    `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_TSS_PostCodeMaster` AS p ON l.DeliveryPostcode = RTRIM(p.PostCode) AND UPPER(LTRIM(l.DeliveryTown)) = RTRIM(p.Suburb) AND p.CountryCode IN (1, 6) LEFT OUTER JOIN
                                                    `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label_Address` AS a ON k.LabelNo = a.LabelNo
                          WHERE        (k.FirstStopDate IS NULL) AND (r.CountryCode = 1) AND (LEFT(k.LabelNo, 2) <> '5A') OR
                                                    (k.FirstStopDate IS NULL) AND (r.CountryCode = 6) AND (LEFT(k.LabelNo, 1) <> '9')) AS s LEFT OUTER JOIN
                         `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIMatrix` AS m ON s.PickupRF = m.PickupFranchise AND s.DestRF = m.DeliveryFranchise