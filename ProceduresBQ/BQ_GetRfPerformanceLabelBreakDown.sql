CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.rpt_GetRfPerformanceLabelBreakDown`(
  IN p_StartDate  DATETIME,
  IN p_EndDate    DATETIME
)
BEGIN

  CREATE TEMP TABLE Results AS

  WITH

  -- -----------------------------------------------------------------------
  -- Resolve ActualAttemptedDateAdjust via LEFT JOIN + ARRAY_AGG
  -- Replaces the correlated SELECT TOP 1 subquery from the original
  -- -----------------------------------------------------------------------
  AttemptedDateAdjust AS (
    SELECT
      f.LabelNo,
      (
        SELECT MAX(dt.Calendar_Date)
        FROM `{{ project_id }}.{{ target_dataset_id }}.rpt_Dim_Time` dt
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.rpt_KPIExcludedDates` ex
          ON dt.Calendar_Date = ex.Date
         AND ex.Franchise     = CASE WHEN m.ToRf = '' THEN m.Zone ELSE m.ToRf END
        WHERE dt.Calendar_Date <= CAST(f.ActualAttemptedDate AS DATE)
          AND dt.week_day_flag  = 'Y'
          AND ex.Comment IS NULL
      ) AS ActualAttemptedDateAdjust
    FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI` f
    INNER JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF` m
      ON f.LabelNo   = m.LabelNo
    WHERE f.CountryCode          = 1
      AND f.ActualAttemptedDate  > p_StartDate
      AND f.ActualAttemptedDate  <= p_EndDate
      AND m.IsCurrent            = 1
      AND m.Category             IN ('Interbranch', 'Local')
  ),

  -- -----------------------------------------------------------------------
  -- Base KPI dataset
  -- -----------------------------------------------------------------------
  KPI AS (
    SELECT
      f.LabelNo,
      f.CountryCode,
      f.FromRf,
      f.FromCf,
      CASE WHEN m.ToRf = '' THEN m.Zone ELSE m.ToRf END AS ToRf,
      f.ToCf,
      m.Category,
      m.SLA,
      m.KPIPickup,
      m.KPILEA,
      m.KPIDelivery,
      m.KPIPickupImpact,
      m.KPILEAImpact,
      m.KPIDeliveryImpact,
      f.ActualAttemptedRF,
      f.ActualDepartureDate,
      f.ActualFirstArrivalDate,
      f.ActualArrivalDate,
      f.ActualAttemptedDate,
      f.KPIDepartureDate,
      f.KPIArrivalDate,
      f.KPIAttemptedDate,
      f.KPIAttemptedDateAdjust,
      f.RealisedDate,
      f.DueDate,
      COALESCE(f.KPIAttemptedDate, f.KPIAttemptedDateAdjust) AS EstimatedDeliveryDate,
      a.ActualAttemptedDateAdjust
    FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI` f
    INNER JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF` m
      ON f.LabelNo   = m.LabelNo
    INNER JOIN AttemptedDateAdjust a
      ON f.LabelNo   = a.LabelNo
    WHERE f.CountryCode         = 1
      AND f.ActualAttemptedDate > p_StartDate
      AND f.ActualAttemptedDate <= p_EndDate
      AND m.IsCurrent           = 1
      AND m.Category            IN ('Interbranch', 'Local')
  ),

  -- -----------------------------------------------------------------------
  -- KPI performance flags
  -- -----------------------------------------------------------------------
  DestoPerformanceCheck AS (
    SELECT
      LabelNo,
      CountryCode,
      FromRF,
      ToRf,
      FromCf,
      ToCf,
      Category,
      SLA,
      KPIPickup,
      KPILEA,
      KPIDelivery,
      -- KPIPickupImpact,   -- dataset not complete yet to utilise
      -- KPILEAImpact,      -- dataset not ready yet to utilise
      -- KPIDeliveryImpact, -- dataset not ready yet to utilise
      ActualAttemptedRF,
      ActualDepartureDate,
      ActualFirstArrivalDate,
      ActualArrivalDate,
      ActualAttemptedDate,
      ActualAttemptedDateAdjust,
      RealisedDate,
      CAST(ActualAttemptedDate AS DATE)                         AS DeliveryDate,
      DueDate,
      KPIDepartureDate,
      KPIArrivalDate,
      KPIAttemptedDate,
      KPIAttemptedDateAdjust                                    AS KPIAttemptedDateAdjust,

      -- OnTimePickup
      CASE
        WHEN Category = 'Local' THEN NULL
        WHEN KPIPickupImpact = 0
         AND (ActualDepartureDate IS NULL
              OR DATETIME_ADD(KPIDepartureDate, INTERVAL 30 HOUR) < ActualDepartureDate)
        THEN 0
        ELSE 1
      END AS OnTimePickup,

      -- OnTimeLEA
      CASE
        WHEN Category = 'Local' THEN NULL
        WHEN KPILEAImpact = 0
         AND KPIArrivalDate   IS NOT NULL
         AND ActualArrivalDate IS NOT NULL
         AND KPIArrivalDate    < CAST(ActualDepartureDate AS DATE)
        THEN 0
        ELSE 1
      END AS OnTimeLEA,

      -- OnTimeDelivery
      CASE
        WHEN Category = 'Local' THEN NULL
        WHEN KPIDeliveryImpact = 1
          OR (EstimatedDeliveryDate IS NOT NULL AND EstimatedDeliveryDate >= ActualAttemptedDateAdjust)
          OR (EstimatedDeliveryDate IS NULL AND ActualDepartureDate IS NULL)
        THEN 1
        ELSE 0
      END AS OnTimeDelivery,

      -- OnTimeSLA
      CASE
        WHEN DueDate < ActualAttemptedDateAdjust THEN 0
        ELSE 1
      END AS OnTimeSLA

    FROM KPI
    WHERE ToRf    != 'TMW'
      AND ToRf     = ActualAttemptedRF
      AND Category = 'interbranch'
  )

  -- -----------------------------------------------------------------------
  -- Final output with OnTimeDeliveryResult label
  -- -----------------------------------------------------------------------
  SELECT
    *,
    CASE
      WHEN OnTimeDelivery = 1                                    THEN 'Successful'
      WHEN OnTimeDelivery = 0 AND ActualArrivalDate IS NULL      THEN 'Fail No Manifest'
      ELSE                                                            'Fail'
    END AS OnTimeDeliveryResult
  FROM DestoPerformanceCheck;

END;