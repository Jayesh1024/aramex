CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Fact_Pickup_Performance2`
AS
SELECT        COALESCE (k.FirstReceivedRF, l.Distribution_FranchiseeCode) AS ReceivedRF, k.FirstReceivedCF AS ReceivedCF, k.FirstStopRF AS DeliveryRF, k.FirstStopCF AS DeliveryCF, r.CountryCode, CAST(COALESCE (k.FirstReceivedDate, k.FirstScanDate) AS DATE) AS PickupDate, COUNT(1) AS NumofPickups
FROM            `{{ project_id }}.{{ dataset_id }}.dbo_Fact_Scan_KPI` AS k LEFT OUTER JOIN
                         `{{ project_id }}.{{ dataset_id }}.dbo_Dim_Label` AS l ON k.LabelNo = l.LabelNo INNER JOIN
                         `{{ project_id }}.{{ dataset_id }}.dbo_Dim_RF` AS r ON COALESCE (k.FirstReceivedRF, l.Distribution_FranchiseeCode) = r.FranchiseeCode
WHERE        (k.LastScanStatus NOT IN ('PP2', 'PP3', 'PP4', 'PP5', 'PP6', 'PP7', 'NOC', 'NAA', 'NOH', 'PIO'))
GROUP BY COALESCE (k.FirstReceivedRF, l.Distribution_FranchiseeCode), k.FirstReceivedCF, k.FirstStopRF, k.FirstStopCF, r.CountryCode, CAST(COALESCE (k.FirstReceivedDate, k.FirstScanDate) AS DATE)