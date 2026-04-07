-- ==========================================================================================
-- Routine:     Load LSAT_FL_InvoicePayment
-- Description: Loads FWFastwayDW fl_InvoicePayment into [dv].[LSAT_FL_InvoicePayment]
-- Example:     Exec [dv].[Load_FL_InvoicePayment]  123 
-- History:
--  21/07/2025  B. Woods        Routine Written
--
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_FL_InvoicePayment`(IN p_ProcessId INT64, IN p_RecordSource STRING)
BEGIN
  /*
  ** Routine: Load_FL_InvoicePayment
  ** Description: Loads FWFastwayDW fl_InvoicePayment into dv_LSAT_FL_InvoicePayment
  */

  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Component STRING DEFAULT 'dv_Load_FL_InvoicePayment';
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING;
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_Inserted INT64 DEFAULT 0;
  DECLARE v_Updated INT64 DEFAULT 0;

  BEGIN
    -- MERGE Rule: Use single MERGE for Insert + Update logic
    MERGE `{{ project_id }}.{{ target_dataset_id }}.dv_LSAT_FL_InvoicePayment` AS Tgt
    USING `{{ project_id }}.{{ target_dataset_id }}.Staging_fl_InvoicePayment_Stg` AS Src
    ON Tgt.InvoicePaymentId = Src.InvoicePaymentId
    WHEN MATCHED AND (
      Tgt.CountryId IS DISTINCT FROM Src.CountryId OR
      Tgt.CustomerId IS DISTINCT FROM Src.CustomerId OR
      Tgt.InvoiceHeaderId IS DISTINCT FROM Src.InvoiceHeaderId OR
      Tgt.JournalId IS DISTINCT FROM Src.JournalId OR
      Tgt.Amount IS DISTINCT FROM Src.Amount OR
      Tgt.UpdatedOn IS DISTINCT FROM Src.UpdatedOn OR
      Tgt.UpdatedBy IS DISTINCT FROM Src.UpdatedBy
    )
    THEN UPDATE SET
      CountryId = Src.CountryId,
      CustomerId = Src.CustomerId,
      InvoiceHeaderId = Src.InvoiceHeaderId,
      JournalId = Src.JournalId,
      Amount = Src.Amount,
      UpdatedOn = Src.UpdatedOn,
      UpdatedBy = Src.UpdatedBy,
      Loaded = v_Loaded,
      ProcessId = p_ProcessId,
      RecordSource = p_RecordSource
    WHEN NOT MATCHED THEN
      INSERT (
        InvoicePaymentId,
        CountryId,
        CustomerId,
        InvoiceHeaderId,
        JournalId,
        Amount,
        UpdatedOn,
        UpdatedBy,
        Loaded,
        ProcessId,
        RecordSource
      )
      VALUES (
        Src.InvoicePaymentId,
        Src.CountryId,
        Src.CustomerId,
        Src.InvoiceHeaderId,
        Src.JournalId,
        Src.Amount,
        Src.UpdatedOn,
        Src.UpdatedBy,
        v_Loaded,
        p_ProcessId,
        p_RecordSource
      );

    -- When MERGE is used: @@row_count returns total rows affected (inserts + updates combined). 
    -- Assign to v_Updated; leave v_Inserted = 0.
    SET v_Updated = @@row_count;
    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result = 'Failed';
    SET v_ErrorMessage = @@error.message;
  END;

  -- Logging Rule: Every translated SP MUST end with CALL Staging_SaveLog
  SET v_Ended = CURRENT_DATETIME();
  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
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