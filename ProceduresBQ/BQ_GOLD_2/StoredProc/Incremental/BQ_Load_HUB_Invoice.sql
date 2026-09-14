-- ==========================================================================================
-- Routine:     Load_HUB_Invoice
-- Description: Loads business keys into HUB_Invoice
-- Example:     CALL `...dv_Load_HUB_Invoice`(123, 'FMS_Invoice');
-- History:
--  25/10/2019  P. Waldron    Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_HUB_Invoice`(
  p_ProcessID INT64,
  p_RecordSource STRING
)
BEGIN
  DECLARE v_Component STRING DEFAULT 'dv_Load_HUB_Invoice';
  DECLARE v_Started   DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Loaded    DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Status    STRING   DEFAULT 'Success';
  DECLARE v_Error_Msg STRING   DEFAULT NULL;
  DECLARE v_Inserted_Count INT64 DEFAULT 0;

  BEGIN
    -- BigQuery MERGE for idempotent business-key insertion (replaces WHERE NOT EXISTS)
    MERGE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_Invoice` AS Target
    USING (
      SELECT DISTINCT
        `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(
          CONCAT(
            CAST(inv.InvoiceNumber AS STRING), '^',
            inv.RFCode,                        '^',
            inv.CourierInvoiceBelongsTo,       '^',
            cty.CountryName
          ), '^'
        ) AS Invoice_HSK,
        inv.InvoiceNumber                 AS InvoiceNumber,
        inv.RFCode                        AS FranchiseeCode,
        inv.CourierInvoiceBelongsTo       AS CourierNumber,
        cty.CountryName                   AS Country,
        v_Loaded                          AS Loaded,
        p_ProcessID                       AS ProcessID,
        p_RecordSource                    AS RecordSource
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_FMS_InvoiceHead_Stg` AS inv
      LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CustomerLinks_Stg` AS lnk
        ON lnk.FMSCustomerID = inv.CustomerId
       AND lnk.CountryCode   = inv.NMId
      LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Country` AS cty
        ON cty.CountryCode = inv.NMId
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

  -- Metadata logging (9 arguments, matching Staging_SaveLog signature in repo)
  CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
    v_Component, p_ProcessID, v_Started, CURRENT_DATETIME(), v_Status, v_Error_Msg, v_Inserted_Count, 0, 0
  );

  IF v_Status = 'Failed' THEN
    RAISE USING MESSAGE = v_Error_Msg;
  END IF;

END;