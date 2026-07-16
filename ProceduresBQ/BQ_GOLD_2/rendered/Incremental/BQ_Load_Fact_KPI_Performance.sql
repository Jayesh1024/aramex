CREATE OR REPLACE
  PROCEDURE
    `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_Load_Fact_KPI_Performance`(
      IN p_ProcessID INT64)
      BEGIN
        DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();

DECLARE v_StartDate DATETIME;
DECLARE v_EndDate DATETIME;
DECLARE v_Component STRING DEFAULT 'dbo_Load_Fact_KPI_Performance';
DECLARE v_Step STRING;
DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
DECLARE v_Ended DATETIME;
DECLARE v_Result STRING DEFAULT 'Success';
DECLARE v_ErrorMessage STRING DEFAULT NULL;
DECLARE v_Inserted INT64 DEFAULT 0;
DECLARE v_Updated INT64 DEFAULT 0;

BEGIN
SET v_Step = 'Inserts';

SET v_EndDate = (
  SELECT CAST(LastValue AS DATETIME)
  FROM
    `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_LoadControl`
  WHERE RecordSource = 'Fact_KPI_Scan'
);

SET v_StartDate =
  CAST(
    CONCAT(
      CAST(
        LAST_DAY(DATE_SUB(CAST(v_EndDate AS DATE), INTERVAL 1 MONTH))
        AS STRING),
      ' 23:59:59.999')
    AS DATETIME);

DELETE FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI_Delivery_Performance`
WHERE DeliveryDate > CAST(v_StartDate AS DATE);

INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI_Delivery_Performance`
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
    OnTimeSLA)
WITH
  k AS (
    SELECT
      f.LabelNo,
      f.CountryCode,
      m.FromRf,
      m.FromCf,
      f.Category,
      CASE WHEN m.ToRf = '' THEN m.Zone ELSE m.ToRf END AS ToRf,
      m.ToCf,
      f.KPIPickupImpact,
      f.KPILEAImpact,
      f.KPIDeliveryImpact,
      f.ActualAttemptedRF,
      f.ActualDepartureDate,
      f.ActualArrivalDate,
      f.ActualAttemptedDate,
      f.KPIDepartureDate,
      f.KPIArrivalDate,
      f.DueDate,
      COALESCE(f.KPIAttemptedDate, f.KPIAttemptedDateAdjust)
        AS EstimatedDeliveryDate,
      DATE(f.ActualAttemptedDate) AS ActualAttemptedDt
    FROM
      `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI`
        AS f
    INNER JOIN
      `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF`
        AS m
      ON f.LabelNo = m.LabelNo
    WHERE
      f.CountryCode = 1
      AND f.ActualAttemptedDate IS NOT NULL
      AND f.ActualAttemptedDate > v_StartDate
      AND f.ActualAttemptedDate <= v_EndDate
      AND m.IsCurrent = 1
      AND f.Category IN ('Interbranch', 'Local')
  ),
  valid_days AS (
    SELECT DATE(Calendar_Date) AS Calendar_Date
    FROM
      `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Time`
    WHERE
      week_day_flag = 'Y'
      AND DATE(Calendar_Date)
        BETWEEN DATE_SUB(CAST(v_StartDate AS DATE), INTERVAL 30 DAY)
        AND CAST(v_EndDate AS DATE)
  ),
  kpi AS (
    SELECT
      k.* EXCEPT (ActualAttemptedDt),
      dt.Calendar_Date AS ActualAttemptedDateAdjust
    FROM k
    INNER JOIN valid_days dt
      ON
        dt.Calendar_Date
        BETWEEN DATE_SUB(k.ActualAttemptedDt, INTERVAL 30 DAY)
        AND k.ActualAttemptedDt
    LEFT JOIN
      `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIExcludedDates`
        ex
      ON dt.Calendar_Date = DATE(ex.Date) AND ex.Franchise = k.ToRf
    WHERE ex.Comment IS NULL
    QUALIFY
      ROW_NUMBER() OVER (PARTITION BY k.LabelNo ORDER BY dt.Calendar_Date DESC)
      = 1
  )
SELECT
  CountryCode,
  FromRf AS FromRF,
  ToRf,
  FromCf,
  ToCf,
  Category,
  CAST(ActualAttemptedDate AS DATE) AS DeliveryDate,
  COUNT(LabelNo) AS NumofLabels,
  SUM(
    CASE
      WHEN Category = 'Local' THEN NULL
      WHEN
        KPIPickupImpact = 0
        AND (
          ActualDepartureDate IS NULL
          OR DATETIME_ADD(KPIDepartureDate, INTERVAL 30 HOUR)
            < ActualDepartureDate)
        THEN 0
      ELSE 1
      END) AS OnTimePickup,
  SUM(
    CASE
      WHEN Category = 'Local' THEN NULL
      WHEN
        KPILEAImpact = 0
        AND (
          KPIArrivalDate IS NOT NULL
          AND ActualArrivalDate IS NOT NULL
          AND KPIArrivalDate < CAST(ActualDepartureDate AS DATE))
        THEN 0
      ELSE 1
      END) AS OnTimeLEA,
  SUM(
    CASE
      WHEN Category = 'Local' THEN NULL
      WHEN
        KPIDeliveryImpact = 1
        OR (
          EstimatedDeliveryDate IS NOT NULL
          AND EstimatedDeliveryDate >= ActualAttemptedDateAdjust)
        OR (EstimatedDeliveryDate IS NULL AND ActualDepartureDate IS NULL)
        THEN 1
      ELSE 0
      END) AS OnTimeDelivery,
  SUM(CASE WHEN DueDate < ActualAttemptedDateAdjust THEN 0 ELSE 1 END)
    AS OnTimeSLA
FROM kpi
WHERE
  ToRf != 'TMW'
  AND ToRf = ActualAttemptedRF
GROUP BY
  CountryCode, FromRf, FromCf, ToRf, ToCf, Category,
  CAST(ActualAttemptedDate AS DATE);

SET v_Inserted = @@row_count;
SET v_Result = 'Success';

EXCEPTION WHEN ERROR THEN
SET v_Result = CONCAT('Failed (', v_Step, ')');

SET v_ErrorMessage = @@error.message;

END;

SET v_Ended = CURRENT_DATETIME();

CALL
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
    v_Component,
    p_ProcessID,
    v_Started,
    v_Ended,
    v_Result,
    v_ErrorMessage,
    v_Inserted,
    v_Updated,
    -1);

END;
