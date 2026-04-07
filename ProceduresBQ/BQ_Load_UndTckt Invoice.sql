{#-- ==========================================================================================
Routine:     dbo_Load_UndTckt_Invoice
Description: Loads any under ticketed invoices into dbo_FMS_UndTcktInvoice
History:
  01/07/2025  B. Woods        Routine Written
========================================================================================== --#}

CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id}}.dbo_Load_UndTckt_Invoice`(
    IN p_ProcessID INT64
)
BEGIN
    -- ------------------------------------------------------------------------------------------
    -- Routine:     dbo_Load_UndTckt_Invoice
    -- Description: Upserts under-ticketed invoices into dbo_FMS_UndTcktInvoice
    -- ------------------------------------------------------------------------------------------

    DECLARE v_Component STRING DEFAULT '{{ project_id }}.{{ target_dataset_id }}.dbo_Load_UndTckt_Invoice';
    DECLARE v_Step STRING DEFAULT 'Upsert';
    DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Ended TIMESTAMP;
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING DEFAULT NULL;
    DECLARE v_AffectedRows INT64 DEFAULT 0;

    BEGIN
        -- Using MERGE to synchronize the Target table with the Staging data
        MERGE INTO `{{ project_id }}.{{ target_dataset_id }}.dbo_FMS_UndTcktInvoice` AS Tgt
        USING `{{ project_id }}.{{ target_dataset_id }}.Staging_FMS_UndTcktInvoice_Stg` AS Src
        ON Tgt.UnderTickId = Src.UnderTickId
        
        WHEN MATCHED THEN
            UPDATE SET
                CountryId = Src.CountryId,
                LoggedByRF = Src.LoggedByRF,
                UpdatedByRF = Src.UpdatedByRF,
                PRF = Src.PRF,
                SaleRF = Src.SaleRF,
                Label = Src.Label,
                CustomerId = Src.CustomerId,
                CustomerName = Src.CustomerName,
                SystemDeadWeight = Src.SystemDeadWeight,
                SystemLength = Src.SystemLength,
                SystemWidth = Src.SystemWidth,
                SystemHeight = Src.SystemHeight,
                SystemWeightCubic = Src.SystemWeightCubic,
                SystemPrice = Src.SystemPrice,
                NewDeadWeight = Src.NewDeadWeight,
                NewLength = Src.NewLength,
                Source = Src.Source,
                Note = Src.Note,
                Date = Src.Date,
                UserIdRecorded = Src.UserIdRecorded,
                BankedFMSCustomerId = Src.BankedFMSCustomerId,
                Procssed = Src.Procssed,
                DeliveryRF = Src.DeliveryRF,
                NumberOfExcess = Src.NumberOfExcess,
                NewExcessLabels = Src.NewExcessLabels,
                RepricedAutomatically = Src.RepricedAutomatically,
                FMSOriginalInvoiceNumber = Src.FMSOriginalInvoiceNumber,
                FMSBankedInvoiceAmount = Src.FMSBankedInvoiceAmount,
                FMSCustomerInvoiceMonthlyBatch = Src.FMSCustomerInvoiceMonthlyBatch,
                FMSCustomerInvoiceNumber = Src.FMSCustomerInvoiceNumber,
                FMSCustomerIdInvoiced = Src.FMSCustomerIdInvoiced,
                FMSCustomerInvoiceAmount = Src.FMSCustomerInvoiceAmount,
                DLBSInvoiceMonthlyBatch = Src.DLBSInvoiceMonthlyBatch,
                DLBSInvoiceNumber = Src.DLBSInvoiceNumber,
                DLBSInvoiceRFFrom = Src.DLBSInvoiceRFFrom,
                DLBSInvoiceRFTo = Src.DLBSInvoiceRFTo,
                DLBSInvoiceAmount = Src.DLBSInvoiceAmount,
                LeaMonthlyBatch = Src.LeaMonthlyBatch,
                LeaInvoiceNumber = Src.LeaInvoiceNumber,
                LeaChargeAmount = Src.LeaChargeAmount,
                Locked = Src.Locked,
                Repriced = Src.Repriced,
                InvoicePrice = Src.InvoicePrice,
                ExcessPrice = Src.ExcessPrice,
                Invoiced = Src.Invoiced,
                NewPriceIncGST = Src.NewPriceIncGST,
                MultiplePriceOptions = Src.MultiplePriceOptions,
                NewColour = Src.NewColour,
                RCTIInvoiceNumber = Src.RCTIInvoiceNumber,
                InvException = Src.InvException,
                InvExceptionReason = Src.InvExceptionReason,
                ToLng = Src.ToLng,
                ToLat = Src.ToLat,
                ChildCharge = Src.ChildCharge

        WHEN NOT MATCHED THEN
            INSERT (
                UnderTickId, CountryId, LoggedByRF, UpdatedByRF, PRF, SaleRF, Label, CustomerId, CustomerName,
                SystemDeadWeight, SystemLength, SystemWidth, SystemHeight, SystemWeightCubic, SystemPrice,
                NewDeadWeight, NewLength, NewWidth, NewHeight, NewWeightCubic, NewPrice,
                FromAddress1, FromAddress2, FromAddress3, FromAddress4, FromAddress5, FromAddress6,
                ToAddress1, ToAddress2, ToAddress3, ToAddress4, ToAddress5, ToAddress6,
                Source, Note, Date, UserIdRecorded, BankedFMSCustomerId, Procssed, DeliveryRF,
                NumberOfExcess, NewExcessLabels, RepricedAutomatically, FMSOriginalInvoiceNumber,
                FMSBankedInvoiceAmount, FMSCustomerInvoiceMonthlyBatch, FMSCustomerInvoiceNumber,
                FMSCustomerIdInvoiced, FMSCustomerInvoiceAmount, DLBSInvoiceMonthlyBatch,
                DLBSInvoiceNumber, DLBSInvoiceRFFrom, DLBSInvoiceRFTo, DLBSInvoiceAmount,
                LeaMonthlyBatch, LeaInvoiceNumber, LeaChargeAmount, Locked, Repriced,
                InvoicePrice, ExcessPrice, Invoiced, NewPriceIncGST, MultiplePriceOptions,
                NewColour, RCTIInvoiceNumber, InvException, InvExceptionReason, ToLng, ToLat, ChildCharge
            )
            VALUES (
                Src.UnderTickId, Src.CountryId, Src.LoggedByRF, Src.UpdatedByRF, Src.PRF, Src.SaleRF, Src.Label, Src.CustomerId, Src.CustomerName,
                Src.SystemDeadWeight, Src.SystemLength, Src.SystemWidth, Src.SystemHeight, Src.SystemWeightCubic, Src.SystemPrice,
                Src.NewDeadWeight, Src.NewLength, Src.NewWidth, Src.NewHeight, Src.NewWeightCubic, Src.NewPrice,
                Src.FromAddress1, Src.FromAddress2, Src.FromAddress3, Src.FromAddress4, Src.FromAddress5, Src.FromAddress6,
                Src.ToAddress1, Src.ToAddress2, Src.ToAddress3, Src.ToAddress4, Src.ToAddress5, Src.ToAddress6,
                Src.Source, Src.Note, Src.Date, Src.UserIdRecorded, Src.BankedFMSCustomerId, Src.Procssed, Src.DeliveryRF,
                Src.NumberOfExcess, Src.NewExcessLabels, Src.RepricedAutomatically, Src.FMSOriginalInvoiceNumber,
                Src.FMSBankedInvoiceAmount, Src.FMSCustomerInvoiceMonthlyBatch, Src.FMSCustomerInvoiceNumber,
                Src.FMSCustomerIdInvoiced, Src.FMSCustomerInvoiceAmount, Src.DLBSInvoiceMonthlyBatch,
                Src.DLBSInvoiceNumber, Src.DLBSInvoiceRFFrom, Src.DLBSInvoiceRFTo, Src.DLBSInvoiceAmount,
                Src.LeaMonthlyBatch, Src.LeaInvoiceNumber, Src.LeaChargeAmount, Src.Locked, Src.Repriced,
                Src.InvoicePrice, Src.ExcessPrice, Src.Invoiced, Src.NewPriceIncGST, Src.MultiplePriceOptions,
                Src.NewColour, Src.RCTIInvoiceNumber, Src.InvException, Src.InvExceptionReason, Src.ToLng, Src.ToLat, Src.ChildCharge
            );

        SET v_AffectedRows = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = FORMAT('Failed (%s)', v_Step);
        SET v_ErrorMessage = @@error.message;
    END;

    SET v_Ended = CURRENT_TIMESTAMP();
    
    -- Final Log Call
    CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,
        v_Ended,
        v_Result,
        v_ErrorMessage,
        0,              
        v_AffectedRows, 
        IF(v_Result = 'Success', 0, -1)
    );

END;