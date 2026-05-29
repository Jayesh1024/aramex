CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_Load_Fact_KPI_Performance_Hist`(IN p_ProcessID INT64)
BEGIN
  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Component STRING DEFAULT 'dbo_Load_Fact_KPI_Performance_Hist';
  DECLARE v_Step STRING;
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING DEFAULT 'Success';
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_Inserted INT64 DEFAULT 0;
  DECLARE v_Updated INT64 DEFAULT 0;

  BEGIN
    SET v_Step = 'Inserts';

    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI_Delivery_Performance` (
      CountryCode, PickupRF, DeliveryRF, FromCf, ToCf, Category,
      DeliveryDate, NumofLabels, OnTimePickup, OnTimeLEA, OnTimeDelivery, OnTimeSLA
    )
    SELECT
      CountryCode, FromRF, ToRf, FromCf, ToCf, Category,
      CAST(ActualAttemptedDate AS DATE) AS DeliveryDate,
      COUNT(LabelNo) AS NumofLabels,
      SUM(CASE
        WHEN Category = 'Local' THEN NULL
        WHEN KPIPickupImpact = 0 AND (ActualDepartureDate IS NULL OR DATETIME_ADD(KPIDepartureDate, INTERVAL 30 HOUR) < ActualDepartureDate) THEN 0
        ELSE 1
      END) AS OnTimePickup,
      SUM(CASE
        WHEN Category = 'Local' THEN NULL
        WHEN KPILEAImpact = 0 AND (KPIArrivalDate IS NOT NULL AND ActualArrivalDate IS NOT NULL AND KPIArrivalDate < CAST(ActualDepartureDate AS DATE)) THEN 0
        ELSE 1
      END) AS OnTimeLEA,
      SUM(CASE
        WHEN Category = 'Local' THEN NULL
        WHEN KPIDeliveryImpact = 1 OR (EstimatedDeliveryDate IS NOT NULL AND EstimatedDeliveryDate >= ActualAttemptedDateAdjust) OR (EstimatedDeliveryDate IS NULL AND ActualDepartureDate IS NULL) THEN 1
        ELSE 0
      END) AS OnTimeDelivery,
      SUM(CASE WHEN DueDate < ActualAttemptedDateAdjust THEN 0 ELSE 1 END) AS OnTimeSLA
    FROM (
      -- CTE/Subquery to resolve the "Latest Valid Date" without correlation
      SELECT
        k.*,
        dt.Calendar_Date AS ActualAttemptedDateAdjust,
        ROW_NUMBER() OVER(PARTITION BY k.LabelNo ORDER BY dt.Calendar_Date DESC) as rn
      FROM (
        SELECT
          f.LabelNo, f.CountryCode, m.FromRf, m.FromCf, f.Category,
          CASE WHEN m.ToRf = '' THEN m.Zone ELSE m.ToRf END AS ToRf,
          m.ToCf, f.KPIPickupImpact, f.KPILEAImpact, f.KPIDeliveryImpact,
          f.ActualAttemptedRF, f.ActualDepartureDate, f.ActualArrivalDate,
          f.ActualAttemptedDate, f.KPIDepartureDate, f.KPIArrivalDate, f.DueDate,
          COALESCE(f.KPIAttemptedDate, f.KPIAttemptedDateAdjust) AS EstimatedDeliveryDate
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI` AS f
        INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF_partitioned` AS m ON f.LabelNo = m.LabelNo
        WHERE f.CountryCode = 1
          AND m.IsCurrent = 1
          AND f.Category IN ('Interbranch', 'Local')
      ) k
      -- Join to the Time/Exclusion tables using the inequality
      INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Time` dt
        ON dt.Calendar_Date <= CAST(k.ActualAttemptedDate AS DATE)
      LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIExcludedDates` ex
        ON dt.Calendar_Date = ex.Date AND ex.Franchise = k.ToRf
      WHERE dt.week_day_flag = 'Y'
        AND ex.Comment IS NULL
    ) AS kpi
    WHERE rn = 1 -- This replaces the 'LIMIT 1' from your subquery
      AND ToRf != 'TMW'
      AND ToRf = ActualAttemptedRF
    GROUP BY CountryCode, FromRF, FromCf, ToRf, ToCf, Category, CAST(ActualAttemptedDate AS DATE);

    SET v_Inserted = @@row_count;
    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result = CONCAT('Failed (', v_Step, ')');
    SET v_ErrorMessage = @@error.message;
  END;

  SET v_Ended = CURRENT_DATETIME();
  CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
    v_Component, p_ProcessID, v_Started, v_Ended, v_Result, v_ErrorMessage, v_Inserted, v_Updated, -1
  );
END;