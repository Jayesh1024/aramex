-- ==========================================================================================
-- Routine:     Load_FMS_RFBatchingPerformanceBonus
-- Description: Exports stats for InterBranch Pickup & Delivery KPIs to FMS on KRILLIN
-- Example:     Exec [dbo].[Load_Fact_KPI_Performance] 30
-- History:
--  02/02/2023  B. Woods      Routine Written
--
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `project.dbo.Load_FMS_RFBatchingPerformanceBonus`(
  IN p_ProcessId BIGINT
)
BEGIN

  DECLARE v_Component     STRING DEFAULT 'dbo.Load_FMS_RFBatchingPerformanceBonus';
  DECLARE v_Step          STRING;
  DECLARE v_Started       DATETIME;
  DECLARE v_Ended         DATETIME;
  DECLARE v_Result        STRING DEFAULT '';
  DECLARE v_ErrorMessage  STRING DEFAULT '';
  DECLARE v_Inserted      INT64 DEFAULT 0;
  DECLARE v_Loaded        DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_LastValue     STRING;
  DECLARE v_DateBOM       DATE;
  DECLARE v_StartDate     DATE;
  DECLARE v_EndDate       DATE;

  SET v_Step    = 'Inserts';
  SET v_Started = CURRENT_DATETIME();

  -- -----------------------------------------------------------------------
  -- Resolve date window from LoadControl
  -- -----------------------------------------------------------------------
  SELECT CAST(LastValue AS DATE)
  INTO v_DateBOM
  FROM `project.staging.LoadControl`
  WHERE RecordSource = 'Fact_KPI_DPFM_Export';

  -- EOMONTH(DATEADD(MONTH, -1, @DateBOM)) → LAST_DAY(DATE_SUB(v_DateBOM, INTERVAL 1 MONTH))
  SET v_StartDate = LAST_DAY(DATE_SUB(v_DateBOM, INTERVAL 1 MONTH));

  -- DATEADD(DAY, -1, EOMONTH(@DateBOM)) → DATE_SUB(LAST_DAY(v_DateBOM), INTERVAL 1 DAY)
  SET v_EndDate = DATE_SUB(LAST_DAY(v_DateBOM), INTERVAL 1 DAY);

  BEGIN

    -- -----------------------------------------------------------------------
    -- Main performance bonus result set
    -- -----------------------------------------------------------------------
    CREATE TEMP TABLE Results AS
    SELECT
      t.CountryCode,
      t.PickupRF,
      t.DeliveryRF,
      t.Category,
      t.DateBOM,
      ROUND(t.PerformancePercentage, 0)   AS PerformancePercentage,
      0                                   AS FMSInvoiceBatchId,
      0                                   AS FMSInvoiceNumber,
      0                                   AS DLBSAmount,
      0                                   AS DLBSPercentageToApply,
      0                                   AS DLBSBonus,
      0                                   AS MYFDLBSAmount,
      0                                   AS MYFastwayLowerWeightAmount,
      0                                   AS MYFastwayLowerPercentageToApply,
      0                                   AS MYFastwayLowerWeightBonus,
      0                                   AS MYFastwayUpperWeightAmount,
      0                                   AS MYFastwayUpperPercentageToApply,
      0                                   AS MYFastwayUpperWeightBonus,
      v_Loaded                            AS CreatedDate,
      'FSO'                               AS CreatedBy,
      v_Loaded                            AS UpdatedDate,
      'FSO'                               AS UpdatedBy
    FROM (
      SELECT
        CountryCode,
        PickupRF,
        DeliveryRF,
        Category,
        v_DateBOM                                                         AS DateBOM,
        CAST(ROUND(SUM(OnTimeDelivery) * 100.0 / SUM(NumofLabels), 0) AS INT64) AS PerformancePercentage
      FROM `project.dbo.Fact_KPI_Delivery_Performance`
      WHERE Category    = 'Interbranch'
        AND DeliveryDate BETWEEN v_StartDate AND v_EndDate
      GROUP BY CountryCode, PickupRF, DeliveryRF, Category
    ) t
    LEFT JOIN `project.dbo.KPIRate` r ON t.DateBOM = r.DateBOM
    WHERE t.PerformancePercentage >= COALESCE(r.Rate, 95);

    /*
    UNION

    SELECT
      t.CountryCode, t.PickupRF, t.DeliveryRF, t.Category, t.DateBOM,
      ROUND(t.PerformancePercentage, 0)   AS PerformancePercentage,
      0 AS FMSInvoiceBatchId, 0 AS FMSInvoiceNumber,
      0 AS DLBSAmount, 0 AS DLBSPercentageToApply, 0 AS DLBSBonus,
      0 AS MYFDLBSAmount,
      0 AS MYFastwayLowerWeightAmount, 0 AS MYFastwayLowerPercentageToApply, 0 AS MYFastwayLowerWeightBonus,
      0 AS MYFastwayUpperWeightAmount, 0 AS MYFastwayUpperPercentageToApply, 0 AS MYFastwayUpperWeightBonus,
      v_Loaded AS CreatedDate, 'FSO' AS CreatedBy,
      v_Loaded AS UpdatedDate, 'FSO' AS UpdatedBy
    FROM (
      SELECT
        CountryCode, 'FSA' AS PickupRF, DeliveryRF, Category,
        v_DateBOM AS DateBOM,
        CAST(ROUND(SUM(OnTimeDelivery) * 100.0 / SUM(NumofLabels), 0) AS INT64) AS PerformancePercentage
      FROM `project.dbo.Fact_KPI_Delivery_Performance`
      WHERE Category = 'Interbranch'
        AND DeliveryDate BETWEEN v_StartDate AND v_EndDate
      GROUP BY CountryCode, DeliveryRF, Category
    ) t
    LEFT JOIN `project.dbo.KPIRate` r ON t.DateBOM = r.DateBOM
    WHERE t.PerformancePercentage >= COALESCE(r.Rate, 95)
    */

    SET v_Result = 'Success';

    -- -----------------------------------------------------------------------
    -- Advance LoadControl to next month on success
    -- CONVERT(Varchar(26), DATEADD(MONTH, 1, @DateBOM), 120) → CAST(DATE_ADD(...) AS STRING)
    -- -----------------------------------------------------------------------
    UPDATE `project.staging.LoadControl`
    SET LastValue = CAST(DATE_ADD(v_DateBOM, INTERVAL 1 MONTH) AS STRING)
    WHERE RecordSource = 'Fact_KPI_DPFM_Export';

  EXCEPTION WHEN ERROR THEN
    SET v_Result       = CONCAT('Failed (', v_Step, ')');
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
    v_Inserted,
    -1,
    -1
  );

END;