-- ==========================================================================================
-- Routine:     Load_Fact_Scan_KPI_Stg
-- Description: Recalc scan KPI stats for Labels that have just arrived
-- Example:     Exec [Staging].[Load_CF_Productivity_Stg] 124
-- History:
--  19/08/2023  B. Woods      Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.Staging_Load_CF_Productivity_AU`(
  IN p_ProcessId INT64
)
BEGIN

  DECLARE v_Component       STRING DEFAULT 'Staging_Load_CF_Productivity_AU';
  DECLARE v_Started         DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended           DATETIME;
  DECLARE v_Result          STRING;
  DECLARE v_ErrorMessage    STRING;
  DECLARE v_TotalInserted   INT64 DEFAULT 0;
  DECLARE v_Inserted        INT64 DEFAULT 0;
  DECLARE v_Loaded          DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_LoadedDate      DATE DEFAULT CURRENT_DATE();
  DECLARE v_CountryCode     INT64 DEFAULT 1;
  DECLARE v_CountryName     STRING DEFAULT 'Australia';
  DECLARE v_StartDate       DATETIME;
  DECLARE v_EndDate         DATETIME;
  DECLARE v_RowCount        INT64; -- Renamed from v_LastId for clarity

  -- -----------------------------------------------------------------------
  -- Early exit if no rows to process
  -- FIX: Use COUNT(*) to avoid casting alphanumeric IDs to INT64
  -- -----------------------------------------------------------------------
  SET v_RowCount = (
    SELECT COUNT(*) 
    FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_KPI_Labels_Stg`
  );

  IF v_RowCount = 0 THEN
    RETURN;
  END IF;

  -- -----------------------------------------------------------------------
  -- Resolve date window from LoadControl
  -- -----------------------------------------------------------------------
  SET v_StartDate = (
    SELECT CAST(LastValue AS DATETIME)
    FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_LoadControl`
    WHERE RecordSource = 'CF_Productivity'
    LIMIT 1
  );

  SET v_EndDate = DATETIME_ADD(v_StartDate, INTERVAL 1 DAY);

  -- -----------------------------------------------------------------------
  -- Truncate Staging targets
  -- -----------------------------------------------------------------------
  TRUNCATE TABLE `{{ project_id }}.{{ target_dataset_id }}.Staging_CF_Productivity_Stg_AU`;
  TRUNCATE TABLE `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_Scan_Stg2`;

  SET v_Loaded = CURRENT_DATETIME();

  BEGIN

    -- -----------------------------------------------------------------------
    -- Load scan window into Fact_Scan_Stg2
    -- -----------------------------------------------------------------------
    INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_Scan_Stg2`
    (
      LabelNo, ScanDateTime, ScanDate, ScanType, ScanStatus,
      FranchiseeCode, CourierNumber, CountryName, Latitude, Longitude
    )
    SELECT
      LabelNo, ScanDate, CAST(ScanDate AS DATE), ScanType, ScanStatus,
      FranchiseeCode, CourierNumber, CountryName, Latitude, Longitude
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
      INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_CF_Productivity_Stg_AU`
      (
        WorkDate, CountryCode, RF, CF, DeliveriesForDay,
        FirstDeliveryTime, FirstDelivery_Latitude, FirstDelivery_Longitude,
        LastDeliveryTime,  LastDelivery_Latitude,  LastDelivery_Longitude
      )
      SELECT
        day_rec.day_date, v_CountryCode, s.FranchiseeCode, s.CourierNumber,
        COUNT(DISTINCT s.LabelNo), MIN(s.ScanDateTime), MIN(s.Latitude), MIN(s.Longitude),
        MAX(s.ScanDateTime), MAX(s.Latitude), MAX(s.Longitude)
      FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_Scan_Stg2` s
      LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIExcludedLabels` ex
        ON SUBSTR(s.LabelNo, 1, 2) = ex.LabelPrefix AND ex.CountryName = s.CountryName
      WHERE s.ScanDate = day_rec.day_date AND s.CountryName = v_CountryName AND s.ScanType = 'D' AND ex.LabelPrefix IS NULL
      GROUP BY s.FranchiseeCode, s.CourierNumber;

      -- 2. First scan time
      INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_CF_Productivity_Stg_AU`
      (WorkDate, CountryCode, RF, CF, FirstScanTime)
      SELECT day_rec.day_date, v_CountryCode, s.FranchiseeCode, s.CourierNumber, MIN(s.ScanDateTime)
      FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_Scan_Stg2` s
      WHERE s.ScanDate = day_rec.day_date AND s.CountryName = v_CountryName
      GROUP BY s.FranchiseeCode, s.CourierNumber;

      -- 3. In-depot scan start (CK1)
      INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_CF_Productivity_Stg_AU`
      (WorkDate, CountryCode, RF, CF, ArrivalTime_AM, ArrivalTime_PM, ArrivalTime_TW, InDepotScan_StartTime)
      SELECT
        day_rec.day_date, v_CountryCode, FranchiseeCode, CourierNumber,
        IF(Cycle = 'AM', ScanDateTime, NULL), IF(Cycle = 'PM', ScanDateTime, NULL), IF(Cycle = 'TW', ScanDateTime, NULL),
        IF(Cycle = 'PM', MAX(NextScanTime), NULL)
      FROM (
        SELECT FranchiseeCode, CourierNumber, ScanStatus, ScanDateTime,
          CASE WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 10 THEN 'AM' WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 15 THEN 'PM' ELSE 'TW' END AS Cycle,
          LEAD(ScanDateTime) OVER (PARTITION BY s.FranchiseeCode, s.CourierNumber ORDER BY s.ScanDateTime) AS NextScanTime
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_Scan_Stg2` s
        WHERE s.ScanDate = day_rec.day_date AND s.CountryName = v_CountryName
      ) s
      WHERE ScanStatus = 'CK1'
      GROUP BY FranchiseeCode, CourierNumber, Cycle, ScanDateTime;

      -- 4. In-depot scan finish (CK2)
      INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_CF_Productivity_Stg_AU`
      (WorkDate, CountryCode, RF, CF, DepartureTime_AM, DepartureTime_PM, DepartureTime_TW, InDepotScan_FinishTime)
      SELECT
        day_rec.day_date, v_CountryCode, FranchiseeCode, CourierNumber,
        IF(Cycle = 'AM', ScanDateTime, NULL), IF(Cycle = 'PM', ScanDateTime, NULL), IF(Cycle = 'TW', ScanDateTime, NULL),
        IF(Cycle = 'PM', MAX(PreviousScanTime), NULL)
      FROM (
        SELECT FranchiseeCode, CourierNumber, ScanStatus, ScanDateTime,
          CASE WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 10 THEN 'AM' WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 15 THEN 'PM' ELSE 'TW' END AS Cycle,
          LAG(ScanDateTime) OVER (PARTITION BY s.FranchiseeCode, s.CourierNumber ORDER BY s.ScanDateTime) AS PreviousScanTime
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_Scan_Stg2` s
        WHERE s.ScanDate = day_rec.day_date AND s.CountryName = v_CountryName
      ) ss
      WHERE ScanStatus = 'CK2'
      GROUP BY FranchiseeCode, CourierNumber, Cycle, ScanDateTime;

      -- 5. Average time between stops
      INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_CF_Productivity_Stg_AU`
      (WorkDate, CountryCode, RF, CF, AvergeTimeBetweenStopsMinutes)
      SELECT day_rec.day_date, v_CountryCode, FranchiseeCode, CourierNumber, CAST(AVG(DATETIME_DIFF(NextScanTime, ScanDateTime, MINUTE)) AS INT64)
      FROM (
        SELECT FranchiseeCode, CourierNumber, ScanDateTime,
          LEAD(ScanDateTime) OVER (PARTITION BY s.FranchiseeCode, s.CourierNumber ORDER BY s.ScanDateTime) AS NextScanTime
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_Scan_Stg2` s
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIExcludedLabels` ex
          ON SUBSTR(s.LabelNo, 1, 2) = ex.LabelPrefix AND ex.CountryName = s.CountryName
        WHERE s.ScanDate = day_rec.day_date AND s.CountryName = v_CountryName AND s.ScanType IN ('P', 'D') AND ex.LabelPrefix IS NULL
      ) s
      WHERE DATETIME_DIFF(NextScanTime, ScanDateTime, MINUTE) > 0 AND DATETIME_DIFF(NextScanTime, ScanDateTime, MINUTE) < 30
      GROUP BY FranchiseeCode, CourierNumber;

      -- 6. Break start/finish
      INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_CF_Productivity_Stg_AU`
      (WorkDate, CountryCode, RF, CF, BreakStartTime_AM, BreakStartTime_PM, BreakStartTime_TW)
      SELECT day_rec.day_date, v_CountryCode, FranchiseeCode, CourierNumber,
        IF(Cycle = 'AM', ScanDateTime, NULL), IF(Cycle = 'PM', ScanDateTime, NULL), IF(Cycle = 'TW', ScanDateTime, NULL)
      FROM (
        SELECT FranchiseeCode, CourierNumber, ScanStatus, ScanDateTime,
          CASE WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 10 THEN 'AM' WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 15 THEN 'PM' ELSE 'TW' END AS Cycle
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_Scan_Stg2` s
        WHERE s.ScanDate = day_rec.day_date AND s.CountryName = v_CountryName AND ScanStatus = 'BKS'
      ) s GROUP BY FranchiseeCode, CourierNumber, Cycle, ScanDateTime;

      -- 7. Pickups for Day
      INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_CF_Productivity_Stg_AU`
      (WorkDate, CountryCode, RF, CF, PickupsForDday, FirstPickupTime, FirstPickup_Latitude, FirstPickup_Longitude, LastPickupTime, LastPickup_Latitude, LastPickup_Longitude, ActiveCustomers)
      SELECT
        day_rec.day_date, v_CountryCode, s.FranchiseeCode, s.CourierNumber,
        COUNT(DISTINCT s.LabelNo), MIN(s.ScanDateTime), MIN(s.Latitude), MIN(s.Longitude), MAX(s.ScanDateTime), MAX(s.Latitude), MAX(s.Longitude), COUNT(DISTINCT l.FMSCustomerID)
      FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_Scan_Stg2` s
      LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIExcludedLabels` ex
        ON SUBSTR(s.LabelNo, 1, 2) = ex.LabelPrefix AND ex.CountryName = s.CountryName
      LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Label` l
        ON s.LabelNo = l.LabelNo AND s.CountryName = l.Country
      WHERE s.ScanDate = day_rec.day_date AND s.CountryName = v_CountryName AND s.ScanType = 'P' AND ex.LabelPrefix IS NULL
      GROUP BY s.FranchiseeCode, s.CourierNumber;

      -- Update global counter
      SET v_Inserted = (SELECT COUNT(*) FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_CF_Productivity_Stg_AU` WHERE WorkDate = day_rec.day_date);
      SET v_TotalInserted = v_TotalInserted + v_Inserted;

    END FOR;

    -- -----------------------------------------------------------------------
    -- Final load: aggregate Staging into CF_Productivity_AU
    -- -----------------------------------------------------------------------
    INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dbo_CF_Productivity_AU`
    (
      WorkDate, CountryCode, RF, CF, TerritoryNumber, OwnershipType,
      DeliveriesForDay, PickupsForDday, ActiveCustomers, TotalStops, FirstScanTime,
      ArrivalTime_AM, ArrivalTime_PM, ArrivalTime_TW, DepartureTime_AM, DepartureTime_PM, DepartureTime_TW,
      FirstDeliveryTime, FirstPickupTime, LastPickupTime, LastDeliveryTime,
      InDepotScan_StartTimePM, InDepotScan_FinishTimePM, 
      First_PD_DistanceTravelled, Last_PD_DistanceTravelled,
      AvergeTimeBetweenStopsMinutes, BreakStops,
      DayStartTime, DayFinishTime,
      BreakTimeMinutes, TravelTimeMinutes, TimeInDepotMinutes, TotalWorkingMinutes,
      FirstDelivery_Latitude, FirstDelivery_Longitude, LastDelivery_Latitude, LastDelivery_Longitude,
      FirstPickup_Latitude, FirstPickup_Longitude, LastPickup_Latitude, LastPickup_Longitude,
      BreakStartTime_AM, BreakStartTime_PM, BreakStartTime_TW, BreakFinishTime_AM, BreakFinishTime_PM, BreakFinishTime_TW
    )
    SELECT
      WorkDate, CountryCode, RF, CF, CAST(NULL AS INT64), CAST(NULL AS STRING),
      MIN(DeliveriesForDay), MIN(PickupsForDday), MIN(ActiveCustomers), (IFNULL(MIN(DeliveriesForDay),0) + IFNULL(MIN(PickupsForDday),0)), MIN(FirstScanTime),
      MIN(ArrivalTime_AM), MIN(ArrivalTime_PM), MIN(ArrivalTime_TW), MIN(DepartureTime_AM), MIN(DepartureTime_PM), MIN(DepartureTime_TW),
      MIN(FirstDeliveryTime), MIN(FirstPickupTime), MIN(LastPickupTime), MIN(LastDeliveryTime),
      MIN(InDepotScan_StartTime), MIN(InDepotScan_FinishTime),
      NULL, NULL,
      MIN(AvergeTimeBetweenStopsMinutes), NULL,
      NULL, NULL, 
      NULL, NULL, NULL, NULL, 
      MIN(FirstDelivery_Latitude), MIN(FirstDelivery_Longitude), MIN(LastDelivery_Latitude), MIN(LastDelivery_Longitude),
      MIN(FirstPickup_Latitude), MIN(FirstPickup_Longitude), MIN(LastPickup_Latitude), MIN(LastPickup_Longitude),
      MIN(BreakStartTime_AM), MIN(BreakStartTime_PM), MIN(BreakStartTime_TW), NULL, NULL, NULL
    FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_CF_Productivity_Stg_AU`
    GROUP BY WorkDate, CountryCode, RF, CF;

    UPDATE `{{ project_id }}.{{ target_dataset_id }}.Staging_LoadControl`
    SET LastValue = CAST(v_EndDate AS STRING)
    WHERE RecordSource = 'CF_Productivity';

    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result       = 'Failed';
    SET v_ErrorMessage = @@error.message;
  END;

  SET v_Ended = CURRENT_DATETIME();
  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(v_Component, p_ProcessId, v_Started, v_Ended, v_Result, v_ErrorMessage, v_TotalInserted, -1, -1);

END;