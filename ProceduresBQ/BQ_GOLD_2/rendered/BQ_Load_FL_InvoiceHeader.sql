-- ==========================================================================================
-- Routine:     Load LSAT_FL_InvoiceHeader
-- Description: Loads FWFastwayDW fl_InvoiceHeader into [dv].[LSAT_FL_InvoiceHeader]
-- Example:     Exec [dv].[Load_FL_InvoiceHeader]  123 
-- History:
--  21/07/2025  B. Woods        Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_FL_InvoiceHeader`(IN p_ProcessId INT64, IN p_RecordSource STRING)
BEGIN
  /*
  ** Routine: Load_FL_InvoiceHeader
  ** Description: Loads FWFastwayDW fl_InvoiceHeader into dv_LSAT_FL_InvoiceHeader
  */

  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Component STRING DEFAULT 'dv_Load_FL_InvoiceHeader';
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING;
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_Inserted INT64 DEFAULT 0;
  DECLARE v_Updated INT64 DEFAULT 0;
  BEGIN
    -- MERGE Rule: Use single MERGE for SP containing both INSERT + UPDATE
    MERGE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_FL_InvoiceHeader` AS Tgt
    USING `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_fl_InvoiceHeader_Stg` AS Src
    ON Tgt.InvoiceHeaderId = Src.InvoiceHeaderId
    WHEN MATCHED AND (
      Tgt.BatchId IS DISTINCT FROM Src.BatchId OR
      Tgt.RF IS DISTINCT FROM Src.RF OR
      Tgt.ParentRF IS DISTINCT FROM Src.ParentRF OR
      Tgt.CountryId IS DISTINCT FROM Src.CountryId OR
      Tgt.CustomerId IS DISTINCT FROM Src.CustomerId OR
      Tgt.ParentCustomerId IS DISTINCT FROM Src.ParentCustomerId OR
      Tgt.InvoiceNo IS DISTINCT FROM Src.InvoiceNo OR
      Tgt.InvoiceDate IS DISTINCT FROM Src.InvoiceDate OR
      Tgt.Price IS DISTINCT FROM Src.Price OR
      Tgt.Tax IS DISTINCT FROM Src.Tax OR
      Tgt.Total IS DISTINCT FROM Src.Total OR
      Tgt.GroupPrice IS DISTINCT FROM Src.GroupPrice OR
      Tgt.GroupTax IS DISTINCT FROM Src.GroupTax OR
      Tgt.GroupTotal IS DISTINCT FROM Src.GroupTotal OR
      Tgt.Released IS DISTINCT FROM Src.Released OR
      Tgt.RFLegalEntity IS DISTINCT FROM Src.RFLegalEntity OR
      Tgt.ParentRFLegalEntity IS DISTINCT FROM Src.ParentRFLegalEntity OR
      Tgt.CFLegalEntity IS DISTINCT FROM Src.CFLegalEntity OR
      Tgt.Level IS DISTINCT FROM Src.Level OR
      Tgt.BankProcess IS DISTINCT FROM Src.BankProcess OR
      Tgt.ParentInvoiceHeaderId IS DISTINCT FROM Src.ParentInvoiceHeaderId OR
      Tgt.CFOverride IS DISTINCT FROM Src.CFOverride OR
      Tgt.CFOverrideBasePriceCommPercent IS DISTINCT FROM Src.CFOverrideBasePriceCommPercent OR
      Tgt.CFOverrideExcessPriceCommPercent IS DISTINCT FROM Src.CFOverrideExcessPriceCommPercent OR
      Tgt.SelectedUI IS DISTINCT FROM Src.SelectedUI OR
      Tgt.EnterpriseFastlabelType IS DISTINCT FROM Src.EnterpriseFastlabelType OR
      Tgt.DueDate IS DISTINCT FROM Src.DueDate OR
      Tgt.CloseDate IS DISTINCT FROM Src.CloseDate OR
      Tgt.TotalPaid IS DISTINCT FROM Src.TotalPaid OR
      Tgt.CourierNumber IS DISTINCT FROM Src.CourierNumber OR
      Tgt.GroupTaxExempt IS DISTINCT FROM Src.GroupTaxExempt
    )
    THEN UPDATE SET
      BatchId = Src.BatchId,
      RF = Src.RF,
      ParentRF = Src.ParentRF,
      CountryId = Src.CountryId,
      CustomerId = Src.CustomerId,
      ParentCustomerId = Src.ParentCustomerId,
      InvoiceNo = Src.InvoiceNo,
      InvoiceDate = Src.InvoiceDate,
      Price = Src.Price,
      Tax = Src.Tax,
      Total = Src.Total,
      GroupPrice = Src.GroupPrice,
      GroupTax = Src.GroupTax,
      GroupTotal = Src.GroupTotal,
      Released = Src.Released,
      RFLegalEntity = Src.RFLegalEntity,
      ParentRFLegalEntity = Src.ParentRFLegalEntity,
      CFLegalEntity = Src.CFLegalEntity,
      Level = Src.Level,
      BankProcess = Src.BankProcess,
      ParentInvoiceHeaderId = Src.ParentInvoiceHeaderId,
      CFOverride = Src.CFOverride,
      CFOverrideBasePriceCommPercent = Src.CFOverrideBasePriceCommPercent,
      CFOverrideExcessPriceCommPercent = Src.CFOverrideExcessPriceCommPercent,
      SelectedUI = Src.SelectedUI,
      EnterpriseFastlabelType = Src.EnterpriseFastlabelType,
      DueDate = Src.DueDate,
      CloseDate = Src.CloseDate,
      TotalPaid = Src.TotalPaid,
      CourierNumber = Src.CourierNumber,
      GroupTaxExempt = Src.GroupTaxExempt,
      Loaded = v_Loaded,
      ProcessId = p_ProcessId,
      RecordSource = p_RecordSource
    WHEN NOT MATCHED THEN
      INSERT (
        InvoiceHeaderId, BatchId, RF, ParentRF, CountryId, CustomerId, ParentCustomerId, InvoiceNo, InvoiceDate, Price, Tax, Total, GroupPrice, GroupTax, GroupTotal, Released, RFLegalEntity, ParentRFLegalEntity, CFLegalEntity, Level, BankProcess, ParentInvoiceHeaderId, CFOverride, CFOverrideBasePriceCommPercent, CFOverrideExcessPriceCommPercent, SelectedUI, EnterpriseFastlabelType, DueDate, CloseDate, TotalPaid, CourierNumber, GroupTaxExempt, Loaded, ProcessId, RecordSource
      )
      VALUES (
        Src.InvoiceHeaderId, Src.BatchId, Src.RF, Src.ParentRF, Src.CountryId, Src.CustomerId, Src.ParentCustomerId, Src.InvoiceNo, Src.InvoiceDate, Src.Price, Src.Tax, Src.Total, Src.GroupPrice, Src.GroupTax, Src.GroupTotal, Src.Released, Src.RFLegalEntity, Src.ParentRFLegalEntity, Src.CFLegalEntity, Src.Level, Src.BankProcess, Src.ParentInvoiceHeaderId, Src.CFOverride, Src.CFOverrideBasePriceCommPercent, Src.CFOverrideExcessPriceCommPercent, Src.SelectedUI, Src.EnterpriseFastlabelType, Src.DueDate, Src.CloseDate, Src.TotalPaid, Src.CourierNumber, Src.GroupTaxExempt, v_Loaded, p_ProcessId, p_RecordSource
      );

    -- When MERGE is used: @@row_count returns total rows affected (inserts + updates combined). 
    -- Assign to v_Updated; leave v_Inserted = 0.
    SET v_Updated = @@row_count;
    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result = 'Failed';
    SET v_ErrorMessage = @@error.message;
  END;

  -- Logging Rule: Every translated SP MUST end with CALL Staging_SaveLog covering success and failure
  SET v_Ended = CURRENT_DATETIME();
  CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
    v_Component,
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