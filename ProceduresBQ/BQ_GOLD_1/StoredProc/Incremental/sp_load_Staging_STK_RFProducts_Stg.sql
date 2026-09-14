CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.sp_load_Staging_STK_RFProducts_Stg`(
)
BEGIN
  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_STK_RFProducts_Stg`
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
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_STK_RFProducts`
  ;

END;