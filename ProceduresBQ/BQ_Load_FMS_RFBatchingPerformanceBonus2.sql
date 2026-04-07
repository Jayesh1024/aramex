-- ==========================================================================================
-- Routine:     Load_FMS_RFBatchingPerformanceBonus
-- Description: Exports stats for InterBranch Pickup & Delivery KPIs to FMS on KRILLIN
-- Example:     Exec [dbo].[Load_Fact_KPI_Performance] 30
-- History:
--  02/02/2023  B. Woods      Routine Written
--
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ dataset_id }}.dbo.Load_FMS_RFBatchingPerformanceBonus2`(
  IN p_ProcessId BIGINT
)
BEGIN

  DECLARE v_Component     STRING DEFAULT 'dbo.Load_FMS_RFBatchingPerformanceBonus2';
  DECLARE v_Step          STRING;
  DECLARE v_Started       DATETIME;
  DECLARE v_Ended         DATETIME;
  DECLARE v_Result        STRING DEFAULT '';
  DECLARE v_ErrorMessage  STRING DEFAULT '';
  DECLARE v_Inserted      INT64 DEFAULT 0;
  DECLARE v_Loaded        DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_DateBOM       DATE;
  DECLARE v_StartDate     DATE;
  DECLARE v_EndDate       DATE;

  SET v_Step    = 'Inserts';
  SET v_Started = CURRENT_DATETIME();

  -- -----------------------------------------------------------------------
  -- Resolve DateBOM from LoadControl
  -- -----------------------------------------------------------------------
  SELECT CAST(LastValue AS DATE)
  INTO v_DateBOM
  FROM `{{ project_id }}.{{ dataset_id }}.staging.LoadControl`
  WHERE RecordSource = 'Fact_KPI_DPFM_Export';

  -- Default date window
  SET v_StartDate = LAST_DAY(DATE_SUB(v_DateBOM, INTERVAL 1 MONTH));
  SET v_EndDate   = DATE_SUB(LAST_DAY(v_DateBOM), INTERVAL 1 DAY);

  -- January override: set start to 01-Jan so whole calendar year is selected
  -- DATEADD(DAY, 1, EOMONTH(DATEADD(MONTH, -1, @DateBOM))) → DATE_ADD(LAST_DAY(DATE_SUB(...)), INTERVAL 1 DAY)
  IF EXTRACT(MONTH FROM v_DateBOM) = 1 THEN
    SET v_StartDate = DATE_ADD(LAST_DAY(DATE_SUB(v_DateBOM, INTERVAL 1 MONTH)), INTERVAL 1 DAY);
  END IF;

  -- December override: set end to 31-Dec so calendar year is complete
  IF EXTRACT(MONTH FROM v_DateBOM) = 12 THEN
    SET v_EndDate = LAST_DAY(v_DateBOM);
  END IF;

  BEGIN

    -- -----------------------------------------------------------------------
    -- Main result set: per PickupRF + FSA aggregate UNION
    -- -----------------------------------------------------------------------
    CREATE TEMP TABLE Results AS

    -- Per PickupRF breakdown
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
        v_DateBOM                                                               AS DateBOM,
        CAST(ROUND(SUM(OnTimeDelivery) * 100.0 / SUM(NumofLabels), 0) AS INT64) AS PerformancePercentage
      FROM `{{ project_id }}.{{ dataset_id }}.dbo.Fact_KPI_Delivery_Performance`
      WHERE Category    = 'Interbranch'
        AND DeliveryDate BETWEEN v_StartDate AND v_EndDate
      GROUP BY CountryCode, PickupRF, DeliveryRF, Category
    ) t
    LEFT JOIN `{{ project_id }}.{{ dataset_id }}.dbo.KPIRate` r ON t.DateBOM = r.DateBOM
    -- WHERE PerformancePercentage >= COALESCE(r.Rate, 95)
    -- WHERE PerformancePercentage >= 90

    UNION

    -- FSA aggregate (all pickups rolled up under 'FSA')
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
        'FSA'                                                                   AS PickupRF,
        DeliveryRF,
        Category,
        v_DateBOM                                                               AS DateBOM,
        CAST(ROUND(SUM(OnTimeDelivery) * 100.0 / SUM(NumofLabels), 0) AS INT64) AS PerformancePercentage
      FROM `{{ project_id }}.{{ dataset_id }}.dbo.Fact_KPI_Delivery_Performance`
      WHERE Category    = 'Interbranch'
        AND DeliveryDate BETWEEN v_StartDate AND v_EndDate
      GROUP BY CountryCode, DeliveryRF, Category
    ) t
    LEFT JOIN `{{ project_id }}.{{ dataset_id }}.dbo.KPIRate` r ON t.DateBOM = r.DateBOM;
    -- WHERE PerformancePercentage >= COALESCE(r.Rate, 95)
    -- WHERE PerformancePercentage >= 90

    SET v_Result = 'Success';

    -- UPDATE `{{ project_id }}.{{ dataset_id }}.staging.LoadControl`
    -- SET LastValue = CAST(DATE_ADD(v_DateBOM, INTERVAL 1 MONTH) AS STRING)
    -- WHERE RecordSource = 'Fact_KPI_DPFM_Export';

  EXCEPTION WHEN ERROR THEN
    SET v_Result       = CONCAT('Failed (', v_Step, ')');
    SET v_ErrorMessage = @@error.message;

  END;

  /*
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
  */

END;