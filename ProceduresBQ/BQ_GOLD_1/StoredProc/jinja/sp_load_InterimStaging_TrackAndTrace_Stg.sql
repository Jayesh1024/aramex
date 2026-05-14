CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_InterimStaging_TrackAndTrace_Stg`(
  lastId INT64
)
BEGIN
  DECLARE endID INT64;
  DECLARE boundDate DATETIME;

  -- Use DATETIME_SUB and CURRENT_DATETIME() to replicate DATEADD and GETDATE()
  SET boundDate = DATETIME_SUB(CURRENT_DATETIME(), INTERVAL 30 DAY);
  SET endID = lastId + 200000; -- Batchsize - rows every 15min

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
      a.Latitude,
      a.Longitude,
      a.Signature
  FROM (
      SELECT
          ID,
          RecordId,
          CountryCode,
          FranchiseeCode,
          ScanType,
          Status AS ScanStatus,
          LabelNo,
          ScanDate,
          CourierNo,
          '' AS CountryName,
          UploadDate,
          RecordCreateDate,
          iLocate,
          ProductId,
          Latitude,
          Longitude,
          Signature
      FROM `{{ project_id }}.{{ source_dataset_id }}.FastwayReports_dbo_TrackAndTraceDataP`
      WHERE ScanDate > boundDate
        AND ID > lastId 
        AND ID <= endID
        AND CountryCode IN (1, 6, 11, 24)
  ) a
  ORDER BY ID;

END;