-- ==========================================================================================
-- Routine:     Load_FMS_RFBatchingPerformanceBonus
-- Description: Exports stats for InterBranch Pickup & Delivery KPIs to FMS on KRILLIN
-- Example:     Exec [dbo].[Load_Fact_KPI_Performance] 30
-- History:
--  02/02/2023  B. Woods      Routine Written
--
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_Load_FMS_RFBatchingPerformanceBonus`(
  IN p_ProcessId INT64
)
BEGIN

  DECLARE v_Component     STRING DEFAULT 'dbo_Load_FMS_RFBatchingPerformanceBonus';
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
  -- FIX: Changed SELECT INTO to SET variable = (SELECT ...)
  -- -----------------------------------------------------------------------
  SET v_DateBOM = (
    SELECT DATE(SAFE_CAST(LastValue AS DATETIME))
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_LoadControl`
    WHERE RecordSource = 'Fact_KPI_DPFM_Export'
    LIMIT 1
  );

  SET v_StartDate = LAST_DAY(DATE_SUB(v_DateBOM, INTERVAL 1 MONTH));
  SET v_EndDate = DATE_SUB(LAST_DAY(v_DateBOM), INTERVAL 1 DAY);

  BEGIN

    -- -----------------------------------------------------------------------
    -- Main performance bonus result set
    -- -----------------------------------------------------------------------
    CREATE OR REPLACE TEMP TABLE Results AS
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
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI_Delivery_Performance`
      WHERE Category    = 'Interbranch'
        AND DeliveryDate BETWEEN v_StartDate AND v_EndDate
      GROUP BY CountryCode, PickupRF, DeliveryRF, Category
    ) t
    LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIRate` r ON t.DateBOM = r.DateBOM
    WHERE t.PerformancePercentage >= COALESCE(r.Rate, 95);

    -- Capture the number of rows calculated
    SET v_Inserted = (SELECT COUNT(*) FROM Results);

    SET v_Result = 'Success';

    -- -----------------------------------------------------------------------
    -- Advance LoadControl to next month on success
    -- -----------------------------------------------------------------------
    UPDATE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_LoadControl`
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

  CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
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