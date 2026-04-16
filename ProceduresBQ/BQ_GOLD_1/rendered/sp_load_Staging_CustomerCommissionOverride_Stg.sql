CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.sp_load_Staging_CustomerCommissionOverride_Stg`(
)
BEGIN
  INSERT INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_CustomerCommissionOverride_Stg`
  SELECT NmId
        ,RFCode
        ,Courier
        ,ProductId
        ,Percentage
        ,UpdatedOn
        ,UpdatedBy
  FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_krillin_silver.Fastway_dbo_FMS_CustomerCommisionOverride`
  ;

END;