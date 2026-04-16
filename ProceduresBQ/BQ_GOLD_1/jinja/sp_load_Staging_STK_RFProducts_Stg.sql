CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_STK_RFProducts_Stg`(
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_STK_RFProducts_Stg`
  SELECT RFCode
        ,ProductId
        ,QtyOnHand
        ,QtyOnOrder
        ,DeliveryPrice
        ,PickupPrice
        ,CommisionPercentage
        ,CAST(IncludesGst AS INT64) AS IncludesGst
        ,FMSBookPrice
        ,ProductType
        ,SalesRepCommissionPercentage
        ,CAST(LocalPickup AS INT64) AS LocalPickup
        ,UpdatedOn
        ,UpdatedBy
    FROM `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_STK_RFProducts`
  ;

END;