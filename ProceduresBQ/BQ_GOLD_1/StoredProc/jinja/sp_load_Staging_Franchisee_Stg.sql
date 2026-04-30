CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_Franchisee_Stg`(
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_Franchisee_Stg`
  SELECT
      FranchiseeCode, f.CountryCode, c.Country, f.RFId, 
      f.Name, f.Email, f.LegalTradingEntity, f.ABN, f.ACN, f.TaxNumber,
      f.Add1, f.Add2, f.Add3, f.Add4, f.Phone, f.Fax,
      f.FranchiseEnquiryEmail, f.State, f.Suburb, f.PostCode, 
      f.Phone2, f.AccountsEmail, f.FMSType,
      CAST(CompanyOwnedRF AS INT64) AS CompanyOwnedRF,
      CAST(UsingWebFMSBanking AS INT64) AS UsingWebFMSBanking
  FROM `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_Franchisee` f 
  LEFT JOIN `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_Country` c ON c.Code = f.CountryCode
  ;

END;