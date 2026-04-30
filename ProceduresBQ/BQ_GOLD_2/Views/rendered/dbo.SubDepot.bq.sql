CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_SubDepot`
AS
SELECT DISTINCT CountryCode, DeedRF, SubDepotCode, LPAD(TRIM(value), 3, '0') AS CF
FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_TSS_PostCodeMaster`
CROSS JOIN UNNEST(SPLIT(CFDeliveryString, '-')) AS value
WHERE DeedRF != '' AND SubDepotCode != '' AND value != ''