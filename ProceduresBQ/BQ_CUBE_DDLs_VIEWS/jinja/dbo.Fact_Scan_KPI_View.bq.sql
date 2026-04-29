CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Fact_Scan_KPI_View`
AS
SELECT        k.LabelNo, k.FirstScanDate, k.FirstScanRF, k.FirstScanCF, k.FirstScanType, k.FirstScanStatus, k.LastScanDate, k.LastScanRF, k.LastScanCF, k.LastScanType, k.LastScanStatus, k.FirstPscanDate, k.FirstPscanRF, k.FirstPscanCF, 
                         k.FirstPscanStatus, k.FirstDscanDate, k.FirstDscanRF, k.FirstDscanCF, k.FirstDscanStatus, k.FirstReceivedDate, k.FirstReceivedRF, k.FirstReceivedCF, k.FirstReceivedScanType, k.FirstReceivedScanStatus, k.LastReceivedDate,
                          k.LastReceivedRF, k.LastReceivedCF, k.LastReceivedScanType, k.LastReceivedScanStatus, k.FirstSortedDate, k.FirstSortedRF, k.FirstSortedCF, k.FirstSortedScanType, k.FirstSortedScanStatus, k.LastSortedDate, 
                         k.LastSortedRF, k.LastSortedCF, k.LastSortedScanType, k.LastSortedScanStatus, k.FirstDepartedDate, k.FirstDepartedRF, k.FirstDepartedCF, k.FirstDepartedScanType, k.FirstDepartedScanStatus, k.LastDepartedDate, 
                         k.LastDepartedRF, k.LastDepartedCF, k.LastDepartedScanType, k.LastDepartedScanStatus, k.FirstArrivedDate, k.FirstArrivedRF, k.FirstArrivedCF, k.FirstArrivedScanType, k.FirstArrivedScanStatus, k.LastArrivedDate, 
                         k.LastArrivedRF, k.LastArrivedCF, k.LastArrivedScanType, k.LastArrivedScanStatus, k.FirstOutDate, k.FirstOutRF, k.FirstOutCF, k.FirstOutScanType, k.FirstOutScanStatus, k.LastOutDate, k.LastOutRF, k.LastOutCF, 
                         k.LastOutScanType, k.LastOutScanStatus, k.FirstStopDate, k.FirstStopRF, k.FirstStopCF, k.FirstStopScanType, k.FirstStopScanStatus, k.LastStopDate, k.LastStopRF, k.LastStopCF, k.LastStopScanType, k.LastStopScanStatus, 
                         k.FirstDeliveryDate, k.FirstDeliveryRF, k.FirstDeliveryCF, k.FirstDeliveryScanType, k.FirstDeliveryScanStatus, k.LastDeliveryDate, k.LastDeliveryRF, k.LastDeliveryCF, k.LastDeliveryScanType, k.LastDeliveryScanStatus, 
                         k.StopDays, k.StopHoliday, k.KPI, k.SingleCycle, k.SubDepot, k.DeliveryDays, k.DeliveryHoliday, k.SLA, p.Town AS PickupTown, p.Postcode AS PickupPostcode, d.Town AS DeliveryTown, d.Postcode AS DeliveryPostcode
FROM            `{{ project_id }}.{{ dataset_id }}.dbo_Fact_Scan_KPI` AS k LEFT OUTER JOIN
                         `{{ project_id }}.{{ dataset_id }}.dv_LNK_Label_Address` AS a ON k.LabelNo = a.LabelNo LEFT OUTER JOIN
                         `{{ project_id }}.{{ dataset_id }}.dv_SAT_Address` AS p ON a.Pickup_Address_HSK = p.Address_HSK AND p.IsCurrent = 1 LEFT OUTER JOIN
                         `{{ project_id }}.{{ dataset_id }}.dv_SAT_Address` AS d ON a.Delivery_Address_HSK = d.Address_HSK AND d.IsCurrent = 1