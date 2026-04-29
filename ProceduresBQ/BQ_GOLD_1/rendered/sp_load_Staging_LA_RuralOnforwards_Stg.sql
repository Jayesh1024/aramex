CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.sp_load_Staging_LA_RuralOnforwards_Stg`(
  LastDate DATE,
  StartDate DATE,
  EndDate DATE
)
BEGIN
  --If specified startdate and enddate are inclusive
  SET StartDate = IF(StartDate = '1900-01-01', DATE_ADD(LastDate, INTERVAL 1 DAY), StartDate);
  SET EndDate = IF(EndDate = '1900-01-01', DATE(DATE_SUB(CURRENT_DATETIME(), INTERVAL 1 DAY)), EndDate);

  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_LA_RuralOnforwards_Stg`
  SELECT  Country
        ,RF
        ,Courier
        ,Label
        ,CAST(Date AS DATETIME) AS Date
        ,Time
        ,Onforwards
        ,FileId
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_LA_RuralOnforwards`
    WHERE CAST(Date AS DATE) >= StartDate AND CAST(Date AS DATE) <= EndDate
  ORDER BY Country, RF,Courier,Label,Date,Time
  ;

END;