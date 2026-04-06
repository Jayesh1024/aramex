-- ==========================================================================================
-- Routine:		Load_HUB_Invoice
-- Description: Loads attributes into HUB_Invoice
-- Example:		Exec [dv].[Load_HUB_Invoice] 123, 'FMS_Invoice'  
-- History:
--	25/10/2019  P. Waldron		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `your_project.dv.Load_HUB_Invoice`(
  p_ProcessID INT64,
  p_RecordSource STRING
)
BEGIN
  DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
  DECLARE v_Inserted_Count INT64 DEFAULT 0;
  DECLARE v_Status STRING DEFAULT 'Success';
  DECLARE v_Error_Msg STRING DEFAULT NULL;

  BEGIN
    -- MERGE handles the multi-part Business Key check efficiently in BigQuery
    MERGE `your_project.dv.HUB_Invoice` AS Target
    USING (
      SELECT DISTINCT
        -- Composite Hashing: InvoiceNumber ^ FranchiseeCode ^ CourierNumber ^ Country
        UPPER(TO_HEX(SHA256(CONCAT(
          CAST(InvoiceNumber AS STRING), '^', 
          IFNULL(FranchiseeCode, ''), '^', 
          IFNULL(CourierNumber, ''), '^', 
          IFNULL(Country, '')
        )))) AS Invoice_HSK,
        InvoiceNumber,
        FranchiseeCode,
        CourierNumber,
        Country,
        v_Started AS Loaded,
        p_ProcessID AS ProcessID,
        p_RecordSource AS RecordSource
      FROM (
        SELECT 
          inv.InvoiceNumber, 
          inv.RFCode AS FranchiseeCode, 
          inv.CourierInvoiceBelongsTo AS CourierNumber, 
          cty.CountryName AS Country
        FROM `your_project.Staging.FMS_InvoiceHead_Stg` AS inv
        -- Note: CustomerKey link exists in source but isn't used in Hub target columns
        LEFT JOIN `your_project.Staging.Dim_Country` AS cty
          ON cty.CountryCode = inv.NMId
      ) AS Src
      WHERE InvoiceNumber IS NOT NULL
    ) AS Source
    ON Target.Invoice_HSK = Source.Invoice_HSK
    WHEN NOT MATCHED THEN
      INSERT (Invoice_HSK, InvoiceNumber, FranchiseeCode, CourierNumber, Country, Loaded, ProcessID, RecordSource)
      VALUES (Source.Invoice_HSK, Source.InvoiceNumber, Source.FranchiseeCode, Source.CourierNumber, Source.Country, Source.Loaded, Source.ProcessID, Source.RecordSource);

    SET v_Inserted_Count = @@row_count;

  EXCEPTION WHEN ERROR THEN
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- Metadata Logging
  CALL `your_project.Staging.SaveLog`(
    'dv.Load_HUB_Invoice',
    p_ProcessID,
    v_Started,
    CURRENT_TIMESTAMP(),
    v_Status,
    v_Error_Msg,
    v_Inserted_Count
  );

  IF v_Status = 'Failed' THEN
    ERROR(v_Error_Msg);
  END IF;

END;
