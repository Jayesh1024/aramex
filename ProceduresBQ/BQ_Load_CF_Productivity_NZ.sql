-- ==========================================================================================
-- Routine:     Load_Fact_Scan_KPI_Stg
-- Description: Recalc scan KPI stats for Labels that have just arrived
-- Example:     Exec [Staging].[Load_CF_Productivity_Stg] 124
-- History:
--  19/08/2023  B. Woods      Routine Written

-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `project.staging.Load_CF_Productivity_NZ`(
  IN p_ProcessId INT64
)
BEGIN

  DECLARE v_Component       STRING DEFAULT 'staging.Load_CF_Productivity_NZ';
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
  DECLARE v_LastId          INT64;
  -- DECLARE v_CutOffDate DATETIME DEFAULT '2022-11-30T23:59:59'; -- declared but unused in original

  -- -----------------------------------------------------------------------
  -- Early exit if no rows to process
  -- -----------------------------------------------------------------------
  SET v_LastId = (SELECT IFNULL(MAX(ID), 0) FROM `project.staging.KPI_Labels_Stg`);

  IF v_LastId = 0 THEN
    CREATE TEMP TABLE Results AS SELECT 'Success - No rows to process' AS ExecutionResult;
    RETURN;
  END IF;

  -- -----------------------------------------------------------------------
  -- Resolve date window from LoadControl
  -- -----------------------------------------------------------------------
  SELECT CAST(LastValue AS DATETIME)
  INTO v_StartDate
  FROM `project.staging.LoadControl`
  WHERE RecordSource = 'CF_Productivity_NZ';

  SET v_EndDate = DATETIME_ADD(v_StartDate, INTERVAL 1 DAY);

  -- -----------------------------------------------------------------------
  -- Truncate staging targets
  -- -----------------------------------------------------------------------
  TRUNCATE TABLE `project.staging.CF_Productivity_Stg_NZ`;
  TRUNCATE TABLE `project.staging.Fact_Scan_Stg2_NZ`;

  SET v_Loaded = CURRENT_DATETIME();

  BEGIN

    -- -----------------------------------------------------------------------
    -- Load scan window into Fact_Scan_Stg2_NZ
    -- DROP/CREATE INDEX omitted — BQ manages clustering natively
    -- -----------------------------------------------------------------------
    INSERT INTO `project.staging.Fact_Scan_Stg2_NZ`
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
    FROM `project.dv.LNK_Scan`
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

      -- ---------------------------------------------------------------------
      -- Deliveries for Day
      -- ---------------------------------------------------------------------
      INSERT INTO `project.staging.CF_Productivity_Stg_NZ`
      (
        WorkDate, CountryCode, RF, CF,
        DeliveriesForDay,
        FirstDeliveryTime, FirstDelivery_Latitude, FirstDelivery_Longitude,
        LastDeliveryTime,  LastDelivery_Latitude,  LastDelivery_Longitude
      )
      SELECT
        day_rec.day_date, v_CountryCode, s.FranchiseeCode, s.CourierNumber,
        COUNT(DISTINCT s.LabelNo)   AS DeliveriesForDay,
        MIN(s.ScanDateTime)         AS FirstDeliveryTime,
        MIN(s.Latitude)             AS FirstDelivery_Latitude,
        MIN(s.Longitude)            AS FirstDelivery_Longitude,
        MAX(s.ScanDateTime)         AS LastDeliveryTime,
        MAX(s.Latitude)             AS LastDelivery_Latitude,
        MAX(s.Longitude)            AS LastDelivery_Longitude
      FROM `project.staging.Fact_Scan_Stg2_NZ` s
      LEFT JOIN `project.dbo.KPIExcludedLabels` ex
        ON SUBSTR(s.LabelNo, 1, 2) = ex.LabelPrefix
       AND ex.CountryName          = s.CountryName
      WHERE s.ScanDate    = day_rec.day_date
        AND s.CountryName = v_CountryName
        AND s.ScanType    = 'D'
        AND ex.LabelPrefix IS NULL
      GROUP BY s.FranchiseeCode, s.CourierNumber;

      -- ---------------------------------------------------------------------
      -- First scan time
      -- ---------------------------------------------------------------------
      INSERT INTO `project.staging.CF_Productivity_Stg_NZ`
      (WorkDate, CountryCode, RF, CF, FirstScanTime)
      SELECT
        day_rec.day_date, v_CountryCode, s.FranchiseeCode, s.CourierNumber,
        MIN(s.ScanDateTime) AS FirstScanTime
      FROM `project.staging.Fact_Scan_Stg2_NZ` s
      WHERE s.ScanDate    = day_rec.day_date
        AND s.CountryName = v_CountryName
      GROUP BY s.FranchiseeCode, s.CourierNumber;

      -- ---------------------------------------------------------------------
      -- In-depot scan start time (B87 — NZ equivalent of CK1)
      -- ---------------------------------------------------------------------
      INSERT INTO `project.staging.CF_Productivity_Stg_NZ`
      (
        WorkDate, CountryCode, RF, CF,
        ArrivalTime_AM, ArrivalTime_PM, ArrivalTime_TW,
        InDepotScan_StartTime
      )
      SELECT
        day_rec.day_date, v_CountryCode, FranchiseeCode, CourierNumber,
        IF(Cycle = 'AM', ScanDateTime, NULL) AS ArrivalTime_AM,
        IF(Cycle = 'PM', ScanDateTime, NULL) AS ArrivalTime_PM,
        IF(Cycle = 'TW', ScanDateTime, NULL) AS ArrivalTime_TW,
        IF(Cycle = 'PM', MAX(NextScanTime), NULL) AS InDepotScan_StartTime
      FROM (
        SELECT
          FranchiseeCode, CourierNumber, ScanStatus,
          CASE
            WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 10 THEN 'AM'
            WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 15 THEN 'PM'
            ELSE 'TW'
          END AS Cycle,
          ScanDateTime,
          LEAD(ScanDateTime) OVER (
            PARTITION BY s.FranchiseeCode, s.CourierNumber
            ORDER BY s.ScanDateTime
          ) AS NextScanTime
        FROM `project.staging.Fact_Scan_Stg2_NZ` s
        WHERE s.ScanDate    = day_rec.day_date
          AND s.CountryName = v_CountryName
      ) s
      WHERE ScanStatus = 'B87'  -- NZ check-in code (AU uses CK1)
      GROUP BY FranchiseeCode, CourierNumber, Cycle, ScanDateTime;

      -- ---------------------------------------------------------------------
      -- In-depot scan finish time (B88 — NZ equivalent of CK2)
      -- ---------------------------------------------------------------------
      INSERT INTO `project.staging.CF_Productivity_Stg_NZ`
      (
        WorkDate, CountryCode, RF, CF,
        DepartureTime_AM, DepartureTime_PM, DepartureTime_TW,
        InDepotScan_FinishTime
      )
      SELECT
        day_rec.day_date, v_CountryCode, FranchiseeCode, CourierNumber,
        IF(Cycle = 'AM', ScanDateTime, NULL) AS DepartureTime_AM,
        IF(Cycle = 'PM', ScanDateTime, NULL) AS DepartureTime_PM,
        IF(Cycle = 'TW', ScanDateTime, NULL) AS DepartureTime_TW,
        IF(Cycle = 'PM', MAX(PreviousScanTime), NULL) AS InDepotScan_FinishTime
      FROM (
        SELECT
          FranchiseeCode, CourierNumber, ScanStatus,
          CASE
            WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 10 THEN 'AM'
            WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 15 THEN 'PM'
            ELSE 'TW'
          END AS Cycle,
          ScanDateTime,
          LAG(ScanDateTime) OVER (
            PARTITION BY s.FranchiseeCode, s.CourierNumber
            ORDER BY s.ScanDateTime
          ) AS PreviousScanTime
        FROM `project.staging.Fact_Scan_Stg2_NZ` s
        WHERE s.ScanDate    = day_rec.day_date
          AND s.CountryName = v_CountryName
      ) ss
      WHERE ScanStatus = 'B88'  -- NZ check-out code (AU uses CK2)
      GROUP BY FranchiseeCode, CourierNumber, Cycle, ScanDateTime;

      -- ---------------------------------------------------------------------
      -- Average time between stops (< 30 min)
      -- ---------------------------------------------------------------------
      INSERT INTO `project.staging.CF_Productivity_Stg_NZ`
      (WorkDate, CountryCode, RF, CF, AvergeTimeBetweenStopsMinutes)
      SELECT
        day_rec.day_date, v_CountryCode, FranchiseeCode, CourierNumber,
        AVG(DATETIME_DIFF(NextScanTime, ScanDateTime, MINUTE)) AS TimeBetweenStops
      FROM (
        SELECT
          FranchiseeCode, CourierNumber,
          ScanDateTime,
          LEAD(ScanDateTime) OVER (
            PARTITION BY s.FranchiseeCode, s.CourierNumber
            ORDER BY s.ScanDateTime
          ) AS NextScanTime
        FROM `project.staging.Fact_Scan_Stg2_NZ` s
        LEFT JOIN `project.dbo.KPIExcludedLabels` ex
          ON SUBSTR(s.LabelNo, 1, 2) = ex.LabelPrefix
         AND ex.CountryName          = s.CountryName
        WHERE s.ScanDate    = day_rec.day_date
          AND s.CountryName = v_CountryName
          AND s.ScanType    IN ('P', 'D')
          AND ex.LabelPrefix IS NULL
      ) s
      WHERE DATETIME_DIFF(NextScanTime, ScanDateTime, MINUTE) > 0
        AND DATETIME_DIFF(NextScanTime, ScanDateTime, MINUTE) < 30
      GROUP BY FranchiseeCode, CourierNumber;

      -- ---------------------------------------------------------------------
      -- Average time between stops (all gaps)
      -- ---------------------------------------------------------------------
      INSERT INTO `project.staging.CF_Productivity_Stg_NZ`
      (WorkDate, CountryCode, RF, CF, AvergeTimeBetweenStopsMinutes)
      SELECT
        day_rec.day_date, v_CountryCode, FranchiseeCode, CourierNumber,
        AVG(DATETIME_DIFF(NextScanTime, ScanDateTime, MINUTE)) AS TimeBetweenStops
      FROM (
        SELECT
          FranchiseeCode, CourierNumber,
          ScanDateTime,
          LEAD(ScanDateTime) OVER (
            PARTITION BY s.FranchiseeCode, s.CourierNumber
            ORDER BY s.ScanDateTime
          ) AS NextScanTime
        FROM `project.staging.Fact_Scan_Stg2_NZ` s
        LEFT JOIN `project.dbo.KPIExcludedLabels` ex
          ON SUBSTR(s.LabelNo, 1, 2) = ex.LabelPrefix
         AND ex.CountryName          = s.CountryName
        WHERE s.ScanDate    = day_rec.day_date
          AND s.CountryName = v_CountryName
          AND s.ScanType    IN ('P', 'D')
          AND ex.LabelPrefix IS NULL
      ) s
      GROUP BY FranchiseeCode, CourierNumber;

      -- ---------------------------------------------------------------------
      -- Break stops (gaps > 30 minutes)
      -- ---------------------------------------------------------------------
      INSERT INTO `project.staging.CF_Productivity_Stg_NZ`
      (WorkDate, CountryCode, RF, CF, BreakStops)
      SELECT
        day_rec.day_date, v_CountryCode, FranchiseeCode, CourierNumber,
        COUNT(*) AS BreakStops
      FROM (
        SELECT
          FranchiseeCode, CourierNumber,
          ScanDateTime,
          LEAD(ScanDateTime) OVER (
            PARTITION BY s.FranchiseeCode, s.CourierNumber
            ORDER BY s.ScanDateTime
          ) AS NextScanTime
        FROM `project.staging.Fact_Scan_Stg2_NZ` s
        LEFT JOIN `project.dbo.KPIExcludedLabels` ex
          ON SUBSTR(s.LabelNo, 1, 2) = ex.LabelPrefix
         AND ex.CountryName          = s.CountryName
        WHERE s.ScanDate    = day_rec.day_date
          AND s.CountryName = v_CountryName
          AND s.ScanType    IN ('P', 'D')
          AND ex.LabelPrefix IS NULL
      ) AS A
      WHERE DATETIME_DIFF(NextScanTime, ScanDateTime, MINUTE) > 30
      GROUP BY FranchiseeCode, CourierNumber;

      -- ---------------------------------------------------------------------
      -- Pickups for Day
      -- ---------------------------------------------------------------------
      INSERT INTO `project.staging.CF_Productivity_Stg_NZ`
      (
        WorkDate, CountryCode, RF, CF,
        PickupsForDday,
        FirstPickupTime,  FirstPickup_Latitude,  FirstPickup_Longitude,
        LastPickupTime,   LastPickup_Latitude,   LastPickup_Longitude,
        ActiveCustomers
      )
      SELECT
        day_rec.day_date, v_CountryCode, s.FranchiseeCode, s.CourierNumber,
        COUNT(DISTINCT s.LabelNo)       AS PickupsForDday,
        MIN(s.ScanDateTime)             AS FirstPickupTime,
        MIN(s.Latitude)                 AS FirstPickup_Latitude,
        MIN(s.Longitude)                AS FirstPickup_Longitude,
        MAX(s.ScanDateTime)             AS LastPickupTime,
        MAX(s.Latitude)                 AS LastPickup_Latitude,
        MAX(s.Longitude)                AS LastPickup_Longitude,
        COUNT(DISTINCT l.FMSCustomerID) AS ActiveCustomers
      FROM `project.staging.Fact_Scan_Stg2_NZ` s
      LEFT JOIN `project.dbo.KPIExcludedLabels` ex
        ON SUBSTR(s.LabelNo, 1, 2) = ex.LabelPrefix
       AND ex.CountryName          = s.CountryName
      LEFT JOIN `project.dbo.Dim_Label` l
        ON s.LabelNo     = l.LabelNo
       AND s.CountryName = l.Country
      WHERE s.ScanDate    = day_rec.day_date
        AND s.CountryName = v_CountryName
        AND s.ScanType    = 'P'
        AND ex.LabelPrefix IS NULL
      GROUP BY s.FranchiseeCode, s.CourierNumber;

      SET v_TotalInserted = v_TotalInserted + v_Inserted;
      SET v_Inserted = 0;

    END FOR;

    -- -----------------------------------------------------------------------
    -- Final load: aggregate staging into CF_Productivity_NZ
    -- Note: NZ target omits BreakStartTime/BreakFinishTime columns
    -- -----------------------------------------------------------------------
    INSERT INTO `project.dbo.CF_Productivity_NZ`
    (
      WorkDate, CountryCode, RF, CF,
      TerritoryNumber, OwnershipType,
      DeliveriesForDay, PickupsForDday, ActiveCustomers, TotalStops,
      FirstScanTime,
      ArrivalTime_AM,   ArrivalTime_PM,   ArrivalTime_TW,
      DepartureTime_AM, DepartureTime_PM, DepartureTime_TW,
      FirstDeliveryTime, FirstPickupTime, LastPickupTime, LastDeliveryTime,
      InDepotScan_StartTimePM, InDepotScan_FinishTimePM,
      First_PD_DistanceTravelled, Last_PD_DistanceTravelled,
      AvergeTimeBetweenStopsMinutes, BreakStops,
      DayStartTime, DayFinishTime,
      BreakTimeMinutes, TravelTimeMinutes, TimeInDepotMinutes, TotalWorkingMinutes,
      FirstDelivery_Latitude,  FirstDelivery_Longitude,
      LastDelivery_Latitude,   LastDelivery_Longitude,
      FirstPickup_Latitude,    FirstPickup_Longitude,
      LastPickup_Latitude,     LastPickup_Longitude
    )
    SELECT
      WorkDate, CountryCode, RF, CF,
      MIN(TerritoryNumber)                AS TerritoryNumber,
      MIN(OwnershipType)                  AS OwnershipType,
      MIN(DeliveriesForDay)               AS DeliveriesForDay,
      MIN(PickupsForDday)                 AS PickupsForDday,
      MIN(ActiveCustomers)                AS ActiveCustomers,
      MIN(TotalStops)                     AS TotalStops,
      MIN(FirstScanTime)                  AS FirstScanTime,
      MIN(ArrivalTime_AM)                 AS ArrivalTime_AM,
      MIN(ArrivalTime_PM)                 AS ArrivalTime_PM,
      MIN(ArrivalTime_TW)                 AS ArrivalTime_TW,
      MIN(DepartureTime_AM)               AS DepartureTime_AM,
      MIN(DepartureTime_PM)               AS DepartureTime_PM,
      MIN(DepartureTime_TW)               AS DepartureTime_TW,
      MIN(FirstDeliveryTime)              AS FirstDeliveryTime,
      MIN(FirstPickupTime)                AS FirstPickupTime,
      MIN(LastPickupTime)                 AS LastPickupTime,
      MIN(LastDeliveryTime)               AS LastDeliveryTime,
      MIN(InDepotScan_StartTime)          AS InDepotScan_StartTimePM,
      MIN(InDepotScan_FinishTime)         AS InDepotScan_FinishTimePM,
      MIN(First_PD_DistanceTravelled)     AS First_PD_DistanceTravelled,
      MIN(Last_PD_DistanceTravelled)      AS Last_PD_DistanceTravelled,
      MIN(AvergeTimeBetweenStopsMinutes)  AS AvergeTimeBetweenStopsMinutes,
      MIN(BreakStops)                     AS BreakStops,
      MIN(DayStartTime)                   AS DayStartTime,
      MIN(DayFinishTime)                  AS DayFinishTime,
      MIN(BreakTimeMinutes)               AS BreakTimeMinutes,
      MIN(TravelTimeMinutes)              AS TravelTimeMinutes,
      MIN(TimeInDepotMinutes)             AS TimeInDepotMinutes,
      MIN(TotalWorkingMinutes)            AS TotalWorkingMinutes,
      MIN(FirstDelivery_Latitude)         AS FirstDelivery_Latitude,
      MIN(FirstDelivery_Longitude)        AS FirstDelivery_Longitude,
      MIN(LastDelivery_Latitude)          AS LastDelivery_Latitude,
      MIN(LastDelivery_Longitude)         AS LastDelivery_Longitude,
      MIN(FirstPickup_Latitude)           AS FirstPickup_Latitude,
      MIN(FirstPickup_Longitude)          AS FirstPickup_Longitude,
      MIN(LastPickup_Latitude)            AS LastPickup_Latitude,
      MIN(LastPickup_Longitude)           AS LastPickup_Longitude
    FROM `project.staging.CF_Productivity_Stg_NZ`
    GROUP BY WorkDate, CountryCode, RF, CF;

    -- -----------------------------------------------------------------------
    -- Advance LoadControl
    -- -----------------------------------------------------------------------
    UPDATE `project.staging.LoadControl`
    SET LastValue = CAST(v_EndDate AS STRING)
    WHERE RecordSource = 'CF_Productivity_NZ';

    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result       = 'Failed';
    SET v_ErrorMessage = @@error.message;

  END;

  -- -----------------------------------------------------------------------
  -- Record load metrics in log
  -- -----------------------------------------------------------------------
  SET v_Ended = CURRENT_DATETIME();

  CALL `project.staging.SaveLog`(
    v_Component,
    p_ProcessId,
    v_Started,
    v_Ended,
    v_Result,
    v_ErrorMessage,
    v_TotalInserted,
    -1,
    -1
  );

END;