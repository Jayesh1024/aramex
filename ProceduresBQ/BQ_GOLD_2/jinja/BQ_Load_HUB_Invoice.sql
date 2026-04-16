-- ==========================================================================================
-- Routine:   Load_HUB_Invoice
-- Description: Loads business keys into HUB_Invoice
-- Example:   Exec [dv].[Load_HUB_Invoice] 123, 'FMS_Invoice'
-- History:
--  20/08/2019  P. Waldron    Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_HUB_Invoice`(
  p_ProcessID INT64,
  p_RecordSource STRING
)
BEGIN
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Status STRING DEFAULT 'Success';
  DECLARE v_Error_Msg STRING DEFAULT NULL;
  DECLARE v_Inserted_Count INT64 DEFAULT 0;

  BEGIN
    -- BigQuery MERGE for idempotent business key insertion
    MERGE `{{ project_id }}.{{ target_dataset_id }}.dv_HUB_Invoice` AS Target
    USING (
      SELECT DISTINCT
        -- Using 'Unknown' for Country as confirmed missing from staging
        SHA256(CONCAT('Unknown', '^', TRIM(CAST(InvoiceNumber AS STRING)))) AS Invoice_HSK,
        'Unknown' AS Country,
        InvoiceNumber,
        -- Mapping Required fields from Staging schema
        IFNULL(RFCode, 'Unknown') AS FranchiseeCode,
        IFNULL(CourierInvoiceBelongsTo, 'Unknown') AS CourierNumber,
        v_Loaded AS Loaded,
        p_ProcessID AS ProcessId,
        p_RecordSource AS RecordSource
      FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_FMS_InvoiceHead_Stg`
      WHERE InvoiceNumber IS NOT NULL
    ) AS Source
    ON Target.Invoice_HSK = Source.Invoice_HSK
    WHEN NOT MATCHED THEN
      -- Including all NOT NULL columns: FranchiseeCode and CourierNumber
      INSERT (Invoice_HSK, InvoiceNumber, FranchiseeCode, CourierNumber, Country, Loaded, ProcessId, RecordSource)
      VALUES (Source.Invoice_HSK, Source.InvoiceNumber, Source.FranchiseeCode, Source.CourierNumber, Source.Country, Source.Loaded, Source.ProcessId, Source.RecordSource);

    SET v_Inserted_Count = @@row_count;

  EXCEPTION WHEN ERROR THEN
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- Metadata Logging (9 Arguments)
  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
    'dv_Load_HUB_Invoice', p_ProcessID, v_Started, CURRENT_DATETIME(), v_Status, v_Error_Msg, v_Inserted_Count, 0, 0
  );

  IF v_Status = 'Failed' THEN
    RAISE USING MESSAGE = v_Error_Msg;
  END IF;

END;