CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Invoice_Line`
AS
SELECT h.Country, h.InvoiceNumber, h.FranchiseeCode, h.CourierNumber, s.CustomerKey, s.ProductCode, s.InvoiceDateInvLine, s.Qty, s.Price, s.Qty * s.Price AS TotalPrice, s.GSTAmount, s.PriceDiscounted, s.LineType,
             (SELECT MIN(LEFT(lab.LabelNo, 2))
              FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Invoice_Label` AS lab
              WHERE lab.Invoice_HSK = l.Invoice_HSK AND s.ProductCode IN (LEFT(lab.LabelNo, 2), LEFT(lab.LabelNo, 1))) AS Prefix
FROM   `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_Invoice` AS h INNER JOIN
             `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_InvoiceLine` AS l ON h.InvoiceNumber = l.InvoiceNumber AND h.FranchiseeCode = l.FranchiseeCode INNER JOIN
             `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_InvoiceLine` AS s ON l.InvoiceLine_HSK = s.InvoiceLine_HSK