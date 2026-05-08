-- ==========================================================================================
-- Routine:     Staging_load_PickupRequest_AU_Stg
-- Description: Loads `Staging_PickupRequest_AU_Stg` from silver `FastwayGlobal_1_PickupDashboard_PickupRequest`
--              filtered by silver `ingestion_time` vs watermark from `Staging_LoadControl.LastValue`
--              (passed as `p_ingestion_time` ISO string). NULL / empty / 'None' → 60-day lookback.
-- History:
--  [BQ]  2026-05-04  Consolidated LoadPickupRequests migration (replaces CT + IsReload in DAG).
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.Staging_load_PickupRequest_AU_Stg`(
  IN p_ingestion_time STRING
)
BEGIN
  DECLARE cutoff DATETIME;
  SET cutoff = (
    SELECT CASE
      WHEN p_ingestion_time IS NULL
        OR TRIM(p_ingestion_time) = ''
        OR LOWER(TRIM(p_ingestion_time)) = 'none'
      THEN DATETIME_SUB(CURRENT_DATETIME(), INTERVAL 60 DAY)
      ELSE SAFE_CAST(p_ingestion_time AS DATETIME)
    END
  );

  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_PickupRequest_AU_Stg` (
    Id,
    CreateDateUtc,
    ingestion_time,
    ShouldPrintLabel,
    PickupFranchiseeCode,
    PickupCourierNumber,
    LabelNumber,
    CollectionDate,
    CollectionCycle,
    PickupAddress1,
    PickupAddress2,
    PickupSuburb,
    PickupPostcode,
    PickupName,
    PickupPhone,
    PickupEmail,
    DeliveryAddress1,
    DeliveryAddress2,
    DeliverySuburb,
    DeliveryPostcode,
    DeliveryName,
    DeliveryPhone,
    DeliveryEmail,
    IsMessageSent,
    Weight,
    Width,
    Height,
    Length,
    RequestingCustomerName,
    CountryCode,
    IsPrinted,
    IsComplete,
    ConsolidationGroupId,
    CourierMessageResult,
    ConsolidationDateUtc,
    PickupSpecialInstructions,
    DeliverySpecialInstructions,
    HhcMessageId,
    HasCourierRejected,
    IsRegularCollection,
    RequestingCustomerOesId,
    IsCancelled,
    CancellationReason,
    CancellationTitle,
    FutileScanDate,
    NotReadyScanDate,
    PickupScanDate,
    MessageSentDateUtc,
    CourierMessageResultText,
    RejectionReason,
    RejectionDate,
    InternalStatus,
    DidNotAssignCourierDuringCreation,
    IsReturnService,
    IsParcelConnectPickupLocation,
    SecondaryLabelNumber,
    PickupSubDepotFranchiseeCode,
    CubicWeight,
    PickupCompany,
    DeliveryCompany,
    IsPriority,
    SYS_CHANGE_VERSION
  )
  SELECT
    Src.Id,
    Src.CreateDateUtc,
    Src.ingestion_time,
    CAST(Src.ShouldPrintLabel AS INT64) AS ShouldPrintLabel,
    Src.PickupFranchiseeCode,
    Src.PickupCourierNumber,
    Src.LabelNumber,
    Src.CollectionDate,
    Src.CollectionCycle,
    Src.PickupAddress1,
    Src.PickupAddress2,
    Src.PickupSuburb,
    Src.PickupPostcode,
    Src.PickupName,
    Src.PickupPhone,
    Src.PickupEmail,
    Src.DeliveryAddress1,
    Src.DeliveryAddress2,
    Src.DeliverySuburb,
    Src.DeliveryPostcode,
    Src.DeliveryName,
    Src.DeliveryPhone,
    Src.DeliveryEmail,
    CAST(Src.IsMessageSent AS INT64) AS IsMessageSent,
    Src.Weight,
    Src.Width,
    Src.Height,
    Src.Length,
    Src.RequestingCustomerName,
    Src.CountryCode,
    CAST(Src.IsPrinted AS INT64) AS IsPrinted,
    CAST(Src.IsComplete AS INT64) AS IsComplete,
    CAST(Src.ConsolidationGroupId AS BYTES) AS ConsolidationGroupId,
    Src.CourierMessageResult,
    Src.ConsolidationDateUtc,
    Src.PickupSpecialInstructions,
    Src.DeliverySpecialInstructions,
    Src.HhcMessageId,
    CAST(Src.HasCourierRejected AS INT64) AS HasCourierRejected,
    CAST(Src.IsRegularCollection AS INT64) AS IsRegularCollection,
    Src.RequestingCustomerOesId,
    CAST(Src.IsCancelled AS INT64) AS IsCancelled,
    Src.CancellationReason,
    Src.CancellationTitle,
    Src.FutileScanDate,
    Src.NotReadyScanDate,
    Src.PickupScanDate,
    Src.MessageSentDateUtc,
    Src.CourierMessageResultText,
    Src.RejectionReason,
    Src.RejectionDate,
    Src.InternalStatus,
    CAST(Src.DidNotAssignCourierDuringCreation AS INT64) AS DidNotAssignCourierDuringCreation,
    CAST(Src.IsReturnService AS INT64) AS IsReturnService,
    CAST(Src.IsParcelConnectPickupLocation AS INT64) AS IsParcelConnectPickupLocation,
    Src.SecondaryLabelNumber,
    Src.PickupSubDepotFranchiseeCode,
    Src.CubicWeight,
    Src.PickupCompany,
    Src.DeliveryCompany,
    CAST(Src.IsPriority AS INT64) AS IsPriority,
    CAST(0 AS INT64) AS SYS_CHANGE_VERSION
  FROM `{{ project_id }}.{{ source_dataset_id }}.FastwayGlobal_1_PickupDashboard_PickupRequest` AS Src
  WHERE SAFE_CAST(Src.ingestion_time AS DATETIME) > cutoff;
END;
