CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_FMS_Customer_Stg`(
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_FMS_Customer_Stg`
  SELECT RFId
        ,CourierNumber
        ,Concat(RFId, LPAD(CAST(CourierNumber AS STRING), 3, '0'), LPAD(CAST(CustomerNumber AS STRING), 4, '0')) AS CustomerKey
        ,CustomerID
        ,CustomerNumber
        ,CAST(Active AS INT64) AS Active
        ,DeactiveDescription
        ,BusinessName
        ,TradingName
        ,LegalEntity
        ,LegEntOtherDes
        ,ShortName
        ,EnterpriseFastLabelParentId
        ,CAST(XLabelCustomer AS INT64) AS XLabelCustomer
        ,StreetAddress1
        ,StreetAddress2
        ,StreetAddress3
        ,PostalAddress1
        ,PostalAddress2
        ,PostalAddress3
        ,PostCodeStreet
        ,PostCodePostal
        ,PhoneNumber
        ,FaxNumber
        ,Mobile
        ,EmailAddress
        ,LastPurchDate
        ,StartDate
        ,IndustryClassification
        ,g.Description as IndustryDescription
        ,IndustryClassifcationOtherDes
        ,CompanyNumber
        ,TaxNumber
        ,Latitude
        ,Longitude
        ,CAST(MultiCustomer AS INT64) AS MultiCustomer
        ,PriceListCode
        ,B2B
        ,B2C
        ,CAST(xLabelAlcoholDeliveries AS INT64) AS xLabelAlcoholDeliveries
        ,CAST(NULL AS STRING) AS SalesForceId
    FROM `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_FMS_Customer` c
  LEFT JOIN `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_FMS_LookUpTableDetail` g on HeaderCode = 'IND' and c.IndustryClassification = g.ItemCode and g.NMid = c.NMId
  ;

END;
