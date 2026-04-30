CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_fl_ServiceItem_Stg`(
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_fl_ServiceItem_Stg`
  SELECT
      ServiceItemId
      ,ServiceId
      ,CountryId
      ,Rf
      ,PriceList
      ,ProductId
      ,Description
      ,DisplayValue
      ,DisplayText
      ,CAST(DisplaySelected AS INT64) AS DisplaySelected
      ,CAST(Percentage AS NUMERIC) AS Percentage
      ,CAST(Price AS NUMERIC) AS Price
      ,CAST(PickupAmount AS NUMERIC) AS PickupAmount
      ,CAST(ServiceCommission AS NUMERIC) AS ServiceCommission
      ,CAST(ReadOnly AS INT64) AS ReadOnly
      ,CAST(DisplayForm AS INT64) AS DisplayForm
      ,CAST(DisplaySummmary AS INT64) AS DisplaySummmary
      ,ChargeLevel
      ,CAST(IsDefault AS INT64) AS IsDefault
      ,ServiceType
      ,TriggerPoint
  FROM `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_fl_ServiceItem`
  ;

END;