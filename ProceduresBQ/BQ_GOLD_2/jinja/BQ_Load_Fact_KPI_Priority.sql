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

  DECLARE v_Component     STRING DEFAULT 'dbo_Load_Fact_KPI_Priority';
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
    WITH BusinessDayArrays AS (
      -- -----------------------------------------------------------------------
      -- Build an array of valid business days per franchise,
      -- excluding dates in dbo_KPIExcludedDates for that franchise.
      -- -----------------------------------------------------------------------
      SELECT
        ex.Franchise,
        ARRAY_AGG(dt.Calendar_Date ORDER BY dt.Calendar_Date) AS CalendarDates
      FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Time` dt
      LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIExcludedDates` ex
        ON  dt.Calendar_Date = ex.Date
        AND ex.Comment       IS NULL
      WHERE dt.week_day_flag = 'Y'
      GROUP BY ex.Franchise
    ),
    Base AS (
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
        MF.ToPostalCode,
        CAST(COALESCE(K.KPILEA, 0) AS INT64)                               AS lea_offset,
        CAST(COALESCE(K.KPIDelivery, 0) AS INT64)                          AS del_offset,
        CAST(COALESCE(K.KPILEA, 0) + COALESCE(K.KPIDelivery, 0) AS INT64) AS lea_del_offset,
        CAST(K.ActualDepartureDate AS DATE)                                AS dep_date,
        CAST(K.ActualArrivalDate AS DATE)                                  AS arr_date
      FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI_Daily` K
      LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF_partitioned` MF
        ON  MF.LabelNo     = K.LabelNo
        AND MF.IsCurrent   = 1
        AND MF.CountryCode = K.CountryCode
      WHERE K.ServiceType = 'P'
    )
    SELECT
      B.LabelNo,
      B.CountryCode,
      B.Category,
      B.ServiceType,
      B.CreatedOn,
      B.RealisedDate,
      B.SLA,
      B.KPIPickup,
      B.KPILEA,
      B.KPIDelivery,
      B.KPIPickupImpact,
      B.KPILEAImpact,
      B.KPIDeliveryImpact,
      B.DueDate,
      B.KPIDepartureDate,

      -- KPIArrivalDate: nth business day >= ActualDepartureDate, offset by KPILEA
      BD_dep.CalendarDates[SAFE_OFFSET(
        CAST((SELECT COUNT(*) FROM UNNEST(BD_dep.CalendarDates) AS d WHERE d < B.dep_date) + B.lea_offset AS INT64)
      )]                                            AS KPIArrivalDate,

      -- KPIAttemptedDate: nth business day >= ActualArrivalDate, offset by KPIDelivery
      BD_arr.CalendarDates[SAFE_OFFSET(
        CAST((SELECT COUNT(*) FROM UNNEST(BD_arr.CalendarDates) AS d WHERE d < B.arr_date) + B.del_offset AS INT64)
      )]                                            AS KPIAttemptedDate,

      -- KPIAttemptedDateAdjust: nth business day >= ActualDepartureDate, offset by KPILEA + KPIDelivery
      BD_dep.CalendarDates[SAFE_OFFSET(
        CAST((SELECT COUNT(*) FROM UNNEST(BD_dep.CalendarDates) AS d WHERE d < B.dep_date) + B.lea_del_offset AS INT64)
      )]                                            AS KPIAttemptedDateAdjust,

      B.ActualDepartureDate,
      B.ActualDepartureRF,
      B.ActualDepartureCF,
      B.ActualDepartureType,
      B.ActualDepartureStatus,
      B.ActualFirstArrivalDate,
      B.ActualFirstArrivalRF,
      B.ActualFirstArrivalCF,
      B.ActualFirstArrivalType,
      B.ActualFirstArrivalStatus,
      B.ActualArrivalDate,
      B.ActualArrivalRF,
      B.ActualArrivalCF,
      B.ActualArrivalType,
      B.ActualArrivalStatus,
      B.ActualAttemptedDate,
      B.ActualAttemptedRF,
      B.ActualAttemptedCF,
      B.ActualAttemptedType,
      B.ActualAttemptedStatus,
      B.ActualDeliveryScanDate,
      B.ActualDeliveryRF,
      B.ActualDeliveryCF,
      B.ActualDeliveryType,
      B.ActualDeliveryStatus,
      B.LastScanDate,
      B.LastScanRF,
      B.LastScanCF,
      B.LastScanType,
      B.LastScanStatus,
      B.MISScanDate,
      B.MISRF,
      B.LastUpdated,
      B.ProcessId,
      B.FromRf,
      B.FromCf,
      B.ToRf,
      B.ToCf,
      B.CustomerId,
      B.ToLocality,
      B.ToPostalCode
    FROM Base B
    LEFT JOIN BusinessDayArrays BD_dep
      ON BD_dep.Franchise = B.ToRf
    LEFT JOIN BusinessDayArrays BD_arr
      ON BD_arr.Franchise = B.ToRf;

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
  -- -----------------------------------------------------------------------
  SET v_Ended        = CURRENT_DATETIME();
  SET v_SubComponent = CONCAT(v_Component, ' (', v_Step, ')');

  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
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