{#-- ==========================================================================================
Routine:     dv_Load_SAT_Label_PickupRequests
Description: Loads relationships into LNK_RuralOnforwards 
History:
  17/01/2024  B. Woods        Routine Written
========================================================================================== --#}

CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id}}.dv_Load_SAT_Label_PickupRequests`(
    IN p_ProcessID INT64
)
BEGIN
    -- ------------------------------------------------------------------------------------------
    -- Routine:     dv_Load_SAT_Label_PickupRequests
    -- Description: Full refresh of dv_SAT_Label_PickupRequest from Staging
    -- ------------------------------------------------------------------------------------------

    DECLARE v_Component STRING DEFAULT '{{ project_id }}.{{ target_dataset_id }}.dv_Load_SAT_Label_PickupRequests';
    DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Ended TIMESTAMP;
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING DEFAULT NULL;
    DECLARE v_Inserted INT64 DEFAULT 0;

    BEGIN
        -- 1. Truncate target table
        TRUNCATE TABLE `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_PickupRequest`;

        -- 2. Insert transformed data
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_PickupRequest` (
            PickupRequest_HSK, LabelNo_HSK, FranchiseeCode_HSK, Courier_HSK,
            CreateDateUtc, ShouldPrintLabel, PickupFranchiseeCode, PickupCourierNumber,
            LabelNo, Country, CollectionDate, CollectionCycle, PickupName, PickupPhone,
            PickupEmail, DeliveryName, DeliveryPhone, DeliveryEmail, IsMessageSent,
            Weight, Width, Height, Length, RequestingCustomerName, CountryCode,
            IsPrinted, IsComplete, ConsolidationGroupId, CourierMessageResult,
            ConsolidationDateUtc, PickupSpecialInstructions, DeliverySpecialInstructions,
            HhcMessageId, HasCourierRejected, IsRegularCollection, RequestingCustomerOesId,
            IsCancelled, CancellationReason, CancellationTitle, FutileScanDate,
            NotReadyScanDate, PickupScanDate, MessageSentDateUtc, CourierMessageResultText,
            RejectionReason, RejectionDate, InternalStatus, DidNotAssignCourierDuringCreation,
            IsReturnService, IsParcelConnectPickupLocation, SecondaryLabelNumber,
            PickupSubDepotFranchiseeCode, CubicWeight, PickupCompany, DeliveryCompany,
            IsPriority, Loaded, ProcessId, RecordSourceId, RecordSource
        )
        SELECT 
            -- Hashing Logic using BigQuery native SHA256
            UPPER(TO_HEX(SHA256(CONCAT(IFNULL(SUBSTR(Src.LabelNumber, 1, 12), ''), '^', IFNULL(CAST(Src.CountryCode AS STRING), ''), '^')))) AS PickupRequest_HSK,
            UPPER(TO_HEX(SHA256(IFNULL(Src.LabelNumber, '')))) AS LabelNo_HSK,
            UPPER(TO_HEX(SHA256(IFNULL(Src.PickupFranchiseeCode, '')))) AS FranchiseeCode_HSK,
            UPPER(TO_HEX(SHA256(CONCAT(IFNULL(Src.PickupFranchiseeCode, ''), '^', IFNULL(Src.PickupCourierNumber, ''))))) AS Courier_HSK,
            
            Src.CreateDateUtc, Src.ShouldPrintLabel, Src.PickupFranchiseeCode, Src.PickupCourierNumber,
            Src.LabelNumber, C.CountryName, Src.CollectionDate, Src.CollectionCycle, 
            Src.PickupName, Src.PickupPhone, Src.PickupEmail, Src.DeliveryName, 
            Src.DeliveryPhone, Src.DeliveryEmail, Src.IsMessageSent,
            Src.Weight, Src.Width, Src.Height, Src.Length, Src.RequestingCustomerName, 
            Src.CountryCode, Src.IsPrinted, Src.IsComplete, Src.ConsolidationGroupId, 
            Src.CourierMessageResult, Src.ConsolidationDateUtc, Src.PickupSpecialInstructions, 
            Src.DeliverySpecialInstructions, Src.HhcMessageId, Src.HasCourierRejected, 
            Src.IsRegularCollection, Src.RequestingCustomerOesId, Src.IsCancelled, 
            Src.CancellationReason, Src.CancellationTitle, Src.FutileScanDate,
            Src.NotReadyScanDate, Src.PickupScanDate, Src.MessageSentDateUtc, 
            Src.CourierMessageResultText, Src.RejectionReason, Src.RejectionDate, 
            Src.InternalStatus, Src.DidNotAssignCourierDuringCreation, Src.IsReturnService, 
            Src.IsParcelConnectPickupLocation, Src.SecondaryLabelNumber, 
            Src.PickupSubDepotFranchiseeCode, Src.CubicWeight, Src.PickupCompany, 
            Src.DeliveryCompany, Src.IsPriority,
            v_Started AS Loaded,
            p_ProcessID AS ProcessId,
            Src.ID AS RecordSourceID,
            'PickupRequest_Stg' AS RecordSource 
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_PickupRequest_Stg` AS Src
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` AS C 
            ON C.CountryCode = Src.CountryCode
        WHERE Src.LabelNumber IS NOT NULL;

        SET v_Inserted = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Final Log Call
    SET v_Ended = CURRENT_TIMESTAMP();
    
    CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,
        v_Ended,
        v_Result,
        v_ErrorMessage,
        v_Inserted, 
        0,          
        IF(v_Result = 'Success', 0, -1)
    );

END;