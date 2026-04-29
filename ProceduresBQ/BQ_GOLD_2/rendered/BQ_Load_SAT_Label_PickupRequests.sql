CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_SAT_Label_PickupRequests`(
    IN p_ProcessID INT64
)
BEGIN
    -- ------------------------------------------------------------------------------------------
    -- Routine:     dv_Load_SAT_Label_PickupRequests
    -- Description: Full refresh of dv_SAT_Label_PickupRequest from Staging
    -- ------------------------------------------------------------------------------------------

    DECLARE v_Component STRING DEFAULT 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_Load_SAT_Label_PickupRequests';
    
    -- OPTION 2: Use DATETIME instead of TIMESTAMP
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Ended DATETIME;
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING DEFAULT NULL;
    DECLARE v_Inserted INT64 DEFAULT 0;

    BEGIN
        -- 1. Truncate target table
        TRUNCATE TABLE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_PickupRequest`;

        -- 2. Insert transformed data
        INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_PickupRequest` (
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
            -- Hashing Logic (Using SHA256 directly for BYTES columns)
            SHA256(CONCAT(IFNULL(SUBSTR(Src.LabelNumber, 1, 12), ''), '^', IFNULL(CAST(Src.CountryCode AS STRING), ''), '^')) AS PickupRequest_HSK,
            SHA256(IFNULL(Src.LabelNumber, '')) AS LabelNo_HSK,
            SHA256(IFNULL(Src.PickupFranchiseeCode, '')) AS FranchiseeCode_HSK,
            SHA256(CONCAT(IFNULL(Src.PickupFranchiseeCode, ''), '^', IFNULL(Src.PickupCourierNumber, ''))) AS Courier_HSK,
            
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
            v_Started AS Loaded, -- Using the DATETIME variable
            p_ProcessID AS ProcessId,
            Src.ID AS RecordSourceID,
            'PickupRequest_Stg' AS RecordSource 
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_PickupRequest_Stg` AS Src
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Country` AS C 
            ON C.CountryCode = Src.CountryCode
        WHERE Src.LabelNumber IS NOT NULL;

        SET v_Inserted = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Final Log Call (Option 2: Using DATETIME and CURRENT_DATETIME)
    SET v_Ended = CURRENT_DATETIME();
    
    CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
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