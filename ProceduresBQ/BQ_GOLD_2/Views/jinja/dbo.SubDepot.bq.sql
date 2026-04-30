CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_SubDepot`
AS
SELECT DISTINCT CountryCode, DeedRF, SubDepotCode, LPAD(TRIM(value), 3, '0') AS CF
FROM `{{ project_id }}.{{ dataset_id }}.dbo_TSS_PostCodeMaster`
CROSS JOIN UNNEST(SPLIT(CFDeliveryString, '-')) AS value
WHERE DeedRF != '' AND SubDepotCode != '' AND value != ''