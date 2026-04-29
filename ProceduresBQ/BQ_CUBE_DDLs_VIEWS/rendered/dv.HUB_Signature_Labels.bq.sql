CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_Signature_Labels`
AS


SELECT LabelNo, COUNT(*) as Cntr
FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Product_ServiceItem` AS s
WHERE IsCurrent = 1
AND ProductCode IN ( 'MYFSGR','MYFWSGR', 'MYFWSIGBUS','MYFWSIGRES')
GROUP BY LabelNo