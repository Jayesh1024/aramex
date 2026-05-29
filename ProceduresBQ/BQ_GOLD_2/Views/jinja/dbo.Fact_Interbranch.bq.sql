CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Fact_Interbranch`
AS
SELECT        (CASE WHEN SAFE_CAST(s.CountryCode AS INT64) = 1 THEN 'Australia' ELSE 'New Zealand' END) AS Country, s.CountryCode, s.InvoiceFromRF, s.InvoiceToRF, s.BatchId, s.LabelNo, s.Category, s.InvoiceNumber, s.InvoiceDate, s.DeliveryDate, s.DeliveryTime, s.ProductID, (CASE WHEN m.LabelNo IS NOT NULL 
                         THEN m.DLBSPrice ELSE s.Price END) AS Price
FROM                     `{{ project_id }}.{{ dataset_id }}.dv_LSAT_Label_Interbranch` AS s LEFT OUTER JOIN
                         `{{ project_id }}.{{ dataset_id }}.dv_SAT_Label_Allocation_MF_partitioned` AS m ON s.LabelNo = m.LabelNo AND m.IsCurrent = 1 LEFT OUTER JOIN
                         `{{ project_id }}.{{ dataset_id }}.dbo_KPIExcludedLabels` AS e ON LEFT(s.LabelNo,2) = CAST(e.LabelPrefix AS STRING) AND SAFE_CAST(s.CountryCode AS INT64) = e.CountryCode
WHERE         (e.LabelPrefix IS NULL)