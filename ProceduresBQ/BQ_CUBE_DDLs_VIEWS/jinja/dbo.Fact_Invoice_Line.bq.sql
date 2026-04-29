CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Fact_Invoice_Line`
AS
SELECT h.Country, h.InvoiceNumber, h.FranchiseeCode, h.CourierNumber, s.CustomerKey, s.ProductCode, s.InvoiceDateInvLine, s.Qty, s.Price, s.Qty * s.Price AS TotalPrice, s.GSTAmount, s.PriceDiscounted, s.LineType,
             (SELECT MIN(LEFT(lab.LabelNo, 2))
              FROM `{{ project_id }}.{{ dataset_id }}.dv_LNK_Invoice_Label` AS lab
              WHERE lab.Invoice_HSK = l.Invoice_HSK AND s.ProductCode IN (LEFT(lab.LabelNo, 2), LEFT(lab.LabelNo, 1))) AS Prefix
FROM   `{{ project_id }}.{{ dataset_id }}.dv_HUB_Invoice` AS h INNER JOIN
             `{{ project_id }}.{{ dataset_id }}.dv_LNK_InvoiceLine` AS l ON h.InvoiceNumber = l.InvoiceNumber AND h.FranchiseeCode = l.FranchiseeCode INNER JOIN
             `{{ project_id }}.{{ dataset_id }}.dv_LSAT_InvoiceLine` AS s ON l.InvoiceLine_HSK = s.InvoiceLine_HSK