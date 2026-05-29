-- ==========================================================================================
-- Routine:     Load_Fact_Scan_KPI_Stg
-- Description: Recalc scan KPI stats for Labels that have just arrived
-- Example:     Exec [Staging].[Load_CF_Productivity_Stg] 124
-- History:
--  19/08/2023  B. Woods      Routine Written

-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.Staging_Load_CF_Productivity_NZ`(
  IN p_ProcessId INT64
)
BEGIN
  DECLARE v_Component       STRING DEFAULT 'Staging_Load_CF_Productivity_NZ';
  DECLARE v_Started         DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended           DATETIME;
  DECLARE v_Result          STRING;
  DECLARE v_ErrorMessage    STRING;
  DECLARE v_TotalInserted   INT64 DEFAULT 0;
  DECLARE v_Inserted        INT64 DEFAULT 0;
  DECLARE v_Loaded          DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_CountryCode     INT64 DEFAULT 6;
  DECLARE v_CountryName     STRING DEFAULT 'New Zealand';
  DECLARE v_StartDate       DATETIME;
  DECLARE v_EndDate         DATETIME;
  DECLARE v_RowCount        INT64;
  -- -----------------------------------------------------------------------
  -- Early exit if no rows to process
  -- Using COUNT(*) to avoid errors if ID column contains non-numeric strings
  -- -----------------------------------------------------------------------
  SET v_RowCount = (
    SELECT COUNT(*) 
    FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_KPI_Labels_Stg`
  );
  IF v_RowCount = 0 THEN
    -- Log skipping and exit
    SET v_Result = 'Success - No rows to process';
    SET v_Ended = CURRENT_DATETIME();
    CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
        v_Component, p_ProcessId, v_Started, v_Ended, v_Result, '', 0, 0, -1
    );
    RETURN;
  END IF;
  -- -----------------------------------------------------------------------
  -- Resolve date window from LoadControl
  -- BigQuery uses SET var = (SELECT ...) instead of SELECT INTO
  -- -----------------------------------------------------------------------
  SET v_StartDate = (
    SELECT CAST(LastValue AS DATETIME)
    FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_LoadControl`
    WHERE RecordSource = 'CF_Productivity_NZ'
    LIMIT 1
  );
  SET v_EndDate = DATETIME_ADD(v_StartDate, INTERVAL 1 DAY);
  -- -----------------------------------------------------------------------
  -- Truncate Staging targets
  -- -----------------------------------------------------------------------
  TRUNCATE TABLE `{{ project_id }}.{{ target_dataset_id }}.Staging_CF_Productivity_Stg_NZ`;
  TRUNCATE TABLE `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_Scan_Stg2_NZ`;
  BEGIN
    -- -----------------------------------------------------------------------
    -- Load scan window into Fact_Scan_Stg2_NZ
    -- -----------------------------------------------------------------------
    INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_Scan_Stg2_NZ`
    (
      LabelNo, ScanDateTime, ScanDate,
      ScanType, ScanStatus,
      FranchiseeCode, CourierNumber,
      CountryName, Latitude, Longitude
    )
    SELECT
      LabelNo,
      ScanDate                  AS ScanDateTime,
      CAST(ScanDate AS DATE)    AS ScanDate,
      ScanType, ScanStatus,
      FranchiseeCode, CourierNumber,
      CountryName, Latitude, Longitude
    FROM `{{ project_id }}.{{ target_dataset_id }}.dv_LNK_Scan`
    WHERE ScanDate >= v_StartDate
      AND ScanDate <  v_EndDate;
    -- -----------------------------------------------------------------------
    -- Iterate over each date in the window
    -- -----------------------------------------------------------------------
    FOR day_rec IN (
      SELECT day_date
      FROM UNNEST(
        GENERATE_DATE_ARRAY(
          CAST(v_StartDate AS DATE),
          DATE_SUB(CAST(v_EndDate AS DATE), INTERVAL 1 DAY)
        )
      ) AS day_date
    )
    DO
      -- 1. Deliveries for Day
      INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_CF_Productivity_Stg_NZ`
      (
        WorkDate, CountryCode, RF, CF, DeliveriesForDay,
        FirstDeliveryTime, FirstDelivery_Latitude, FirstDelivery_Longitude,
        LastDeliveryTime,  LastDelivery_Latitude,  LastDelivery_Longitude
      )
      SELECT
        day_rec.day_date, v_CountryCode, s.FranchiseeCode, s.CourierNumber,
        COUNT(DISTINCT s.LabelNo), MIN(s.ScanDateTime), MIN(s.Latitude), MIN(s.Longitude),
        MAX(s.ScanDateTime), MAX(s.Latitude), MAX(s.Longitude)
      FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_Scan_Stg2_NZ` s
      LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIExcludedLabels` ex
        ON SUBSTR(s.LabelNo, 1, 2) = ex.LabelPrefix AND ex.CountryName = s.CountryName
      WHERE s.ScanDate = day_rec.day_date AND s.CountryName = v_CountryName AND s.ScanType = 'D' AND ex.LabelPrefix IS NULL
      GROUP BY s.FranchiseeCode, s.CourierNumber;
      -- 2. First scan time
      INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_CF_Productivity_Stg_NZ`
      (WorkDate, CountryCode, RF, CF, FirstScanTime)
      SELECT
        day_rec.day_date, v_CountryCode, s.FranchiseeCode, s.CourierNumber, MIN(s.ScanDateTime)
      FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_Scan_Stg2_NZ` s
      WHERE s.ScanDate = day_rec.day_date AND s.CountryName = v_CountryName
      GROUP BY s.FranchiseeCode, s.CourierNumber;
      -- 3. In-depot scan start time (B87)
      INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_CF_Productivity_Stg_NZ`
      (WorkDate, CountryCode, RF, CF, ArrivalTime_AM, ArrivalTime_PM, ArrivalTime_TW, InDepotScan_StartTime)
      SELECT
        day_rec.day_date, v_CountryCode, FranchiseeCode, CourierNumber,
        MAX(IF(Cycle = 'AM', ScanDateTime, NULL)),
        MAX(IF(Cycle = 'PM', ScanDateTime, NULL)),
        MAX(IF(Cycle = 'TW', ScanDateTime, NULL)),
        MAX(IF(Cycle = 'PM', NextScanTime, NULL))
      FROM (
        SELECT FranchiseeCode, CourierNumber, ScanStatus, ScanDateTime,
          CASE WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 10 THEN 'AM' WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 15 THEN 'PM' ELSE 'TW' END AS Cycle,
          LEAD(ScanDateTime) OVER (PARTITION BY s.FranchiseeCode, s.CourierNumber ORDER BY s.ScanDateTime) AS NextScanTime
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_Scan_Stg2_NZ` s
        WHERE s.ScanDate = day_rec.day_date AND s.CountryName = v_CountryName
      ) s
      WHERE ScanStatus = 'B87'
      GROUP BY FranchiseeCode, CourierNumber;
      -- 4. In-depot scan finish time (B88)
      INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_CF_Productivity_Stg_NZ`
      (WorkDate, CountryCode, RF, CF, DepartureTime_AM, DepartureTime_PM, DepartureTime_TW, InDepotScan_FinishTime)
      SELECT
        day_rec.day_date, v_CountryCode, FranchiseeCode, CourierNumber,
        MAX(IF(Cycle = 'AM', ScanDateTime, NULL)),
        MAX(IF(Cycle = 'PM', ScanDateTime, NULL)),
        MAX(IF(Cycle = 'TW', ScanDateTime, NULL)),
        MAX(IF(Cycle = 'PM', PreviousScanTime, NULL))
      FROM (
        SELECT FranchiseeCode, CourierNumber, ScanStatus, ScanDateTime,
          CASE WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 10 THEN 'AM' WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 15 THEN 'PM' ELSE 'TW' END AS Cycle,
          LAG(ScanDateTime) OVER (PARTITION BY s.FranchiseeCode, s.CourierNumber ORDER BY s.ScanDateTime) AS PreviousScanTime
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_Scan_Stg2_NZ` s
        WHERE s.ScanDate = day_rec.day_date AND s.CountryName = v_CountryName
      ) ss
      WHERE ScanStatus = 'B88'
      GROUP BY FranchiseeCode, CourierNumber;
      -- 5. Average time between stops (< 30 min)
      INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_CF_Productivity_Stg_NZ`
      (WorkDate, CountryCode, RF, CF, AvergeTimeBetweenStopsMinutes)
      SELECT
        day_rec.day_date, v_CountryCode, FranchiseeCode, CourierNumber,
        AVG(DATETIME_DIFF(NextScanTime, ScanDateTime, MINUTE))
      FROM (
        SELECT FranchiseeCode, CourierNumber, ScanDateTime,
          LEAD(ScanDateTime) OVER (PARTITION BY s.FranchiseeCode, s.CourierNumber ORDER BY s.ScanDateTime) AS NextScanTime
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_Scan_Stg2_NZ` s
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIExcludedLabels` ex ON SUBSTR(s.LabelNo, 1, 2) = ex.LabelPrefix AND ex.CountryName = s.CountryName
        WHERE s.ScanDate = day_rec.day_date AND s.CountryName = v_CountryName AND s.ScanType IN ('P', 'D') AND ex.LabelPrefix IS NULL
      ) s
      WHERE DATETIME_DIFF(NextScanTime, ScanDateTime, MINUTE) BETWEEN 1 AND 29
      GROUP BY FranchiseeCode, CourierNumber;
      -- 6. Break stops (gaps > 30 minutes)
      INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_CF_Productivity_Stg_NZ`
      (WorkDate, CountryCode, RF, CF, BreakStops)
      SELECT
        day_rec.day_date, v_CountryCode, FranchiseeCode, CourierNumber, COUNT(*)
      FROM (
        SELECT FranchiseeCode, CourierNumber, ScanDateTime,
          LEAD(ScanDateTime) OVER (PARTITION BY s.FranchiseeCode, s.CourierNumber ORDER BY s.ScanDateTime) AS NextScanTime
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_Scan_Stg2_NZ` s
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIExcludedLabels` ex ON SUBSTR(s.LabelNo, 1, 2) = ex.LabelPrefix AND ex.CountryName = s.CountryName
        WHERE s.ScanDate = day_rec.day_date AND s.CountryName = v_CountryName AND s.ScanType IN ('P', 'D') AND ex.LabelPrefix IS NULL
      ) AS A
      WHERE DATETIME_DIFF(NextScanTime, ScanDateTime, MINUTE) > 30
      GROUP BY FranchiseeCode, CourierNumber;
      -- 7. Pickups for Day
      INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_CF_Productivity_Stg_NZ`
      (WorkDate, CountryCode, RF, CF, PickupsForDday, FirstPickupTime, FirstPickup_Latitude, FirstPickup_Longitude, LastPickupTime, LastPickup_Latitude, LastPickup_Longitude, ActiveCustomers)
      SELECT
        day_rec.day_date, v_CountryCode, s.FranchiseeCode, s.CourierNumber,
        COUNT(DISTINCT s.LabelNo), MIN(s.ScanDateTime), MIN(s.Latitude), MIN(s.Longitude), MAX(s.ScanDateTime), MAX(s.Latitude), MAX(s.Longitude), COUNT(DISTINCT l.FMSCustomerID)
      FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_Scan_Stg2_NZ` s
      LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIExcludedLabels` ex ON SUBSTR(s.LabelNo, 1, 2) = ex.LabelPrefix AND ex.CountryName = s.CountryName
      LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Label_partitioned` l ON s.LabelNo = l.LabelNo AND s.CountryName = l.Country
      WHERE s.ScanDate = day_rec.day_date AND s.CountryName = v_CountryName AND s.ScanType = 'P' AND ex.LabelPrefix IS NULL
      GROUP BY s.FranchiseeCode, s.CourierNumber;
    END FOR;
    -- -----------------------------------------------------------------------
    -- Final load: aggregate Staging into CF_Productivity_NZ
    -- -----------------------------------------------------------------------
    INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dbo_CF_Productivity_NZ_partitioned`
    (
      WorkDate, CountryCode, RF, CF, DeliveriesForDay, PickupsForDday, ActiveCustomers, FirstScanTime,
      ArrivalTime_AM, ArrivalTime_PM, ArrivalTime_TW, DepartureTime_AM, DepartureTime_PM, DepartureTime_TW,
      FirstDeliveryTime, FirstPickupTime, LastPickupTime, LastDeliveryTime,
      InDepotScan_StartTimePM, InDepotScan_FinishTimePM, AvergeTimeBetweenStopsMinutes, BreakStops,
      FirstDelivery_Latitude, FirstDelivery_Longitude, LastDelivery_Latitude, LastDelivery_Longitude,
      FirstPickup_Latitude, FirstPickup_Longitude, LastPickup_Latitude, LastPickup_Longitude
    )
    SELECT
      WorkDate, CountryCode, RF, CF,
      MAX(DeliveriesForDay), MAX(PickupsForDday), MAX(ActiveCustomers), MIN(FirstScanTime),
      MAX(ArrivalTime_AM), MAX(ArrivalTime_PM), MAX(ArrivalTime_TW), MAX(DepartureTime_AM), MAX(DepartureTime_PM), MAX(DepartureTime_TW),
      MIN(FirstDeliveryTime), MIN(FirstPickupTime), MAX(LastPickupTime), MAX(LastDeliveryTime),
      MAX(InDepotScan_StartTime), MAX(InDepotScan_FinishTime), MAX(AvergeTimeBetweenStopsMinutes), MAX(BreakStops),
      MAX(FirstDelivery_Latitude), MAX(FirstDelivery_Longitude), MAX(LastDelivery_Latitude), MAX(LastDelivery_Longitude),
      MAX(FirstPickup_Latitude), MAX(FirstPickup_Longitude), MAX(LastPickup_Latitude), MAX(LastPickup_Longitude)
    FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_CF_Productivity_Stg_NZ`
    GROUP BY WorkDate, CountryCode, RF, CF;
    SET v_TotalInserted = @@row_count;
    -- Advance LoadControl
    UPDATE `{{ project_id }}.{{ target_dataset_id }}.Staging_LoadControl`
    SET LastValue = CAST(v_EndDate AS STRING)
    WHERE RecordSource = 'CF_Productivity_NZ';
    SET v_Result = 'Success';
  EXCEPTION WHEN ERROR THEN
    SET v_Result       = 'Failed';
    SET v_ErrorMessage = @@error.message;
  END;
  -- -----------------------------------------------------------------------
  -- Final Log Call
  -- -----------------------------------------------------------------------
  SET v_Ended = CURRENT_DATETIME();
  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
    v_Component, p_ProcessId, v_Started, v_Ended, v_Result, v_ErrorMessage, v_TotalInserted, -1, -1
  );
END;