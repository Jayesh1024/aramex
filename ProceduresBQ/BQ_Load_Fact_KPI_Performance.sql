-- ==========================================================================================
-- Routine:     Load_Fact_KPI_Performance
-- Description: Maintains the stats for InterBranch Pickup & Delivery KPIs
-- Example:     Exec [dbo].[Load_Fact_KPI_Performance] 30
-- History:
-- 30/01/2023   B. Woods        Routine Written
--
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ dataset_id }}.dbo.Load_Fact_KPI_Performance`(
  IN p_ProcessId INT64
)
BEGIN

  DECLARE v_Component     STRING DEFAULT 'dbo.Load_Fact_KPI_Performance';
  DECLARE v_Step          STRING DEFAULT 'Inserts';
  DECLARE v_Started       DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended         DATETIME;
  DECLARE v_Result        STRING DEFAULT '';
  DECLARE v_ErrorMessage  STRING DEFAULT '';
  DECLARE v_Inserted      INT64 DEFAULT 0;
  DECLARE v_Loaded        DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_EndDate       DATETIME;
  DECLARE v_StartDate     DATETIME;

  -- -----------------------------------------------------------------------
  -- Resolve date window from LoadControl
  -- -----------------------------------------------------------------------
  SELECT CAST(LastValue AS DATETIME)
  INTO v_EndDate
  FROM `{{ project_id }}.{{ dataset_id }}.staging.LoadControl`
  WHERE RecordSource = 'Fact_KPI_Scan';

  -- StartDate = last day of the month prior to EndDate at 23:59:59
  -- EOMONTH(DATEADD(MONTH, -1, @EndDate)) + 'T23:59:59.999'
  -- → DATETIME(LAST_DAY(DATE_SUB(CAST(v_EndDate AS DATE), INTERVAL 1 MONTH)), TIME '23:59:59')
  SET v_StartDate = DATETIME(
    LAST_DAY(DATE_SUB(CAST(v_EndDate AS DATE), INTERVAL 1 MONTH)),
    TIME '23:59:59'
  );

  BEGIN

    -- -----------------------------------------------------------------------
    -- Remove rows that will be recalculated
    -- Matches: DELETE WHERE DeliveryDate > @StartDate
    -- -----------------------------------------------------------------------
    DELETE FROM `{{ project_id }}.{{ dataset_id }}.dbo.Fact_KPI_Delivery_Performance`
    WHERE DeliveryDate > CAST(v_StartDate AS DATE);

    -- -----------------------------------------------------------------------
    -- Insert recalculated performance stats
    -- -----------------------------------------------------------------------
    INSERT INTO `{{ project_id }}.{{ dataset_id }}.dbo.Fact_KPI_Delivery_Performance`
    (
      CountryCode,
      PickupRF,
      DeliveryRF,
      FromCf,
      ToCf,
      Category,
      DeliveryDate,
      NumofLabels,
      OnTimePickup,
      OnTimeLEA,
      OnTimeDelivery,
      OnTimeSLA
    )
    SELECT
      CountryCode,
      FromRF,
      ToRf,
      FromCf,
      ToCf,
      Category,
      CAST(ActualAttemptedDate AS DATE)   AS DeliveryDate,
      COUNT(LabelNo)                      AS NumofLabels,

      -- OnTimePickup
      SUM(CASE
        WHEN Category = 'Local' THEN NULL
        WHEN KPIPickupImpact = 0
         AND (ActualDepartureDate IS NULL
              OR DATETIME_ADD(KPIDepartureDate, INTERVAL 30 HOUR) < ActualDepartureDate)
        THEN 0
        ELSE 1
      END)                                AS OnTimePickup,

      -- OnTimeLEA
      SUM(CASE
        WHEN Category = 'Local' THEN NULL
        WHEN KPILEAImpact = 0
         AND KPIArrivalDate   IS NOT NULL
         AND ActualArrivalDate IS NOT NULL
         AND KPIArrivalDate    < CAST(ActualDepartureDate AS DATE)
        THEN 0
        ELSE 1
      END)                                AS OnTimeLEA,

      -- OnTimeDelivery
      SUM(CASE
        WHEN Category = 'Local' THEN NULL
        WHEN KPIDeliveryImpact = 1
          OR (EstimatedDeliveryDate IS NOT NULL
              AND EstimatedDeliveryDate >= ActualAttemptedDateAdjust)
          OR (EstimatedDeliveryDate IS NULL AND ActualDepartureDate IS NULL)
        THEN 1
        ELSE 0
      END)                                AS OnTimeDelivery,

      -- OnTimeSLA
      SUM(CASE
        WHEN DueDate < ActualAttemptedDateAdjust THEN 0
        ELSE 1
      END)                                AS OnTimeSLA

    FROM (
      SELECT
        f.LabelNo,
        f.CountryCode,
        f.FromRf,
        f.FromCf,
        CASE WHEN m.ToRf = '' THEN m.Zone ELSE m.ToRf END  AS ToRf,
        f.ToCf,
        m.Category,
        m.KPIPickupImpact,
        m.KPILEAImpact,
        m.KPIDeliveryImpact,
        f.ActualAttemptedRF,
        f.ActualDepartureDate,
        f.ActualArrivalDate,
        f.ActualAttemptedDate,
        f.KPIDepartureDate,
        f.KPIArrivalDate,
        f.DueDate,
        COALESCE(f.KPIAttemptedDate, f.KPIAttemptedDateAdjust)  AS EstimatedDeliveryDate,

        -- ActualAttemptedDateAdjust:
        -- Original: SELECT TOP 1 Calendar_Date ... WHERE <= ActualAttemptedDate ORDER BY DESC
        -- → MAX() over the filtered window (latest business day on or before ActualAttemptedDate)
        (
          SELECT MAX(dt.Calendar_Date)
          FROM `{{ project_id }}.{{ dataset_id }}.dbo.Dim_Time` dt
          LEFT JOIN `{{ project_id }}.{{ dataset_id }}.dbo.KPIExcludedDates` ex
            ON dt.Calendar_Date = ex.Date
           AND ex.Franchise     = CASE WHEN m.ToRf = '' THEN m.Zone ELSE m.ToRf END
          WHERE dt.Calendar_Date <= CAST(f.ActualAttemptedDate AS DATE)
            AND dt.week_day_flag  = 'Y'
            AND ex.Comment        IS NULL
        )                                                        AS ActualAttemptedDateAdjust

      FROM `{{ project_id }}.{{ dataset_id }}.dbo.Fact_KPI` f
      INNER JOIN `{{ project_id }}.{{ dataset_id }}.dv.SAT_Label_Allocation_MF` m
        ON  f.LabelNo    = m.LabelNo
        AND m.IsCurrent  = 1
      WHERE f.CountryCode          = 1
        AND f.ActualAttemptedDate  > v_StartDate
        AND f.ActualAttemptedDate  <= v_EndDate
        AND m.Category             IN ('Interbranch', 'Local')
    ) kpi
    WHERE ToRf != 'TMW'
      AND ToRf  = ActualAttemptedRF
    GROUP BY
      CountryCode, FromRF, FromCf, ToRf, ToCf, Category,
      CAST(ActualAttemptedDate AS DATE);

    -- -----------------------------------------------------------------------
    -- Capture inserted row count scoped to the delivery date window
    -- -----------------------------------------------------------------------
    SET v_Inserted = (
      SELECT COUNT(*)
      FROM `{{ project_id }}.{{ dataset_id }}.dbo.Fact_KPI_Delivery_Performance`
      WHERE DeliveryDate > CAST(v_StartDate AS DATE)
        AND DeliveryDate <= CAST(v_EndDate AS DATE)
    );

    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result       = CONCAT('Failed (', v_Step, ')');
    SET v_ErrorMessage = @@error.message;

  END;

  -- -----------------------------------------------------------------------
  -- Record load metrics in log
  -- -----------------------------------------------------------------------
  SET v_Ended = CURRENT_DATETIME();

  CALL `{{ project_id }}.{{ dataset_id }}.staging.SaveLog`(
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