CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Dim_Invoice` AS 
SELECT  
	InvoiceNumber, Country, FranchiseeCode
FROM `{{ project_id }}.{{ dataset_id }}.dv_HUB_Invoice` inv