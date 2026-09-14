CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Blu`
AS
SELECT        r.CountryCode, k.FranchiseeCode, k.CourierNumber, k.ScanDate, COUNT(DISTINCT k.LabelNo) AS NumofLabels
FROM            `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Scan` AS k INNER JOIN
                         `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_RF` AS r ON k.FranchiseeCode = r.FranchiseeCode
WHERE        (UPPER(k.ScanStatus) IN ('BB1', 'BB2', 'BB3')) AND (r.CountryCode IN (1, 6))
GROUP BY r.CountryCode, k.FranchiseeCode, k.CourierNumber, k.ScanDate