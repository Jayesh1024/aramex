-- ==========================================================================================
-- Routine:     dv_Load_CT_SAT_Label_PickupRequests_AU
-- Description: BQ port of [dv].[Load_CT_SAT_Label_PickupRequests_AU] — incremental UPDATE/INSERT
--              from `Staging_PickupRequest_AU_Stg` into `dv_SAT_Label_PickupRequest` (CountryCode = 1).
--              Purges rows older than 60 days for this country. Logs via `Staging_SaveLog`.
-- History:
--  24/11/2025  B. Woods        SQL Server original
--  [BQ]  2026-05-04          BigQuery MERGE + SaveLog
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_CT_SAT_Label_PickupRequests_AU`(
  IN p_ProcessID INT64
)
BEGIN
  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Component STRING DEFAULT '{{ project_id }}.{{ target_dataset_id }}.dv_Load_CT_SAT_Label_PickupRequests_AU';
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING DEFAULT 'Success';
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_Inserted INT64 DEFAULT 0;

  BEGIN
    DELETE FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_PickupRequest`
    WHERE SAFE_CAST(CreateDateUtc AS TIMESTAMP) < TIMESTAMP(DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY))
      AND CountryCode = 1;

    MERGE INTO `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_PickupRequest` AS Tgt
    USING (
      WITH prep AS (
        SELECT
          Src.Id AS SrcId,
          Src.LabelNumber,
          Src.CreateDateUtc,
          Src.ShouldPrintLabel,
          Src.PickupFranchiseeCode,
          Src.PickupCourierNumber,
          Src.CollectionDate,
          Src.CollectionCycle,
          Src.PickupName,
          Src.PickupPhone,
          Src.PickupEmail,
          Src.DeliveryName,
          Src.DeliveryPhone,
          Src.DeliveryEmail,
          Src.IsMessageSent,
          Src.Weight,
          Src.Width,
          Src.Height,
          Src.Length,
          Src.RequestingCustomerName,
          Src.CountryCode,
          Src.IsPrinted,
          Src.IsComplete,
          Src.ConsolidationGroupId,
          Src.CourierMessageResult,
          Src.ConsolidationDateUtc,
          Src.PickupSpecialInstructions,
          Src.DeliverySpecialInstructions,
          Src.HhcMessageId,
          Src.HasCourierRejected,
          Src.IsRegularCollection,
          Src.RequestingCustomerOesId,
          Src.IsCancelled,
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
          Src.DidNotAssignCourierDuringCreation,
          Src.IsReturnService,
          Src.IsParcelConnectPickupLocation,
          Src.SecondaryLabelNumber,
          Src.PickupSubDepotFranchiseeCode,
          Src.CubicWeight,
          Src.PickupCompany,
          Src.DeliveryCompany,
          Src.IsPriority,
          Src.SYS_CHANGE_VERSION,
          C.CountryName AS CountryName,
          `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(
            CONCAT(IFNULL(SUBSTR(Src.LabelNumber, 1, 12), ''), '^', IFNULL(CAST(Src.CountryCode AS STRING), ''), '^'),
            '^'
          ) AS PickupRequest_HSK,
          `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(IFNULL(Src.LabelNumber, ''), '^') AS LabelNo_HSK,
          `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(IFNULL(Src.PickupFranchiseeCode, ''), '^') AS FranchiseeCode_HSK,
          `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(
            CONCAT(IFNULL(Src.PickupFranchiseeCode, ''), '^', IFNULL(Src.PickupCourierNumber, '')),
            '^'
          ) AS Courier_HSK
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_PickupRequest_AU_Stg` AS Src
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` AS C
          ON C.CountryCode = Src.CountryCode
        WHERE Src.LabelNumber IS NOT NULL
      )
      SELECT * FROM prep
    ) AS Src
    ON Tgt.LabelNo = Src.LabelNumber
    WHEN MATCHED THEN
      UPDATE SET
        PickupRequest_HSK = Src.PickupRequest_HSK,
        LabelNo_HSK = Src.LabelNo_HSK,
        FranchiseeCode_HSK = Src.FranchiseeCode_HSK,
        Courier_HSK = Src.Courier_HSK,
        CreateDateUtc = Src.CreateDateUtc,
        ShouldPrintLabel = Src.ShouldPrintLabel,
        PickupFranchiseeCode = Src.PickupFranchiseeCode,
        PickupCourierNumber = Src.PickupCourierNumber,
        Country = Src.CountryName,
        CollectionDate = Src.CollectionDate,
        CollectionCycle = Src.CollectionCycle,
        PickupName = Src.PickupName,
        PickupPhone = Src.PickupPhone,
        PickupEmail = Src.PickupEmail,
        DeliveryName = Src.DeliveryName,
        DeliveryPhone = Src.DeliveryPhone,
        DeliveryEmail = Src.DeliveryEmail,
        IsMessageSent = Src.IsMessageSent,
        Weight = Src.Weight,
        Width = Src.Width,
        Height = Src.Height,
        Length = Src.Length,
        RequestingCustomerName = Src.RequestingCustomerName,
        CountryCode = Src.CountryCode,
        IsPrinted = Src.IsPrinted,
        IsComplete = Src.IsComplete,
        ConsolidationGroupId = Src.ConsolidationGroupId,
        CourierMessageResult = Src.CourierMessageResult,
        ConsolidationDateUtc = Src.ConsolidationDateUtc,
        PickupSpecialInstructions = Src.PickupSpecialInstructions,
        DeliverySpecialInstructions = Src.DeliverySpecialInstructions,
        HhcMessageId = Src.HhcMessageId,
        HasCourierRejected = Src.HasCourierRejected,
        IsRegularCollection = Src.IsRegularCollection,
        RequestingCustomerOesId = Src.RequestingCustomerOesId,
        IsCancelled = Src.IsCancelled,
        CancellationReason = Src.CancellationReason,
        CancellationTitle = Src.CancellationTitle,
        FutileScanDate = Src.FutileScanDate,
        NotReadyScanDate = Src.NotReadyScanDate,
        PickupScanDate = Src.PickupScanDate,
        MessageSentDateUtc = Src.MessageSentDateUtc,
        CourierMessageResultText = Src.CourierMessageResultText,
        RejectionReason = Src.RejectionReason,
        RejectionDate = Src.RejectionDate,
        InternalStatus = Src.InternalStatus,
        DidNotAssignCourierDuringCreation = Src.DidNotAssignCourierDuringCreation,
        IsReturnService = Src.IsReturnService,
        IsParcelConnectPickupLocation = Src.IsParcelConnectPickupLocation,
        SecondaryLabelNumber = Src.SecondaryLabelNumber,
        PickupSubDepotFranchiseeCode = Src.PickupSubDepotFranchiseeCode,
        CubicWeight = Src.CubicWeight,
        PickupCompany = Src.PickupCompany,
        DeliveryCompany = Src.DeliveryCompany,
        IsPriority = Src.IsPriority,
        Loaded = v_Loaded,
        ProcessId = p_ProcessID,
        RecordSourceId = Src.SrcId,
        RecordSource = 'PickupRequest_CT',
        SYS_CHANGE_VERSION = Src.SYS_CHANGE_VERSION
    WHEN NOT MATCHED BY TARGET THEN
      INSERT (
        PickupRequest_HSK,
        LabelNo_HSK,
        FranchiseeCode_HSK,
        Courier_HSK,
        CreateDateUtc,
        ShouldPrintLabel,
        PickupFranchiseeCode,
        PickupCourierNumber,
        LabelNo,
        Country,
        CollectionDate,
        CollectionCycle,
        PickupName,
        PickupPhone,
        PickupEmail,
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
        Loaded,
        ProcessId,
        RecordSourceId,
        RecordSource,
        SYS_CHANGE_VERSION
      )
      VALUES (
        Src.PickupRequest_HSK,
        Src.LabelNo_HSK,
        Src.FranchiseeCode_HSK,
        Src.Courier_HSK,
        Src.CreateDateUtc,
        Src.ShouldPrintLabel,
        Src.PickupFranchiseeCode,
        Src.PickupCourierNumber,
        Src.LabelNumber,
        Src.CountryName,
        Src.CollectionDate,
        Src.CollectionCycle,
        Src.PickupName,
        Src.PickupPhone,
        Src.PickupEmail,
        Src.DeliveryName,
        Src.DeliveryPhone,
        Src.DeliveryEmail,
        Src.IsMessageSent,
        Src.Weight,
        Src.Width,
        Src.Height,
        Src.Length,
        Src.RequestingCustomerName,
        Src.CountryCode,
        Src.IsPrinted,
        Src.IsComplete,
        Src.ConsolidationGroupId,
        Src.CourierMessageResult,
        Src.ConsolidationDateUtc,
        Src.PickupSpecialInstructions,
        Src.DeliverySpecialInstructions,
        Src.HhcMessageId,
        Src.HasCourierRejected,
        Src.IsRegularCollection,
        Src.RequestingCustomerOesId,
        Src.IsCancelled,
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
        Src.DidNotAssignCourierDuringCreation,
        Src.IsReturnService,
        Src.IsParcelConnectPickupLocation,
        Src.SecondaryLabelNumber,
        Src.PickupSubDepotFranchiseeCode,
        Src.CubicWeight,
        Src.PickupCompany,
        Src.DeliveryCompany,
        Src.IsPriority,
        v_Loaded,
        p_ProcessID,
        Src.SrcId,
        '',
        Src.SYS_CHANGE_VERSION
      );

    SET v_Inserted = @@row_count;

  EXCEPTION WHEN ERROR THEN
    SET v_Result = 'Failed';
    SET v_ErrorMessage = @@error.message;
  END;

  SET v_Ended = CURRENT_DATETIME();
  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
    v_Component,
    p_ProcessID,
    v_Started,
    v_Ended,
    v_Result,
    v_ErrorMessage,
    v_Inserted,
    -1,
    -1
  );
END;
