CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_PickupRequest_Stg`(
)
BEGIN
  DECLARE startDate DATETIME;
  DECLARE NextID INT64;
  SET startDate = DATE_SUB(CURRENT_DATETIME(), INTERVAL 60 DAY);

  SET NextID = (
    SELECT ID
    FROM `{{ project_id }}.{{ source_dataset_id }}.FastwayGlobal_1_PickupDashboard_PickupRequest`
    WHERE CreateDateUtc > startDate
    ORDER BY CreateDateUtc
    LIMIT 1
  );

  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_PickupRequest_Stg`
  SELECT Id
  
        ,CreateDateUtc
        ,CAST(ShouldPrintLabel AS INT64) AS ShouldPrintLabel
        ,PickupFranchiseeCode
        ,PickupCourierNumber
        ,LabelNumber
        ,CollectionDate
        ,CollectionCycle
        ,PickupAddress1
        ,PickupAddress2
        ,PickupSuburb
        ,PickupPostcode
        ,PickupName
        ,PickupPhone
        ,PickupEmail
        ,DeliveryAddress1
        ,DeliveryAddress2
        ,DeliverySuburb
        ,DeliveryPostcode
        ,DeliveryName
        ,DeliveryPhone
        ,DeliveryEmail
        ,CAST(IsMessageSent AS INT64) AS IsMessageSent
        ,Weight
        ,Width
        ,Height
        ,Length
        ,RequestingCustomerName
        ,CountryCode
        ,CAST(IsPrinted AS INT64) AS IsPrinted
        ,CAST(IsComplete AS INT64) AS IsComplete
        ,CAST(ConsolidationGroupId AS BYTES) AS ConsolidationGroupId
        ,CourierMessageResult
        ,ConsolidationDateUtc
        ,PickupSpecialInstructions
        ,DeliverySpecialInstructions
        ,HhcMessageId
        ,CAST(HasCourierRejected AS INT64) AS HasCourierRejected
        ,CAST(IsRegularCollection AS INT64) AS IsRegularCollection
        ,RequestingCustomerOesId
        ,CAST(IsCancelled AS INT64) AS IsCancelled
        ,CancellationReason
        ,CancellationTitle
        ,FutileScanDate
        ,NotReadyScanDate
        ,PickupScanDate
        ,MessageSentDateUtc
        ,CourierMessageResultText
        ,RejectionReason
        ,RejectionDate
        ,InternalStatus
        ,CAST(DidNotAssignCourierDuringCreation AS INT64) AS DidNotAssignCourierDuringCreation
        ,CAST(IsReturnService AS INT64) AS IsReturnService
        ,CAST(IsParcelConnectPickupLocation AS INT64) AS IsParcelConnectPickupLocation
        ,SecondaryLabelNumber
        ,PickupSubDepotFranchiseeCode
        ,CubicWeight
        ,PickupCompany
        ,DeliveryCompany
        ,CAST(IsPriority AS INT64) AS IsPriority
    FROM `{{ project_id }}.{{ source_dataset_id }}.FastwayGlobal_1_PickupDashboard_PickupRequest`
    WHERE ID >= NextID
  ;

END;