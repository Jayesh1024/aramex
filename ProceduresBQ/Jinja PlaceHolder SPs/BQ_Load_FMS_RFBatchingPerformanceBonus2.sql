-- ==========================================================================================
-- Routine:     Load_FMS_RFBatchingPerformanceBonus
-- Description: Exports stats for InterBranch Pickup & Delivery KPIs to FMS on KRILLIN
-- Example:     Exec [dbo].[Load_Fact_KPI_Performance] 30
-- History:
--  02/02/2023  B. Woods      Routine Written
--
-- ==========================================================================================
<<<<<<< HEAD:ProceduresBQ/Jinja PlaceHolder SPs/BQ_Load_FMS_RFBatchingPerformanceBonus2.sql
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dbo_Load_FMS_RFBatchingPerformanceBonus2`(
  IN p_ProcessId INT64 -- Changed BIGINT to INT64
=======
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ dataset_id }}.dbo_Load_FMS_RFBatchingPerformanceBonus2`(
  IN p_ProcessId BIGINT
>>>>>>> refs/remotes/origin/dev_manas:ProceduresBQ/BQ_Load_FMS_RFBatchingPerformanceBonus2.sql
)
BEGIN

  DECLARE v_Component     STRING DEFAULT 'dbo_Load_FMS_RFBatchingPerformanceBonus2';
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
  -- FIX: Changed SELECT INTO to SET variable = (SELECT ...)
  -- -----------------------------------------------------------------------
<<<<<<< HEAD:ProceduresBQ/Jinja PlaceHolder SPs/BQ_Load_FMS_RFBatchingPerformanceBonus2.sql
  SET v_DateBOM = (
    SELECT CAST(LastValue AS DATE)
    FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_LoadControl`
    WHERE RecordSource = 'Fact_KPI_DPFM_Export'
    LIMIT 1
  );
=======
  SELECT CAST(LastValue AS DATE)
  INTO v_DateBOM
  FROM `{{ project_id }}.{{ dataset_id }}.staging_LoadControl`
  WHERE RecordSource = 'Fact_KPI_DPFM_Export';
>>>>>>> refs/remotes/origin/dev_manas:ProceduresBQ/BQ_Load_FMS_RFBatchingPerformanceBonus2.sql

  -- Default date window
  SET v_StartDate = LAST_DAY(DATE_SUB(v_DateBOM, INTERVAL 1 MONTH));
  SET v_EndDate   = DATE_SUB(LAST_DAY(v_DateBOM), INTERVAL 1 DAY);

  -- January override: set start to 01-Jan so whole calendar year is selected
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
    -- FIX: Changed to CREATE OR REPLACE and added UNION ALL
    -- -----------------------------------------------------------------------
    CREATE OR REPLACE TEMP TABLE Results AS

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
<<<<<<< HEAD:ProceduresBQ/Jinja PlaceHolder SPs/BQ_Load_FMS_RFBatchingPerformanceBonus2.sql
      FROM `s{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI_Delivery_Performance`
=======
      FROM `{{ project_id }}.{{ dataset_id }}.dbo_Fact_KPI_Delivery_Performance`
>>>>>>> refs/remotes/origin/dev_manas:ProceduresBQ/BQ_Load_FMS_RFBatchingPerformanceBonus2.sql
      WHERE Category    = 'Interbranch'
        AND DeliveryDate BETWEEN v_StartDate AND v_EndDate
      GROUP BY CountryCode, PickupRF, DeliveryRF, Category
    ) t
<<<<<<< HEAD:ProceduresBQ/Jinja PlaceHolder SPs/BQ_Load_FMS_RFBatchingPerformanceBonus2.sql
    LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIRate` r ON t.DateBOM = r.DateBOM
=======
    LEFT JOIN `{{ project_id }}.{{ dataset_id }}.dbo_KPIRate` r ON t.DateBOM = r.DateBOM
    -- WHERE PerformancePercentage >= COALESCE(r.Rate, 95)
    -- WHERE PerformancePercentage >= 90
>>>>>>> refs/remotes/origin/dev_manas:ProceduresBQ/BQ_Load_FMS_RFBatchingPerformanceBonus2.sql

    UNION ALL -- FIX: BigQuery requires ALL or DISTINCT

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
      FROM `{{ project_id }}.{{ dataset_id }}.dbo_Fact_KPI_Delivery_Performance`
      WHERE Category    = 'Interbranch'
        AND DeliveryDate BETWEEN v_StartDate AND v_EndDate
      GROUP BY CountryCode, DeliveryRF, Category
    ) t
<<<<<<< HEAD:ProceduresBQ/Jinja PlaceHolder SPs/BQ_Load_FMS_RFBatchingPerformanceBonus2.sql
    LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIRate` r ON t.DateBOM = r.DateBOM;
=======
    LEFT JOIN `{{ project_id }}.{{ dataset_id }}.dbo_KPIRate` r ON t.DateBOM = r.DateBOM;
    -- WHERE PerformancePercentage >= COALESCE(r.Rate, 95)
    -- WHERE PerformancePercentage >= 90
>>>>>>> refs/remotes/origin/dev_manas:ProceduresBQ/BQ_Load_FMS_RFBatchingPerformanceBonus2.sql

    -- Capture Inserted Count
    SET v_Inserted = (SELECT COUNT(*) FROM Results);
    SET v_Result = 'Success';

<<<<<<< HEAD:ProceduresBQ/Jinja PlaceHolder SPs/BQ_Load_FMS_RFBatchingPerformanceBonus2.sql
=======
    -- UPDATE `{{ project_id }}.{{ dataset_id }}.staging_LoadControl`
    -- SET LastValue = CAST(DATE_ADD(v_DateBOM, INTERVAL 1 MONTH) AS STRING)
    -- WHERE RecordSource = 'Fact_KPI_DPFM_Export';

>>>>>>> refs/remotes/origin/dev_manas:ProceduresBQ/BQ_Load_FMS_RFBatchingPerformanceBonus2.sql
  EXCEPTION WHEN ERROR THEN
    SET v_Result       = CONCAT('Failed (', v_Step, ')');
    SET v_ErrorMessage = @@error.message;
  END;

  -- -----------------------------------------------------------------------
  -- Optional: Final Log Call
  -- -----------------------------------------------------------------------
  /*
  SET v_Ended = CURRENT_DATETIME();
<<<<<<< HEAD:ProceduresBQ/Jinja PlaceHolder SPs/BQ_Load_FMS_RFBatchingPerformanceBonus2.sql
  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
    v_Component, p_ProcessId, v_Started, v_Ended, v_Result, v_ErrorMessage, v_Inserted, -1, -1
=======

  CALL `{{ project_id }}.{{ dataset_id }}.staging_SaveLog`(
    v_Component,
    p_ProcessId,
    v_Started,
    v_Ended,
    v_Result,
    v_ErrorMessage,
    v_Inserted,
    -1,
    -1
>>>>>>> refs/remotes/origin/dev_manas:ProceduresBQ/BQ_Load_FMS_RFBatchingPerformanceBonus2.sql
  );
  */

END;