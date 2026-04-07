-- ==========================================================================================
-- Routine:     Load_Fact_KPI_Priority
-- Description: Loads any Priority labels into [dbo].[Fact_KPI_Daily_Priority]
-- Example:     Exec [dbo].[Load_Fact_KPI_Priority] 30
-- History:
--  04/05/2023  B. Woods        Routine Written
--
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dbo_Load_Fact_KPI_Priority`(
  IN p_ProcessId INT64
)
BEGIN

  DECLARE v_Component     STRING DEFAULT 'dbo.Load_Fact_KPI_Priority';
  DECLARE v_SubComponent  STRING;
  DECLARE v_Step          STRING;
  DECLARE v_Started       DATETIME;
  DECLARE v_Ended         DATETIME;
  DECLARE v_Result        STRING;
  DECLARE v_ErrorMessage  STRING;
  DECLARE v_Inserted      INT64 DEFAULT 0;
  DECLARE v_Updated       INT64 DEFAULT 0;

  SET v_Step    = 'Inserts';
  SET v_Started = CURRENT_DATETIME();

  BEGIN

    -- -----------------------------------------------------------------------
    -- Truncate and reload Priority labels
    -- -----------------------------------------------------------------------
    TRUNCATE TABLE `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI_Daily_Priority`;

    INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI_Daily_Priority`
    (
      LabelNo,
      CountryCode,
      Category,
      ServiceType,
      CreatedOn,
      RealisedDate,
      SLA,
      KPIPickup,
      KPILEA,
      KPIDelivery,
      KPIPickupImpact,
      KPILEAImpact,
      KPIDeliveryImpact,
      DueDate,
      KPIDepartureDate,
      KPIArrivalDate,
      KPIAttemptedDate,
      KPIAttemptedDateAdjust,
      ActualDepartureDate,
      ActualDepartureRF,
      ActualDepartureCF,
      ActualDepartureType,
      ActualDepartureStatus,
      ActualFirstArrivalDate,
      ActualFirstArrivalRF,
      ActualFirstArrivalCF,
      ActualFirstArrivalType,
      ActualFirstArrivalStatus,
      ActualArrivalDate,
      ActualArrivalRF,
      ActualArrivalCF,
      ActualArrivalType,
      ActualArrivalStatus,
      ActualAttemptedDate,
      ActualAttemptedRF,
      ActualAttemptedCF,
      ActualAttemptedType,
      ActualAttemptedStatus,
      ActualDeliveryScanDate,
      ActualDeliveryRF,
      ActualDeliveryCF,
      ActualDeliveryType,
      ActualDeliveryStatus,
      LastScanDate,
      LastScanRF,
      LastScanCF,
      LastScanType,
      LastScanStatus,
      MISScanDate,
      MISRF,
      LastUpdated,
      ProcessId,
      FromRf,
      FromCf,
      ToRf,
      ToCf,
      CustomerId,
      ToLocality,
      ToPostalCode
    )
    SELECT
      K.LabelNo,
      K.CountryCode,
      K.Category,
      K.ServiceType,
      K.CreatedOn,
      K.RealisedDate,
      K.SLA,
      K.KPIPickup,
      K.KPILEA,
      K.KPIDelivery,
      K.KPIPickupImpact,
      K.KPILEAImpact,
      K.KPIDeliveryImpact,
      K.DueDate,
      K.KPIDepartureDate,

      -- -----------------------------------------------------------------------
      -- KPIArrivalDate:
      -- Original: nth business day >= ActualDepartureDate, offset by KPILEA
      -- OFFSET n ROWS FETCH FIRST 1 ROWS ONLY →
      --   ARRAY_AGG(Calendar_Date ORDER BY Calendar_Date)[SAFE_OFFSET(n)]
      -- SAFE_OFFSET returns NULL if n exceeds array bounds (safe equivalent)
      -- -----------------------------------------------------------------------
      (
        SELECT ARRAY_AGG(dt.Calendar_Date ORDER BY dt.Calendar_Date)
               [SAFE_OFFSET(CAST(COALESCE(K.KPILEA, 0) AS INT64))]
        FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Time` dt
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIExcludedDates` ex
          ON dt.Calendar_Date = ex.Date
         AND ex.Franchise     = MF.ToRf
        WHERE dt.Calendar_Date >= CAST(K.ActualDepartureDate AS DATE)
          AND dt.week_day_flag  = 'Y'
          AND ex.Comment        IS NULL
      )                                             AS KPIArrivalDate,

      -- -----------------------------------------------------------------------
      -- KPIAttemptedDate:
      -- nth business day >= ActualArrivalDate, offset by KPIDelivery
      -- -----------------------------------------------------------------------
      (
        SELECT ARRAY_AGG(dt.Calendar_Date ORDER BY dt.Calendar_Date)
               [SAFE_OFFSET(CAST(COALESCE(K.KPIDelivery, 0) AS INT64))]
        FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Time` dt
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIExcludedDates` ex
          ON dt.Calendar_Date = ex.Date
         AND ex.Franchise     = MF.ToRf
        WHERE dt.Calendar_Date >= CAST(K.ActualArrivalDate AS DATE)
          AND dt.week_day_flag  = 'Y'
          AND ex.Comment        IS NULL
      )                                             AS KPIAttemptedDate,

      -- -----------------------------------------------------------------------
      -- KPIAttemptedDateAdjust:
      -- nth business day >= ActualDepartureDate, offset by KPILEA + KPIDelivery
      -- -----------------------------------------------------------------------
      (
        SELECT ARRAY_AGG(dt.Calendar_Date ORDER BY dt.Calendar_Date)
               [SAFE_OFFSET(CAST(COALESCE(K.KPILEA, 0) + COALESCE(K.KPIDelivery, 0) AS INT64))]
        FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Time` dt
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIExcludedDates` ex
          ON dt.Calendar_Date = ex.Date
         AND ex.Franchise     = MF.ToRf
        WHERE dt.Calendar_Date >= CAST(K.ActualDepartureDate AS DATE)
          AND dt.week_day_flag  = 'Y'
          AND ex.Comment        IS NULL
      )                                             AS KPIAttemptedDateAdjust,

      K.ActualDepartureDate,
      K.ActualDepartureRF,
      K.ActualDepartureCF,
      K.ActualDepartureType,
      K.ActualDepartureStatus,
      K.ActualFirstArrivalDate,
      K.ActualFirstArrivalRF,
      K.ActualFirstArrivalCF,
      K.ActualFirstArrivalType,
      K.ActualFirstArrivalStatus,
      K.ActualArrivalDate,
      K.ActualArrivalRF,
      K.ActualArrivalCF,
      K.ActualArrivalType,
      K.ActualArrivalStatus,
      K.ActualAttemptedDate,
      K.ActualAttemptedRF,
      K.ActualAttemptedCF,
      K.ActualAttemptedType,
      K.ActualAttemptedStatus,
      K.ActualDeliveryScanDate,
      K.ActualDeliveryRF,
      K.ActualDeliveryCF,
      K.ActualDeliveryType,
      K.ActualDeliveryStatus,
      K.LastScanDate,
      K.LastScanRF,
      K.LastScanCF,
      K.LastScanType,
      K.LastScanStatus,
      K.MISScanDate,
      K.MISRF,
      K.LastUpdated,
      K.ProcessId,
      MF.FromRf,
      MF.FromCf,
      MF.ToRf,
      MF.ToCf,
      MF.CustomerId,
      MF.ToLocality,
      MF.ToPostalCode
    FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI_Daily` K
    LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF` MF
      ON  MF.LabelNo    = K.LabelNo
      AND MF.IsCurrent  = 1
      AND MF.CountryCode = K.CountryCode
    WHERE K.ServiceType = 'P';

    -- -----------------------------------------------------------------------
    -- Capture inserted row count scoped to this process
    -- -----------------------------------------------------------------------
    SET v_Inserted = (
      SELECT COUNT(*)
      FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI_Daily_Priority`
      WHERE ProcessId = p_ProcessId
    );

    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result       = CONCAT('Failed (', v_Step, ')');
    SET v_ErrorMessage = @@error.message;

  END;

  -- -----------------------------------------------------------------------
  -- Record load metrics in log
  -- @SubComponent = @Component + ' (' + @Step + ')' — preserved from original
  -- -----------------------------------------------------------------------
  SET v_Ended        = CURRENT_DATETIME();
  SET v_SubComponent = CONCAT(v_Component, ' (', v_Step, ')');

  CALL `{{ project_id }}.{{ sp_dataset_id }}.staging_SaveLog`(
    v_SubComponent,
    p_ProcessId,
    v_Started,
    v_Ended,
    v_Result,
    v_ErrorMessage,
    v_Inserted,
    v_Updated,
    -1
  );

END;