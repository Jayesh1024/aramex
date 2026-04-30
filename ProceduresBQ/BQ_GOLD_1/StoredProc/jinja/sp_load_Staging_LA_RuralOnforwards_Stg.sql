CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_LA_RuralOnforwards_Stg`(
  LastDate DATE,
  StartDate DATE,
  EndDate DATE
)
BEGIN
  --If specified startdate and enddate are inclusive
  SET StartDate = IF(StartDate = '1900-01-01', DATE_ADD(LastDate, INTERVAL 1 DAY), StartDate);
  SET EndDate = IF(EndDate = '1900-01-01', DATE(DATE_SUB(CURRENT_DATETIME(), INTERVAL 1 DAY)), EndDate);

  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_LA_RuralOnforwards_Stg`
  SELECT  Country
        ,RF
        ,Courier
        ,Label
        ,CAST(Date AS DATETIME) AS Date
        ,Time
        ,Onforwards
        ,FileId
    FROM `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_LA_RuralOnforwards`
    WHERE CAST(Date AS DATE) >= StartDate AND CAST(Date AS DATE) <= EndDate
  ORDER BY Country, RF,Courier,Label,Date,Time
  ;

END;