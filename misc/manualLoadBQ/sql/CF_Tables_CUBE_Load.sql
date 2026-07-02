-- In order for this to work, you need to have the following tables:
-- 1. hub_cf_import_csv - This is the table that contains the data taken directly from SQL SERVER CUBE that you want to load into the HUB_CF table.
-- 2. sat_cf_import - This is the table that contains the data taken directly from SQL SERVER CUBE that you want to load into the SAT_CF table.

TRUNCATE TABLE prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_CF;
TRUNCATE TABLE prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_CF;

-- Transer Data to HUB_CF --
INSERT INTO prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_CF (
  Courier_HSK,
  RFCode,
  CourierNumber,
  Loaded,
  ProcessId,
  RecordSource
) 
SELECT
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(CONCAT(IFNULL(RFCode, ''), '^', IFNULL(CourierNumber, '')), '^') AS Courier_HSK,
  RFCode,
  COALESCE(CourierNumber,''),
  CAST(Loaded as DATETIME),
  ProcessId,
  RecordSource
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.hub_cf_import_csv`;

-- Transer Data to SAT_CF --

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
-- use coalesce like how I used in some column that I am trying to insert for all the columns that have type STRING
SELECT
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`( CONCAT(IFNULL(RFCode, ''), '^', IFNULL(CourierNumber, '')),
    '^') AS Courier_HSK,
  COALESCE(RFCode, ''),
  COALESCE(CourierNumber, ''),
  COALESCE(Name, ''),
  COALESCE(ShortName, ''),
  COALESCE(CFName, ''),
  COALESCE(Address, ''),
  COALESCE(EmailAddress, ''),
  COALESCE(PhoneNumber, ''),
  COALESCE(MobileNumber, ''),
  SAFE_CAST(BlackbayRouteId AS INT64),
  COALESCE(CourierGroup, ''),
  COALESCE(CFOwnershipModel, ''),
  DATETIME(Loaded),
  ProcessId,
  COALESCE(RecordSource, ''),
  DATETIME(ValidFrom),
  DATETIME(ValidTo),
  IsCurrent,
  SAFE_CAST(Inactive AS INT64),
  COALESCE(ParcelConnectCFTerritory, '')
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.sat_cf_import`;