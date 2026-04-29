CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.sp_load_Staging_CustomerCommissionOverride_Stg`(
)
BEGIN
  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_CustomerCommissionOverride_Stg`
  SELECT NmId
        ,RFCode
        ,Courier
        ,ProductId
        ,Percentage
        ,UpdatedOn
        ,UpdatedBy
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_FMS_CustomerCommisionOverride`
  ;

END;