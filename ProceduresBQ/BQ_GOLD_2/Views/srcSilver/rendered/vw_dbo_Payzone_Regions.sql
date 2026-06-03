-- LoadGokuTables.dtsx / Payzone_regions
-- SSIS: OnlineEnquiries_NEW.dbo.payzone_regions -> CUBE.FastwayDW dbo.Payzone_Regions
CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.vw_dbo_Payzone_Regions` AS
SELECT
  id,
  franchisee_code,
  region_company_name,
  region_company_phone,
  region_address,
  region_company_email,
  secondary_franchisee_codes,
  CountryId
FROM (
  SELECT
    Src.id,
    Src.franchisee_code,
    Src.region_company_name,
    Src.region_company_phone,
    Src.region_address,
    Src.region_company_email,
    Src.secondary_franchisee_codes,
    Src.CountryId,
    ROW_NUMBER() OVER (PARTITION BY Src.id ORDER BY Src.id) AS dedupe_rn
  FROM
    `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_payzone_regions` AS Src
)
WHERE
  dedupe_rn = 1;