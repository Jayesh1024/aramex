CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Dim_RF` 
AS
SELECT
      HUB.FranchiseeCode
      ,CountryCode
      ,RFId
      ,Name
      ,LegalTradingEntity
      ,TaxNumber
      ,ABN
      ,ACN
      ,Phone
      ,Fax
      ,Address
  FROM `{{ project_id }}.{{ dataset_id }}.dv_HUB_RF` hub
JOIN `{{ project_id }}.{{ dataset_id }}.dv_SAT_RF` sat
  ON sat.FranchiseeCode_HSK = hub.FranchiseeCode_HSK
WHERE sat.IsCurrent = 1