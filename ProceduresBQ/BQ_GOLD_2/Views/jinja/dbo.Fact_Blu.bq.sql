CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Fact_Blu`
AS
SELECT        r.CountryCode, k.FranchiseeCode, k.CourierNumber, k.ScanDate, COUNT(DISTINCT k.LabelNo) AS NumofLabels
FROM            `{{ project_id }}.{{ dataset_id }}.dbo_Fact_Scan` AS k INNER JOIN
                         `{{ project_id }}.{{ dataset_id }}.dbo_Dim_RF` AS r ON k.FranchiseeCode = r.FranchiseeCode
WHERE        (k.ScanStatus IN ('BB1', 'BB2', 'BB3')) AND (r.CountryCode IN (1, 6))
GROUP BY r.CountryCode, k.FranchiseeCode, k.CourierNumber, k.ScanDate