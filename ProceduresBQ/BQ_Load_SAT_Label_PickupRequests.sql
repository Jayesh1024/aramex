CREATE OR REPLACE PROCEDURE `dv.Load_SAT_Label_PickupRequests`(
    IN p_ProcessID INT64
)
BEGIN
    -- ------------------------------------------------------------------------------------------
    -- Routine:     Load_SAT_Label_PickupRequests
    -- Description: Full refresh of SAT_Label_PickupRequest from Staging
    -- History:
    --  17/01/2024  B. Woods / AI   Routine written and converted to BigQuery
    -- ------------------------------------------------------------------------------------------

    DECLARE v_Component STRING DEFAULT 'dv.Load_SAT_Label_PickupRequests';
    DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Ended TIMESTAMP;
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING DEFAULT NULL;
    DECLARE v_Inserted INT64 DEFAULT 0;

    BEGIN
        -- 1. Truncate target table (BigQuery standard for full refresh)
        TRUNCATE TABLE `dv.SAT_Label_PickupRequest`;

        -- 2. Insert transformed data
        INSERT INTO `dv.SAT_Label_PickupRequest` (
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
            -- Hashing Logic: Mimicking dbo.GetHashKey using SHA256
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
            'PickupRequest_Stg' AS RecordSource -- Hardcoded Source string
        FROM `Staging.PickupRequest_Stg` AS Src
        LEFT JOIN `dbo.Dim_Country` AS C ON C.CountryCode = Src.CountryCode
        WHERE Src.LabelNumber IS NOT NULL;

        SET v_Inserted = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Final Log Call
    SET v_Ended = CURRENT_TIMESTAMP();
    
    CALL `Staging.SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,
        v_Ended,
        v_Result,
        v_ErrorMessage,
        v_Inserted, -- Inserted
        0,          -- Updated
        -1          -- Status
    );

END;