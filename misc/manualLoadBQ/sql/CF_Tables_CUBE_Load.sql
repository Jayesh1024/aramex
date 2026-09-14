TRUNCATE TABLE prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_CF;
TRUNCATE TABLE prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_CF;

-- Transfer Data to HUB_CF --
INSERT INTO prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_CF (
  Courier_HSK,
  RFCode,
  CourierNumber,
  Loaded,
  ProcessId,
  RecordSource
) 
SELECT
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(
    CONCAT(TRIM(COALESCE(RFCode, '')), '^', TRIM(COALESCE(CourierNumber, ''))), 
    '^'
  ) AS Courier_HSK,
  TRIM(COALESCE(RFCode, '')) AS RFCode,
  TRIM(COALESCE(CourierNumber, '')) AS CourierNumber,
  CAST(Loaded AS DATETIME) AS Loaded,
  ProcessId,
  TRIM(COALESCE(RecordSource, '')) AS RecordSource
FROM
  `prj-drgfly-prod-sp-01.validation_results.dv_HUB_CF_sqlserver`;


-- Transfer Data to SAT_CF --
INSERT INTO prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_CF (
  Courier_HSK,
  RFCode,
  CourierNumber,
  Name,
  ShortName,
  CFName,
  Address,
  EmailAddress,
  PhoneNumber,
  MobileNumber,
  BlackbayRouteId,
  CourierGroup,
  CFOwnershipModel,
  Loaded,
  ProcessId,
  RecordSource,
  ValidFrom,
  ValidTo,
  IsCurrent,
  Inactive,
  ParcelConnectCFTerritory
)
SELECT
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(
    CONCAT(TRIM(COALESCE(RFCode, '')), '^', TRIM(COALESCE(CourierNumber, ''))),
    '^'
  ) AS Courier_HSK,
  TRIM(COALESCE(RFCode, '')) AS RFCode,
  TRIM(COALESCE(CourierNumber, '')) AS CourierNumber,
  TRIM(COALESCE(Name, '')) AS Name,
  TRIM(COALESCE(ShortName, '')) AS ShortName,
  TRIM(COALESCE(CFName, '')) AS CFName,
  TRIM(COALESCE(Address, '')) AS Address,
  TRIM(COALESCE(EmailAddress, '')) AS EmailAddress,
  TRIM(COALESCE(PhoneNumber, '')) AS PhoneNumber,
  TRIM(COALESCE(MobileNumber, '')) AS MobileNumber,
  SAFE_CAST(BlackbayRouteId AS INT64) AS BlackbayRouteId,
  TRIM(COALESCE(CourierGroup, '')) AS CourierGroup,
  TRIM(COALESCE(CFOwnershipModel, '')) AS CFOwnershipModel,
  DATETIME(Loaded) AS Loaded,
  ProcessId,
  TRIM(COALESCE(RecordSource, '')) AS RecordSource,
  DATETIME(ValidFrom) AS ValidFrom,
  DATETIME(ValidTo) AS ValidTo,
  CAST(IsCurrent AS INT64),
  SAFE_CAST(Inactive AS INT64) AS Inactive,
  TRIM(COALESCE(ParcelConnectCFTerritory, '')) AS ParcelConnectCFTerritory
FROM
  `prj-drgfly-prod-sp-01.validation_results.dv_SAT_CF_sqlserver`;