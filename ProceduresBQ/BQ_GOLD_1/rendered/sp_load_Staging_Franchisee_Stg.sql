CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.sp_load_Staging_Franchisee_Stg`(
)
BEGIN
  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_Franchisee_Stg`
  SELECT
      FranchiseeCode, f.CountryCode, c.Country, f.RFId, 
      f.Name, f.Email, f.LegalTradingEntity, f.ABN, f.ACN, f.TaxNumber,
      f.Add1, f.Add2, f.Add3, f.Add4, f.Phone, f.Fax,
      f.FranchiseEnquiryEmail, f.State, f.Suburb, f.PostCode, 
      f.Phone2, f.AccountsEmail, f.FMSType,
      CAST(CompanyOwnedRF AS INT64) AS CompanyOwnedRF,
      CAST(UsingWebFMSBanking AS INT64) AS UsingWebFMSBanking
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_Franchisee` f 
  LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_Country` c ON c.Code = f.CountryCode
  ;

END;