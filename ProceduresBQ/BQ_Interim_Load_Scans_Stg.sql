-- ==========================================================================================
-- Routine:     Load_Scans_Stg
-- Description: Combines scan data into one table for loading into Staging.LNK_Scan_Stg
-- Example:     Exec Staging.Load_Scans_Stg 123 
-- History:
--  18/07/2020  P. Waldron      Routine Written
--  17/12/2020  B. Woods        Updated to insert rows from the new TrackAndTrace_Stg source table
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `project.interimstaging.Interim_Load_Scans_Stg`(
  IN p_ProcessId INT64
)
BEGIN

  DECLARE v_Component     STRING DEFAULT 'interimstaging.Interim_Load_Scans_Stg';
  DECLARE v_Started       DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended         DATETIME;
  DECLARE v_Result        STRING;
  DECLARE v_ErrorMessage  STRING;
  DECLARE v_Inserted      INT64 DEFAULT 0;
  DECLARE v_LastId        INT64 DEFAULT 0;
  DECLARE v_Loaded        DATETIME DEFAULT CURRENT_DATETIME();

  BEGIN

    INSERT INTO `project.staging.Scans_Stg` (
      FranchiseeCode,
      CourierNo,
      LabelNo,
      CountryName,
      ScanDate,
      ScanType,
      ScanStatus,
      Latitude,
      Longitude,
      RecordSource,
      RecordSourceId,
      Loaded,
      ProcessId,
      TrackAndTraceID,
      iLocate,
      Signature,
      UploadDate
    )
    SELECT
      FranchiseeCode,
      CourierNo,
      LabelNo,
      CountryName,
      ScanDate,
      ScanType,
      ScanStatus,
      Latitude,
      Longitude,
      RecordSource,
      RecordSourceId,
      v_Loaded,
      p_ProcessId,
      TrackAndTraceID,
      iLocate,
      Signature,
      UploadDate
    FROM (
      SELECT
        stg.FranchiseeCode,
        stg.CourierNo,
        stg.LabelNo,
        DC.CountryName,
        stg.ScanType,
        stg.ScanStatus,
        stg.ScanDate,
        IFNULL(stg.Latitude,  0) AS Latitude,
        IFNULL(stg.Longitude, 0) AS Longitude,
        MAX(stg.RecordId)        AS RecordSourceId,
        'Fastway.dbo.TrackAndTrace' AS RecordSource,
        MAX(stg.ID)              AS TrackAndTraceID,
        MAX(stg.iLocate)         AS iLocate,
        MAX(stg.Signature)       AS Signature,
        MAX(stg.UploadDate)      AS UploadDate
      FROM `project.interimstaging.TrackAndTrace_Stg` AS stg
      INNER JOIN `project.dbo.Dim_Country` DC
        ON DC.CountryCode = stg.CountryCode
      GROUP BY
        stg.FranchiseeCode,
        stg.CourierNo,
        stg.LabelNo,
        DC.CountryName,
        stg.ScanDate,
        stg.ScanType,
        stg.ScanStatus,
        IFNULL(stg.Latitude,  0),
        IFNULL(stg.Longitude, 0)

      /*
      UNION ALL
      SELECT
        Franchise        AS FranchiseeCode,
        CourierNo,
        LabelNo,
        CountryName,
        PickupDelivery   AS ScanType,
        Status           AS ScanStatus,
        ScanDate,
        IFNULL(Latitude,  0),
        IFNULL(Longitude, 0),
        MAX(RecordId)    AS RecordSourceId,
        'Fastway.dbo.Labels' AS RecordSource
      FROM `project.staging.Labels_Stg` AS stg
      GROUP BY
        Franchise, CourierNo, LabelNo, CountryName,
        ScanDate, PickupDelivery, Status,
        IFNULL(Latitude,  0), IFNULL(Longitude, 0)
      */
    ) AS Src;

    -- Capture inserted row count and last processed ID
    SET v_Inserted = (SELECT COUNT(*) FROM `project.staging.Scans_Stg` WHERE ProcessId = p_ProcessId);
    SET v_LastId   = (SELECT MAX(ID) FROM `project.interimstaging.TrackAndTrace_Stg`);

    SET v_Result       = 'Success';
    SET v_ErrorMessage = CONCAT('LastID = ', CAST(v_LastId AS STRING));

  EXCEPTION WHEN ERROR THEN
    SET v_Result       = CONCAT('Failed - Last ID = ', CAST(v_LastId AS STRING));
    SET v_ErrorMessage = @@error.message;

  END;

  -- Record load metrics in log
  SET v_Ended = CURRENT_DATETIME();

  CALL `project.staging.SaveLog`(
    v_Component,
    p_ProcessId,
    v_Started,
    v_Ended,
    v_Result,
    v_ErrorMessage,
    v_Inserted,
    -1,
    -1
  );

END;