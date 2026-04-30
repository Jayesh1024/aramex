CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_TrackAndTrace_Stg`(
)
BEGIN
  DECLARE StartDateOnly DATETIME;
  DECLARE endDateOnly DATETIME;
  SET StartDateOnly = DATE_SUB(CURRENT_DATETIME(), INTERVAL 4 DAY);
  SET endDateOnly = DATE_SUB(CURRENT_DATETIME(), INTERVAL 5 MINUTE);

  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_TrackAndTrace_Stg`
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
      FROM `{{ project_id }}.{{ source_dataset_id }}.FastwayReports_dbo_TrackAndTraceData` a
      WHERE Countrycode = 1  -- in (1,6,11,24) 
        AND DATE(RecordCreateDate) >= StartDateOnly AND DATE(RecordCreateDate) <= endDateOnly
  ;

END;