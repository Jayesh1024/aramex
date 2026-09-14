CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.sp_load_Staging_HDManifests_Stg_Hist`(
)
BEGIN
  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_HDManifests_Stg`
  SELECT 
      ManifestId,
      ConDate,
      LabelNo,
      SendAdd1, SendAdd2, SendAdd3, SendAdd4, SendAdd5, SendAdd6,
      RecAdd1, RecAdd2, RecAdd3, RecAdd4, RecAdd5, RecAdd6,
      ClientId,
      CollectionPostCode, CollectionCountryCode,
      DeliveryPostCode, DeliveryCountryCode,
      CustomerID,
      DeliveryRF,
      CollectionRF,
      CountryCode,
      Quantity,
      Weight,
      Width,
      Length,
      Height,
      DateInserted,
      RecordId,
      UniqueParcelIdentifier
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_HDManifests` 
  ;

END;