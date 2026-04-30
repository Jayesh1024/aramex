CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_HDManifests_Stg`(
  NextID INT64
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_HDManifests_Stg`
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
  FROM `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_HDManifests` 
  WHERE RecordId >= NextID
  ;

END;