CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.sp_load_InterimStaging_TrackAndTrace_Stg`(
  lastId INT64
)
BEGIN
  DECLARE endID INT64;
  SET endID = lastId + 200000;

  INSERT INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.InterimStaging_TrackAndTrace_Stg`
  SELECT
    a.ID,
    a.RecordId,
    a.CountryCode,
    a.FranchiseeCode,
    a.ScanType,
    a.ScanStatus,
    a.LabelNo,
    a.ScanDate,
    a.CourierNo,
    a.CountryName,
    a.UploadDate,
    a.RecordCreateDate,
    a.iLocate,
    a.ProductId,
    CAST(TD.Latitude AS NUMERIC) AS Latitude,
    CAST(TD.Longitude AS NUMERIC) AS Longitude,
    TD.Signature
  FROM (
    SELECT
      ID, RecordId, CountryCode, FranchiseeCode, ScanType,
      Status AS ScanStatus, LabelNo, CAST(ScanDate AS DATETIME) AS ScanDate, CourierNo,
      '' AS CountryName, CAST(UploadDate AS DATETIME) AS UploadDate, CAST(RecordCreateDate AS DATETIME) AS RecordCreateDate, iLocate, ProductId
    FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_vegeta_silver.FastwayReports_dbo_TrackAndTraceDataP` T7
    WHERE ID > lastId AND ID <= endID
      AND Countrycode IN (1, 6, 11, 24)
  ) a
  LEFT JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_vegeta_silver.FastwayReports_dbo_TrackAndTraceData` TD ON TD.ID = a.ID
  ORDER BY ID
  ;

END;