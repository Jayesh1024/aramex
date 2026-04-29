-- ==========================================================================================
-- Routine:     Load_Scans_Stg
-- Description: Combines scan data into one table for loading into Staging_LNK_Scan_Stg
-- Example:     Exec Staging_Load_Scans_Stg 123 
-- History:
--  18/07/2020  P. Waldron      Routine Written
--  17/12/2020  B. Woods        Updated to insert rows from the new TrackAndTrace_Stg source table
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.interimStaging_Interim_Load_Scans_Stg`(
  IN p_ProcessId INT64
)
BEGIN

  DECLARE v_Component     STRING DEFAULT 'interimStaging_Interim_Load_Scans_Stg';
  DECLARE v_Started       DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended         DATETIME;
  DECLARE v_Result        STRING;
  DECLARE v_ErrorMessage  STRING;
  DECLARE v_Inserted      INT64 DEFAULT 0;
  DECLARE v_LastId        INT64 DEFAULT 0;
  DECLARE v_Loaded        DATETIME DEFAULT CURRENT_DATETIME();

  BEGIN

    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Scans_Stg` (
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
        IFNULL(stg.Latitude,  0)          AS Latitude,
        IFNULL(stg.Longitude, 0)          AS Longitude,
        MAX(stg.RecordId)                 AS RecordSourceId,
        'Fastway.dbo_TrackAndTrace'       AS RecordSource,
        MAX(stg.ID)                       AS TrackAndTraceID,
        MAX(stg.iLocate)                  AS iLocate,
        MAX(stg.Signature)                AS Signature,
        DATE(MAX(stg.UploadDate))         AS UploadDate    -- ← cast here
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.InterimStaging_TrackAndTrace_Stg` AS stg
      INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Country` DC
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
      UNION DISTINCT ALL
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
        'Fastway.dbo_Labels' AS RecordSource
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Labels_Stg` AS stg
      GROUP BY
        Franchise, CourierNo, LabelNo, CountryName,
        ScanDate, PickupDelivery, Status,
        IFNULL(Latitude,  0), IFNULL(Longitude, 0)
      */
    ) AS Src;

    -- Capture inserted row count and last processed ID
    SET v_Inserted = (SELECT COUNT(*) FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Scans_Stg` WHERE ProcessId = p_ProcessId);
    SET v_LastId   = (SELECT MAX(ID) FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.InterimStaging_TrackAndTrace_Stg`);

    SET v_Result       = 'Success';
    SET v_ErrorMessage = CONCAT('LastID = ', CAST(v_LastId AS STRING));

  EXCEPTION WHEN ERROR THEN
    SET v_Result       = CONCAT('Failed - Last ID = ', CAST(v_LastId AS STRING));
    SET v_ErrorMessage = @@error.message;

  END;

  -- Record load metrics in log
  SET v_Ended = CURRENT_DATETIME();

  CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
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