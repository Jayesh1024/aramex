CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Invoice_Label_Range`
AS
SELECT        InvoiceNumber, FranchiseeCode, CustomerKey, ProductCode, Qty, Price, UnitPrice, Prefix, LabelsPerBook, InvoiceDateInvLine, LabelNo AS LabelFrom, CONCAT(LEFT(LabelNo, 2),
                         LPAD(CAST(CAST(RIGHT(LabelNo, 10) AS INT64) + LabelsPerBook - 1 AS STRING), 10, '0')) AS LabelTo
FROM            (SELECT        l.InvoiceNumber, l.FranchiseeCode, i.CustomerKey, s.ProductCode, s.Qty, s.Price, s.Price / COALESCE (p.LabelsPerBook, 1) AS UnitPrice, LEFT(l.LabelNo, 2) AS Prefix, p.LabelsPerBook, l.LabelNo,
                                                    s.InvoiceDateInvLine
                          FROM            `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Invoice_Label` AS l LEFT OUTER JOIN
                                                    `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_InvoiceLine` AS i ON i.InvoiceNumber = l.InvoiceNumber AND i.FranchiseeCode = l.FranchiseeCode AND i.ProductCode = LEFT(l.LabelNo, LENGTH(i.ProductCode)) LEFT OUTER JOIN
                                                    `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_InvoiceLine_partitioned` AS s ON i.InvoiceNumber = s.InvoiceNumber AND i.FranchiseeCode = s.FranchiseeCode AND s.ProductCode = i.ProductCode LEFT OUTER JOIN
                                                    `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Product` AS p ON p.ProductCode = i.ProductCode AND p.Country = i.Country) AS inv
WHERE        NOT REGEXP_CONTAINS(RIGHT(LabelNo, 10), r'[^0-9]')