CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_IFSCustomers_Stg`(
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_IFSCustomers_Stg`
  SELECT
      CountryCode, RFCode, 
      IFSCustomerCode, CustomerType, Name, 
      Address1, Address2, Address3, 
      LastOrderNumber, CAST(Disabled AS INT64) AS Disabled
  FROM `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_IFSCustomers`
  ;

END;