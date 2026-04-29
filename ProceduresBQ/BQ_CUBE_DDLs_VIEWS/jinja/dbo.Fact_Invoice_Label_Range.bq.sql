CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Fact_Invoice_Label_Range`
AS
SELECT        InvoiceNumber, FranchiseeCode, CustomerKey, ProductCode, Qty, Price, UnitPrice, Prefix, LabelsPerBook, InvoiceDateInvLine, LabelNo AS LabelFrom, CONCAT(LEFT(LabelNo, 2),
                         LPAD(CAST(CAST(RIGHT(LabelNo, 10) AS INT64) + LabelsPerBook - 1 AS STRING), 10, '0')) AS LabelTo
FROM            (SELECT        l.InvoiceNumber, l.FranchiseeCode, i.CustomerKey, s.ProductCode, s.Qty, s.Price, s.Price / COALESCE (p.LabelsPerBook, 1) AS UnitPrice, LEFT(l.LabelNo, 2) AS Prefix, p.LabelsPerBook, l.LabelNo,
                                                    s.InvoiceDateInvLine
                          FROM            `{{ project_id }}.{{ dataset_id }}.dv_LNK_Invoice_Label` AS l LEFT OUTER JOIN
                                                    `{{ project_id }}.{{ dataset_id }}.dv_LNK_InvoiceLine` AS i ON i.InvoiceNumber = l.InvoiceNumber AND i.FranchiseeCode = l.FranchiseeCode AND i.ProductCode = LEFT(l.LabelNo, LENGTH(i.ProductCode)) LEFT OUTER JOIN
                                                    `{{ project_id }}.{{ dataset_id }}.dv_LSAT_InvoiceLine` AS s ON i.InvoiceNumber = s.InvoiceNumber AND i.FranchiseeCode = s.FranchiseeCode AND s.ProductCode = i.ProductCode LEFT OUTER JOIN
                                                    `{{ project_id }}.{{ dataset_id }}.dbo_Dim_Product` AS p ON p.ProductCode = i.ProductCode AND p.Country = i.Country) AS inv
WHERE        NOT REGEXP_CONTAINS(RIGHT(LabelNo, 10), r'[^0-9]')