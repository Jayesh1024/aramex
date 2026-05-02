-- ==========================================================================================
-- Routine:     Load_LSAT_InvoiceHead
-- Description: Loads FMS Invoice Head into into [dv].[LSAT_InvoiceHead]
-- Example:     Exec [dv].[Load_LSAT_InvoiceHead] 123 
-- History:
--  18/03/2024  B. Woods        Routine Written
--
-- ==========================================================================================

CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_LSAT_InvoiceHead`(IN p_ProcessID INT64, IN p_RecordSource STRING)
BEGIN
  /*
  ** Routine: Load_LSAT_InvoiceHead
  ** Description: Loads FMS Invoice Head into into dv.LSAT_InvoiceHead
  ** Description: Loads FMS Invoice Head into into dv_LSAT_InvoiceHead
  */

  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();

  DECLARE v_Component STRING DEFAULT 'dv_Load_LSAT_InvoiceHead';
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING;
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_Inserted INT64 DEFAULT 0;
  DECLARE v_Updated INT64 DEFAULT 0;
  BEGIN
    -- Only INSERT is present in the source logic, so using INSERT ... SELECT per CORE RULES.
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_InvoiceHead` (
      Invoice_HSK,
      FranchiseeCode_HSK,
      FranchiseeCode,
      InvoiceNumber,
      EnteredDate,
      EnterTime,
      CourierNumber,
      CustomerId,
      CourierIdCommisionPaidTo,
      InvoiceTotalAmount,
      TaxAmount,
      AmountPaid,
      Balance,
      PaidOnEntry,
      InsuranceAmount,
      DissectionLines,
      CourierFloatIssuesGoTo,
      FullyPaid,
      Committed,
      CountryCode,
      InvoiceCopyDate,
      BatchId,
      SystemDate,
      CreditedAmount,
      CreditedTax,
      PurchaseOrderNumber,
      Comments,
      ExcludedFromBaseRate,
      Loaded,
      ProcessId,
      RecordSource
    )
    WITH InvoiceHeadStg AS (
      SELECT
        `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(CONCAT(CAST(InvoiceNumber AS STRING), '^', RFCode), '^') AS Invoice_HSK,
        `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(RFCode, '^') AS FranchiseeCode_HSK,
        RFCode AS FranchiseeCode,
        InvoiceNumber,
        EnteredDate,
        EnterTime,
        CourierIdCommisionPaidTo AS CourierNumber,
        CustomerId,
        CourierIdCommisionPaidTo,
        InvoiceTotalAmount,
        TaxAmount,
        AmountPaid,
        Balance,
        PaidOnEntry,
        InsuranceAmount,
        DissectionLines,
        CourierFloatIssuesGoTo,
        FullyPaid,
        Committed,
        NMId AS CountryCode,
        InvoiceCopyDate,
        BatchId,
        SystemDate,
        CreditedAmount,
        CreditedTax,
        PurchaseOrderNumber,
        Comments,
        ExcludedFromBaseRate
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_FMS_InvoiceHead_Stg`
    )
    SELECT
      Src.Invoice_HSK,
      Src.FranchiseeCode_HSK,
      Src.FranchiseeCode,
      Src.InvoiceNumber,
      Src.EnteredDate,
      Src.EnterTime,
      Src.CourierNumber,
      Src.CustomerId,
      Src.CourierIdCommisionPaidTo,
      Src.InvoiceTotalAmount,
      Src.TaxAmount,
      Src.AmountPaid,
      Src.Balance,
      Src.PaidOnEntry,
      Src.InsuranceAmount,
      Src.DissectionLines,
      Src.CourierFloatIssuesGoTo,
      Src.FullyPaid,
      Src.Committed,
      Src.CountryCode,
      Src.InvoiceCopyDate,
      Src.BatchId,
      Src.SystemDate,
      Src.CreditedAmount,
      Src.CreditedTax,
      Src.PurchaseOrderNumber,
      Src.Comments,
      Src.ExcludedFromBaseRate,
      v_Loaded AS Loaded,
      p_ProcessId AS ProcessId,
      p_RecordSource
    FROM InvoiceHeadStg AS Src
    WHERE NOT EXISTS (
      SELECT 1 
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_InvoiceHead` AS Tgt 
      WHERE Tgt.FranchiseeCode = Src.FranchiseeCode 
        AND Tgt.InvoiceNumber = Src.InvoiceNumber
    );

    SET v_Inserted = @@row_count;
    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result = 'Failed';
    SET v_ErrorMessage = @@error.message;
  END;

  -- Record load metrics in log
  SET v_Ended = CURRENT_DATETIME();
  CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
    v_Component, 
    p_ProcessID, 
    v_Started, 
    v_Ended, 
    v_Result, 
    v_ErrorMessage, 
    v_Inserted, 
    v_Updated, 
    -1
  );

END;