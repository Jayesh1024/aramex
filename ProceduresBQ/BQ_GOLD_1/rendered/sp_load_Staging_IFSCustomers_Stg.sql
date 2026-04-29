CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.sp_load_Staging_IFSCustomers_Stg`(
)
BEGIN
  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_IFSCustomers_Stg`
  SELECT
      CountryCode, RFCode, 
      IFSCustomerCode, CustomerType, Name, 
      Address1, Address2, Address3, 
      LastOrderNumber, CAST(Disabled AS INT64) AS Disabled
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_IFSCustomers`
  ;

END;