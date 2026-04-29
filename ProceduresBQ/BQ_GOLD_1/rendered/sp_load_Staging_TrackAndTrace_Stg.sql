CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.sp_load_Staging_TrackAndTrace_Stg`(
)
BEGIN
  DECLARE StartDateOnly DATETIME;
  DECLARE endDateOnly DATETIME;
  SET StartDateOnly = DATE_SUB(CURRENT_DATETIME(), INTERVAL 4 DAY);
  SET endDateOnly = DATE_SUB(CURRENT_DATETIME(), INTERVAL 5 MINUTE);

  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_TrackAndTrace_Stg`
  SELECT 
      a.ID,
      a.RecordId,
      a.CountryCode,
      a.FranchiseeCode,
      a.ScanType,
      a.Status AS ScanStatus,
      a.LabelNo,
      CAST(a.ScanDate AS DATETIME) AS ScanDate,
      a.CourierNo,
      '' AS CountryName,
      CAST(a.UploadDate AS DATETIME) AS UploadDate,
      CAST(a.RecordCreateDate AS DATETIME) AS RecordCreateDate,
      a.iLocate,
      a.ProductId,
      CAST(NULL AS NUMERIC) AS Latitude,
      CAST(NULL AS NUMERIC) AS Longitude
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_vegeta_silver.FastwayReports_dbo_TrackAndTrace_7Day` a 
      --FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_vegeta_silver.FastwayReports_dbo_TrackAndTraceData` 
      WHERE Countrycode = 1  -- in (1,6,11,24) 
        AND DATE(RecordCreateDate) >= StartDateOnly AND DATE(RecordCreateDate) <= endDateOnly
  ;

END;