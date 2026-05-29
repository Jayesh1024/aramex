CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Dim_Label_partitioneds_With_SignatureService`
	AS 
	
SELECT LabelNo, 1 AS IsSignatureService
FROM `{{ project_id }}.{{ dataset_id }}.dv_HUB_Signature_Labels`