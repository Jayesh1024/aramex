CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_Label_Invoices_Hist`(IN p_ProcessID INT64)
BEGIN
  /*
  ** Routine: Load_Label_Invoices
  ** Description: Attempts to find and Load any missing Invoice-Label relationships in dbo_Dim_label
  */

  DECLARE v_Component STRING DEFAULT 'dv_Load_Label_Invoices_Hist';
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING;
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_Inserted INT64 DEFAULT 0;
  DECLARE v_Updated INT64 DEFAULT 0;
  DECLARE v_TotalUpdated INT64 DEFAULT 0;

  BEGIN
      TRUNCATE TABLE `{{ project_id }}.{{ target_dataset_id }}.Staging_FastwayLabels_Stg`;

      -- Identify labels with missing invoice info and find the "BookInvoiceNumber" using window functions
      INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_FastwayLabels_Stg` (LabelNo, FranchiseeCode, InvoiceNumber, CountryCode)
      WITH TargetLabels AS (
        SELECT 
          LabelNo, 
          CountryCode
        FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Label`
        WHERE (FMSInvoiceID IS NULL OR FMSInvoiceID = 0 OR FMSRfID IS NULL)
          AND CountryCode IN (1, 6, 24)
          AND LENGTH(LabelNo) = 12
      ),
      SourceInvoices AS (
        SELECT 
          LabelNo, 
          InvoiceNumber, 
          FranchiseeCode
        FROM `{{ project_id }}.{{ target_dataset_id }}.dv_LNK_Invoice_Label`
      ),
      Combined AS (
        -- Combine target labels with potential source invoices to use positional window functions
        SELECT LabelNo, CAST(NULL AS INT64) AS InvoiceNumber, CAST(NULL AS STRING) AS FranchiseeCode, 'TGT' AS Typ 
        FROM TargetLabels
        UNION ALL
        SELECT LabelNo, InvoiceNumber, FranchiseeCode, 'SRC' AS Typ 
        FROM SourceInvoices
      ),
      Propagated AS (
        -- Use LAST_VALUE to fill the BookInvoiceNumber and FranchiseeCode based on the sorted LabelNo sequence
        SELECT 
          LabelNo,
          Typ,
          LAST_VALUE(InvoiceNumber IGNORE NULLS) OVER (ORDER BY LabelNo ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS PropInvoice,
          LAST_VALUE(FranchiseeCode IGNORE NULLS) OVER (ORDER BY LabelNo ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS PropFranchisee
        FROM Combined
      )
      SELECT 
        LabelNo, 
        PropFranchisee, 
        PropInvoice, 
        NULL -- CountryCode placeholder
      FROM Propagated
      WHERE Typ = 'TGT';

      -- Update the Dimension table based on discovered mappings for the current date iteration
      UPDATE `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Label` AS dim
      SET 
        FMSInvoiceID = src.InvoiceNumber, 
        FMSRfID = src.FranchiseeCode
      FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_FastwayLabels_Stg` AS src
      WHERE src.LabelNo = dim.LabelNo
        AND (
          dim.FMSInvoiceID IS NULL 
          OR dim.FMSInvoiceID = 0 
          OR (dim.FMSRfID IS NULL AND src.InvoiceNumber = dim.FMSInvoiceID)
        );

      SET v_Updated = @@row_count;
      SET v_TotalUpdated = v_TotalUpdated + v_Updated;

    SET v_Result = 'Success';
    -- Using v_Updated to store final total for logging
    SET v_Updated = v_TotalUpdated;

  EXCEPTION WHEN ERROR THEN
    SET v_Result = 'Failed';
    SET v_ErrorMessage = @@error.message;
  END;

  -- Record load metrics in log
  SET v_Ended = CURRENT_DATETIME();
  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
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