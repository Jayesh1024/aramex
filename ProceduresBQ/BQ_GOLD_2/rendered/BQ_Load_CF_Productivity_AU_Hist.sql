-- ==========================================================================================
-- Routine:     Load_CF_Productivity_AU_Hist
-- Description: One-shot historical load of AU CF productivity from dv_LNK_Scan.
--              No day loop, no KPI-label gate. Updates LoadControl on success.
-- Example:     CALL Staging_Load_CF_Productivity_AU_Hist(124);
-- History:
--  19/08/2023  B. Woods      Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_Load_CF_Productivity_AU_Hist`(
  IN p_ProcessId INT64
)
BEGIN

  DECLARE v_Component       STRING DEFAULT 'Staging_Load_CF_Productivity_AU_Hist';
  DECLARE v_Started         DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended           DATETIME;
  DECLARE v_Result          STRING;
  DECLARE v_ErrorMessage    STRING;
  DECLARE v_TotalInserted   INT64 DEFAULT 0;
  DECLARE v_Loaded          DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_CountryCode     INT64 DEFAULT 1;
  DECLARE v_CountryName     STRING DEFAULT 'Australia';
  DECLARE v_EndDate         DATETIME;

  TRUNCATE TABLE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CF_Productivity_Stg_AU`;
  TRUNCATE TABLE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_Stg2`;

  SET v_Loaded = CURRENT_DATETIME();
  SET v_EndDate = DATETIME_TRUNC(CURRENT_DATETIME(), DAY);

  BEGIN

    -- -----------------------------------------------------------------------
    -- Load all historical AU scans into Fact_Scan_Stg2
    -- -----------------------------------------------------------------------
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_Stg2`
    (
      LabelNo, ScanDateTime, ScanDate, ScanType, ScanStatus,
      FranchiseeCode, CourierNumber, CountryName, Latitude, Longitude
    )
    SELECT
      LabelNo, ScanDate, CAST(ScanDate AS DATE), ScanType, ScanStatus,
      FranchiseeCode, CourierNumber, CountryName, Latitude, Longitude
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Scan`
    WHERE CountryName = v_CountryName;

    -- -----------------------------------------------------------------------
    -- 1. Deliveries for Day (all work dates in one pass)
    -- -----------------------------------------------------------------------
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CF_Productivity_Stg_AU`
    (
      WorkDate, CountryCode, RF, CF, DeliveriesForDay,
      FirstDeliveryTime, FirstDelivery_Latitude, FirstDelivery_Longitude,
      LastDeliveryTime,  LastDelivery_Latitude,  LastDelivery_Longitude
    )
    SELECT
      s.ScanDate, v_CountryCode, s.FranchiseeCode, s.CourierNumber,
      COUNT(DISTINCT s.LabelNo), MIN(s.ScanDateTime), MIN(s.Latitude), MIN(s.Longitude),
      MAX(s.ScanDateTime), MAX(s.Latitude), MAX(s.Longitude)
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_Stg2` s
    LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIExcludedLabels` ex
      ON SUBSTR(s.LabelNo, 1, 2) = ex.LabelPrefix AND ex.CountryName = s.CountryName
    WHERE s.CountryName = v_CountryName AND s.ScanType = 'D' AND ex.LabelPrefix IS NULL
    GROUP BY s.ScanDate, s.FranchiseeCode, s.CourierNumber;

    -- -----------------------------------------------------------------------
    -- 2. First scan time
    -- -----------------------------------------------------------------------
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CF_Productivity_Stg_AU`
    (WorkDate, CountryCode, RF, CF, FirstScanTime)
    SELECT s.ScanDate, v_CountryCode, s.FranchiseeCode, s.CourierNumber, MIN(s.ScanDateTime)
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_Stg2` s
    WHERE s.CountryName = v_CountryName
    GROUP BY s.ScanDate, s.FranchiseeCode, s.CourierNumber;

    -- -----------------------------------------------------------------------
    -- 3. In-depot scan start (CK1)
    -- -----------------------------------------------------------------------
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CF_Productivity_Stg_AU`
    (WorkDate, CountryCode, RF, CF, ArrivalTime_AM, ArrivalTime_PM, ArrivalTime_TW, InDepotScan_StartTime)
    SELECT
      ScanDate, v_CountryCode, FranchiseeCode, CourierNumber,
      IF(Cycle = 'AM', ScanDateTime, NULL), IF(Cycle = 'PM', ScanDateTime, NULL), IF(Cycle = 'TW', ScanDateTime, NULL),
      IF(Cycle = 'PM', MAX(NextScanTime), NULL)
    FROM (
      SELECT s.ScanDate, FranchiseeCode, CourierNumber, ScanStatus, ScanDateTime,
        CASE WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 10 THEN 'AM' WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 15 THEN 'PM' ELSE 'TW' END AS Cycle,
        LEAD(ScanDateTime) OVER (
          PARTITION BY s.FranchiseeCode, s.CourierNumber, s.ScanDate
          ORDER BY s.ScanDateTime
        ) AS NextScanTime
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_Stg2` s
      WHERE s.CountryName = v_CountryName
    ) s
    WHERE ScanStatus = 'CK1'
    GROUP BY ScanDate, FranchiseeCode, CourierNumber, Cycle, ScanDateTime;

    -- -----------------------------------------------------------------------
    -- 4. In-depot scan finish (CK2)
    -- -----------------------------------------------------------------------
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CF_Productivity_Stg_AU`
    (WorkDate, CountryCode, RF, CF, DepartureTime_AM, DepartureTime_PM, DepartureTime_TW, InDepotScan_FinishTime)
    SELECT
      ScanDate, v_CountryCode, FranchiseeCode, CourierNumber,
      IF(Cycle = 'AM', ScanDateTime, NULL), IF(Cycle = 'PM', ScanDateTime, NULL), IF(Cycle = 'TW', ScanDateTime, NULL),
      IF(Cycle = 'PM', MAX(PreviousScanTime), NULL)
    FROM (
      SELECT s.ScanDate, FranchiseeCode, CourierNumber, ScanStatus, ScanDateTime,
        CASE WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 10 THEN 'AM' WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 15 THEN 'PM' ELSE 'TW' END AS Cycle,
        LAG(ScanDateTime) OVER (
          PARTITION BY s.FranchiseeCode, s.CourierNumber, s.ScanDate
          ORDER BY s.ScanDateTime
        ) AS PreviousScanTime
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_Stg2` s
      WHERE s.CountryName = v_CountryName
    ) ss
    WHERE ScanStatus = 'CK2'
    GROUP BY ScanDate, FranchiseeCode, CourierNumber, Cycle, ScanDateTime;

    -- -----------------------------------------------------------------------
    -- 5. Average time between stops
    -- -----------------------------------------------------------------------
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CF_Productivity_Stg_AU`
    (WorkDate, CountryCode, RF, CF, AvergeTimeBetweenStopsMinutes)
    SELECT ScanDate, v_CountryCode, FranchiseeCode, CourierNumber, CAST(AVG(DATETIME_DIFF(NextScanTime, ScanDateTime, MINUTE)) AS INT64)
    FROM (
      SELECT s.ScanDate, FranchiseeCode, CourierNumber, ScanDateTime,
        LEAD(ScanDateTime) OVER (
          PARTITION BY s.FranchiseeCode, s.CourierNumber, s.ScanDate
          ORDER BY s.ScanDateTime
        ) AS NextScanTime
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_Stg2` s
      LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIExcludedLabels` ex
        ON SUBSTR(s.LabelNo, 1, 2) = ex.LabelPrefix AND ex.CountryName = s.CountryName
      WHERE s.CountryName = v_CountryName AND s.ScanType IN ('P', 'D') AND ex.LabelPrefix IS NULL
    ) s
    WHERE DATETIME_DIFF(NextScanTime, ScanDateTime, MINUTE) > 0 AND DATETIME_DIFF(NextScanTime, ScanDateTime, MINUTE) < 30
    GROUP BY ScanDate, FranchiseeCode, CourierNumber;

    -- -----------------------------------------------------------------------
    -- 6. Break start
    -- -----------------------------------------------------------------------
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CF_Productivity_Stg_AU`
    (WorkDate, CountryCode, RF, CF, BreakStartTime_AM, BreakStartTime_PM, BreakStartTime_TW)
    SELECT
      ScanDate, v_CountryCode, FranchiseeCode, CourierNumber,
      IF(Cycle = 'AM', ScanDateTime, NULL), IF(Cycle = 'PM', ScanDateTime, NULL), IF(Cycle = 'TW', ScanDateTime, NULL)
    FROM (
      SELECT s.ScanDate, FranchiseeCode, CourierNumber, ScanStatus, ScanDateTime,
        CASE WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 10 THEN 'AM' WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 15 THEN 'PM' ELSE 'TW' END AS Cycle
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_Stg2` s
      WHERE s.CountryName = v_CountryName AND ScanStatus = 'BKS'
    ) s
    GROUP BY ScanDate, FranchiseeCode, CourierNumber, Cycle, ScanDateTime;

    -- -----------------------------------------------------------------------
    -- 7. Pickups for Day
    -- -----------------------------------------------------------------------
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CF_Productivity_Stg_AU`
    (WorkDate, CountryCode, RF, CF, PickupsForDday, FirstPickupTime, FirstPickup_Latitude, FirstPickup_Longitude, LastPickupTime, LastPickup_Latitude, LastPickup_Longitude, ActiveCustomers)
    SELECT
      s.ScanDate, v_CountryCode, s.FranchiseeCode, s.CourierNumber,
      COUNT(DISTINCT s.LabelNo), MIN(s.ScanDateTime), MIN(s.Latitude), MIN(s.Longitude),
      MAX(s.ScanDateTime), MAX(s.Latitude), MAX(s.Longitude), COUNT(DISTINCT l.FMSCustomerID)
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_Stg2` s
    LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIExcludedLabels` ex
      ON SUBSTR(s.LabelNo, 1, 2) = ex.LabelPrefix AND ex.CountryName = s.CountryName
    LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label` l
      ON s.LabelNo = l.LabelNo AND s.CountryName = l.Country
    WHERE s.CountryName = v_CountryName AND s.ScanType = 'P' AND ex.LabelPrefix IS NULL
    GROUP BY s.ScanDate, s.FranchiseeCode, s.CourierNumber;

    -- -----------------------------------------------------------------------
    -- Final load: aggregate Staging into CF_Productivity_AU
    -- -----------------------------------------------------------------------
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_CF_Productivity_AU`
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
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CF_Productivity_Stg_AU`
    GROUP BY WorkDate, CountryCode, RF, CF;

    SET v_TotalInserted = @@row_count;

    UPDATE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_LoadControl`
    SET LastValue = CAST(v_EndDate AS STRING)
    WHERE RecordSource = 'CF_Productivity';

    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result       = 'Failed';
    SET v_ErrorMessage = @@error.message;
  END;

  SET v_Ended = CURRENT_DATETIME();
  CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(v_Component, p_ProcessId, v_Started, v_Ended, v_Result, v_ErrorMessage, v_TotalInserted, -1, -1);

END;
