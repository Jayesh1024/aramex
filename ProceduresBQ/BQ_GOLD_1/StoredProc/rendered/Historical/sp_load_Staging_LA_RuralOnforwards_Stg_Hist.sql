CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.sp_load_Staging_LA_RuralOnforwards_Stg_Hist`(
)
BEGIN
  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_LA_RuralOnforwards_Stg`
  SELECT  Country
        ,RF
        ,Courier
        ,Label
        ,CAST(Date AS DATETIME) AS Date
        ,Time
        ,Onforwards
        ,FileId
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_LA_RuralOnforwards`
  ORDER BY Country, RF,Courier,Label,Date,Time
  ;

END