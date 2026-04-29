CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dv_HUB_Signature_Labels`
AS


SELECT LabelNo, COUNT(*) as Cntr
FROM `{{ project_id }}.{{ dataset_id }}.dv_LSAT_Label_Product_ServiceItem` AS s
WHERE IsCurrent = 1
AND ProductCode IN ( 'MYFSGR','MYFWSGR', 'MYFWSIGBUS','MYFWSIGRES')
GROUP BY LabelNo