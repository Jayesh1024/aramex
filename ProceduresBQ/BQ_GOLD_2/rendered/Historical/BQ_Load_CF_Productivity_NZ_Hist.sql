-- ==========================================================================================
-- Routine:     Load_CF_Productivity_NZ_Hist
-- Description: One-shot historical load of NZ CF productivity from dv_LNK_Scan.
--              No day loop, no KPI-label gate. Updates LoadControl on success.
-- Example:     CALL Staging_Load_CF_Productivity_NZ_Hist(124);
-- History:
--  19/08/2023  B. Woods      Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_Load_CF_Productivity_NZ_Hist`(
  IN p_ProcessId INT64
)
BEGIN

  DECLARE v_Component       STRING DEFAULT 'Staging_Load_CF_Productivity_NZ_Hist';
  DECLARE v_Started         DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended           DATETIME;
  DECLARE v_Result          STRING;
  DECLARE v_ErrorMessage    STRING;
  DECLARE v_TotalInserted   INT64 DEFAULT 0;
  DECLARE v_Loaded          DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_CountryCode     INT64 DEFAULT 6;
  DECLARE v_CountryName     STRING DEFAULT 'New Zealand';
  DECLARE v_EndDate         DATETIME;

  TRUNCATE TABLE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CF_Productivity_Stg_NZ`;
  TRUNCATE TABLE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_Stg2_NZ`;

  SET v_Loaded = CURRENT_DATETIME();
  SET v_EndDate = DATETIME_TRUNC(CURRENT_DATETIME(), DAY);

  BEGIN

    -- -----------------------------------------------------------------------
    -- Load all historical NZ scans into Fact_Scan_Stg2_NZ
    -- -----------------------------------------------------------------------
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_Stg2_NZ`
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
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Scan`
    WHERE UPPER(CountryName) = UPPER(v_CountryName);

    -- -----------------------------------------------------------------------
    -- 1. Deliveries for Day (all work dates in one pass)
    -- -----------------------------------------------------------------------
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CF_Productivity_Stg_NZ`
    (
      WorkDate, CountryCode, RF, CF, DeliveriesForDay,
      FirstDeliveryTime, FirstDelivery_Latitude, FirstDelivery_Longitude,
      LastDeliveryTime,  LastDelivery_Latitude,  LastDelivery_Longitude
    )
    SELECT
      s.ScanDate, v_CountryCode, s.FranchiseeCode, s.CourierNumber,
      COUNT(DISTINCT s.LabelNo), MIN(s.ScanDateTime), MIN(s.Latitude), MIN(s.Longitude),
      MAX(s.ScanDateTime), MAX(s.Latitude), MAX(s.Longitude)
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_Stg2_NZ` s
    LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIExcludedLabels` ex
      ON SUBSTR(s.LabelNo, 1, 2) = ex.LabelPrefix AND ex.CountryName = s.CountryName
    WHERE UPPER(s.CountryName) = UPPER(v_CountryName) AND UPPER(s.ScanType) = 'D' AND ex.LabelPrefix IS NULL
    GROUP BY s.ScanDate, s.FranchiseeCode, s.CourierNumber;

    -- -----------------------------------------------------------------------
    -- 2. First scan time
    -- -----------------------------------------------------------------------
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CF_Productivity_Stg_NZ`
    (WorkDate, CountryCode, RF, CF, FirstScanTime)
    SELECT s.ScanDate, v_CountryCode, s.FranchiseeCode, s.CourierNumber, MIN(s.ScanDateTime)
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_Stg2_NZ` s
    WHERE UPPER(s.CountryName) = UPPER(v_CountryName)
    GROUP BY s.ScanDate, s.FranchiseeCode, s.CourierNumber;

    -- -----------------------------------------------------------------------
    -- 3. In-depot scan start time (B87)
    -- -----------------------------------------------------------------------
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CF_Productivity_Stg_NZ`
    (WorkDate, CountryCode, RF, CF, ArrivalTime_AM, ArrivalTime_PM, ArrivalTime_TW, InDepotScan_StartTime)
    SELECT
      ScanDate, v_CountryCode, FranchiseeCode, CourierNumber,
      MAX(IF(UPPER(Cycle) = 'AM', ScanDateTime, NULL)),
      MAX(IF(UPPER(Cycle) = 'PM', ScanDateTime, NULL)),
      MAX(IF(UPPER(Cycle) = 'TW', ScanDateTime, NULL)),
      MAX(IF(UPPER(Cycle) = 'PM', NextScanTime, NULL))
    FROM (
      SELECT s.ScanDate, FranchiseeCode, CourierNumber, ScanStatus, ScanDateTime,
        CASE WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 10 THEN 'AM' WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 15 THEN 'PM' ELSE 'TW' END AS Cycle,
        LEAD(ScanDateTime) OVER (
          PARTITION BY s.FranchiseeCode, s.CourierNumber, s.ScanDate
          ORDER BY s.ScanDateTime
        ) AS NextScanTime
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_Stg2_NZ` s
      WHERE UPPER(s.CountryName) = UPPER(v_CountryName)
    ) s
    WHERE UPPER(ScanStatus) = 'B87'
    GROUP BY ScanDate, FranchiseeCode, CourierNumber;

    -- -----------------------------------------------------------------------
    -- 4. In-depot scan finish time (B88)
    -- -----------------------------------------------------------------------
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CF_Productivity_Stg_NZ`
    (WorkDate, CountryCode, RF, CF, DepartureTime_AM, DepartureTime_PM, DepartureTime_TW, InDepotScan_FinishTime)
    SELECT
      ScanDate, v_CountryCode, FranchiseeCode, CourierNumber,
      MAX(IF(UPPER(Cycle) = 'AM', ScanDateTime, NULL)),
      MAX(IF(UPPER(Cycle) = 'PM', ScanDateTime, NULL)),
      MAX(IF(UPPER(Cycle) = 'TW', ScanDateTime, NULL)),
      MAX(IF(UPPER(Cycle) = 'PM', PreviousScanTime, NULL))
    FROM (
      SELECT s.ScanDate, FranchiseeCode, CourierNumber, ScanStatus, ScanDateTime,
        CASE WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 10 THEN 'AM' WHEN EXTRACT(HOUR FROM s.ScanDateTime) < 15 THEN 'PM' ELSE 'TW' END AS Cycle,
        LAG(ScanDateTime) OVER (
          PARTITION BY s.FranchiseeCode, s.CourierNumber, s.ScanDate
          ORDER BY s.ScanDateTime
        ) AS PreviousScanTime
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_Stg2_NZ` s
      WHERE UPPER(s.CountryName) = UPPER(v_CountryName)
    ) ss
    WHERE UPPER(ScanStatus) = 'B88'
    GROUP BY ScanDate, FranchiseeCode, CourierNumber;

    -- -----------------------------------------------------------------------
    -- 5. Average time between stops (< 30 min)
    -- -----------------------------------------------------------------------
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CF_Productivity_Stg_NZ`
    (WorkDate, CountryCode, RF, CF, AvergeTimeBetweenStopsMinutes)
    SELECT
      ScanDate, v_CountryCode, FranchiseeCode, CourierNumber,
      CAST(AVG(DATETIME_DIFF(NextScanTime, ScanDateTime, MINUTE)) AS INT64)
    FROM (
      SELECT s.ScanDate, FranchiseeCode, CourierNumber, ScanDateTime,
        LEAD(ScanDateTime) OVER (
          PARTITION BY s.FranchiseeCode, s.CourierNumber, s.ScanDate
          ORDER BY s.ScanDateTime
        ) AS NextScanTime
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_Stg2_NZ` s
      LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIExcludedLabels` ex
        ON SUBSTR(s.LabelNo, 1, 2) = ex.LabelPrefix AND ex.CountryName = s.CountryName
      WHERE UPPER(s.CountryName) = UPPER(v_CountryName) AND UPPER(s.ScanType) IN ('P', 'D') AND ex.LabelPrefix IS NULL
    ) s
    WHERE DATETIME_DIFF(NextScanTime, ScanDateTime, MINUTE) BETWEEN 1 AND 29
    GROUP BY ScanDate, FranchiseeCode, CourierNumber;

    -- -----------------------------------------------------------------------
    -- 6. Break stops (gaps > 30 minutes)
    -- -----------------------------------------------------------------------
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CF_Productivity_Stg_NZ`
    (WorkDate, CountryCode, RF, CF, BreakStops)
    SELECT ScanDate, v_CountryCode, FranchiseeCode, CourierNumber, COUNT(*)
    FROM (
      SELECT s.ScanDate, FranchiseeCode, CourierNumber, ScanDateTime,
        LEAD(ScanDateTime) OVER (
          PARTITION BY s.FranchiseeCode, s.CourierNumber, s.ScanDate
          ORDER BY s.ScanDateTime
        ) AS NextScanTime
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_Stg2_NZ` s
      LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIExcludedLabels` ex
        ON SUBSTR(s.LabelNo, 1, 2) = ex.LabelPrefix AND ex.CountryName = s.CountryName
      WHERE UPPER(s.CountryName) = UPPER(v_CountryName) AND UPPER(s.ScanType) IN ('P', 'D') AND ex.LabelPrefix IS NULL
    ) AS A
    WHERE DATETIME_DIFF(NextScanTime, ScanDateTime, MINUTE) > 30
    GROUP BY ScanDate, FranchiseeCode, CourierNumber;

    -- -----------------------------------------------------------------------
    -- 7. Pickups for Day
    -- -----------------------------------------------------------------------
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CF_Productivity_Stg_NZ`
    (WorkDate, CountryCode, RF, CF, PickupsForDday, FirstPickupTime, FirstPickup_Latitude, FirstPickup_Longitude, LastPickupTime, LastPickup_Latitude, LastPickup_Longitude, ActiveCustomers)
    SELECT
      s.ScanDate, v_CountryCode, s.FranchiseeCode, s.CourierNumber,
      COUNT(DISTINCT s.LabelNo), MIN(s.ScanDateTime), MIN(s.Latitude), MIN(s.Longitude),
      MAX(s.ScanDateTime), MAX(s.Latitude), MAX(s.Longitude), COUNT(DISTINCT l.FMSCustomerID)
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_Stg2_NZ` s
    LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIExcludedLabels` ex
      ON SUBSTR(s.LabelNo, 1, 2) = ex.LabelPrefix AND ex.CountryName = s.CountryName
    LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label` l
      ON s.LabelNo = l.LabelNo AND s.CountryName = l.Country
    WHERE UPPER(s.CountryName) = UPPER(v_CountryName) AND UPPER(s.ScanType) = 'P' AND ex.LabelPrefix IS NULL
    GROUP BY s.ScanDate, s.FranchiseeCode, s.CourierNumber;

    -- -----------------------------------------------------------------------
    -- Final load: aggregate Staging into CF_Productivity_NZ
    -- -----------------------------------------------------------------------
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_CF_Productivity_NZ`
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
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CF_Productivity_Stg_NZ`
    GROUP BY WorkDate, CountryCode, RF, CF;

    SET v_TotalInserted = @@row_count;

    UPDATE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_LoadControl`
    SET LastValue = CAST(v_EndDate AS STRING)
    WHERE UPPER(RecordSource) = UPPER('CF_Productivity_NZ');

    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result       = 'Failed';
    SET v_ErrorMessage = @@error.message;
  END;

  SET v_Ended = CURRENT_DATETIME();
  CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
    v_Component, p_ProcessId, v_Started, v_Ended, v_Result, v_ErrorMessage, v_TotalInserted, -1, -1
  );

END;
