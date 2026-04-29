CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.sp_load_Staging_FMS_Customer_Stg`(
)
BEGIN
  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_FMS_Customer_Stg`
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
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_FMS_Customer` c
  LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_FMS_LookUpTableDetail` g on HeaderCode = 'IND' and c.IndustryClassification = g.ItemCode and g.NMid = c.NMId
  ;

END;