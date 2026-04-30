CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_vwSubDepot`
AS
SELECT DISTINCT CountryCode, DeedRF, SubDepotCode, LPAD(TRIM(cf_value), 3, '0') AS CF
FROM `{{ project_id }}.{{ dataset_id }}.dbo_TSS_PostCodeMaster`
CROSS JOIN UNNEST(SPLIT(CFDeliveryString, '-')) AS cf_value
WHERE SubDepotCode NOT IN ('', 'HSD', 'KNX', 'SEA') AND TRIM(CFDeliveryString) != '' AND DeedRF != '' AND cf_value != ''