CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Fact_Invoice_Label`
AS
SELECT        lab.LabelNo, lab.InvoiceNumber, lab.FranchiseeCode, i.Country, i.CourierNumber, i.CustomerKey, i.ProductCode, s.InvoiceDateInvLine, s.Price AS LinePrice, 
                         s.Price / (CASE WHEN p.LabelsPerBook > 0 THEN p.LabelsPerBook ELSE 1 END) AS LabelPrice, s.Qty, s.SaleType, s.PriceDiscounted, s.LineType, s.PayCommission, s.Commission, s.GSTAmount
FROM            `{{ project_id }}.{{ dataset_id }}.dv_LNK_Invoice_Label` AS lab LEFT OUTER JOIN
                         `{{ project_id }}.{{ dataset_id }}.dv_LNK_InvoiceLine` AS i ON i.Invoice_HSK = lab.Invoice_HSK AND i.FranchiseeCode_HSK = lab.FranchiseeCode_HSK AND i.ProductCode IN (LEFT(lab.LabelNo, 2), LEFT(lab.LabelNo, 1)) LEFT OUTER JOIN
                         `{{ project_id }}.{{ dataset_id }}.dv_LSAT_InvoiceLine` AS s ON i.InvoiceLine_HSK = s.InvoiceLine_HSK LEFT OUTER JOIN
                         `{{ project_id }}.{{ dataset_id }}.dbo_Dim_Product` AS p ON p.ProductCode = i.ProductCode AND p.Country = i.Country