CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_vwSubDepot`
AS
SELECT DISTINCT
  CountryCode, DeedRF, SubDepotCode, LPAD(TRIM(cf_value), 3, '0') AS CF
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_TSS_PostCodeMaster`
CROSS JOIN UNNEST(SPLIT(CFDeliveryString, '-')) AS cf_value
WHERE
  (UPPER(SubDepotCode) NOT IN ('', 'HSD', 'KNX', 'SEA'))
  AND (TRIM(CFDeliveryString) != '')
  AND (DeedRF != '')
  AND (cf_value != '')
