CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_RF` 
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
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_RF` hub
JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_RF` sat
  ON sat.FranchiseeCode_HSK = hub.FranchiseeCode_HSK
WHERE sat.IsCurrent = 1