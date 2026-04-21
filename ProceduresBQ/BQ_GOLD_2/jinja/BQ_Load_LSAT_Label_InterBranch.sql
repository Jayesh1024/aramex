-- ==========================================================================================
-- Routine:     Load_LSAT_Label_InterBranch
-- Description: Loads LSAT_Label_InterBranch from Staging_Label_Interbranch_Stg for a country
-- Example:     Exec [dv].[Load_LSAT_Label_InterBranch] 659,  'InterBranchAU' 
-- History:
--  17/09/2020  P. Waldron      Routine Written
--  21/06/2022  B. Woods         Cloned
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_LSAT_Label_InterBranch`(IN p_ProcessID INT64, IN p_RecordSource STRING)
BEGIN
  /*
  ** Routine: Load_LSAT_Label_InterBranch
  ** Description: Loads LSAT_Label_InterBranch from Staging_Label_Interbranch_Stg for a country
  ** Description: Loads LSAT_Label_InterBranch from Staging_Label_Interbranch_Stg for a country
  */

  DECLARE v_DefaultValidFrom DATETIME DEFAULT '1900-01-01 00:00:00';
  DECLARE v_DefaultValidTo DATETIME DEFAULT '9999-12-31 23:59:59';
  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();

  DECLARE v_Component STRING DEFAULT 'dv_Load_LSAT_Label_InterBranch';
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING;
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_Inserted INT64 DEFAULT 0;
  DECLARE v_Updated INT64 DEFAULT 0;
  BEGIN
    -- Only INSERT is present in the source logic, so using INSERT ... SELECT per CORE RULES.
    INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_LSAT_Label_Interbranch` (
      Label_InterBranch_HSK,
      LabelNo,
      CountryCode,
      InvoiceNumber,
      InvoiceDate,
      InvoiceFromRF,
      InvoiceToRF,
      ProductID,
      Category,
      DeliveryDate,
      DeliveryTime,
      Price,
      Loaded,
      ProcessId,
      RecordSource,
      RecordSourceId
    )
    SELECT
      Src.Label_InterBranch_HSK,
      Src.LabelNo,
      Src.CountryCode,
      Src.InvoiceNumber,
      Src.InvoiceDate,
      Src.InvoiceFromRF,
      Src.InvoiceToRF,
      Src.ProductID,
      Src.Category,
      Src.DeliveryDate,
      Src.DeliveryTime,
      Src.Price,
      v_Loaded AS Loaded,
      p_ProcessID AS ProcessId,
      p_RecordSource AS RecordSource,
      Src.BatchId
    FROM (
      SELECT
        (SHA256(CONCAT(
          IFNULL(Country, ''), '^',
          IFNULL(LabelNo, ''), '^',
          IFNULL(CAST(BatchId AS STRING), ''), '^',
          IFNULL(InvoiceFromRF, ''), '^',
          IFNULL(InvoiceToRF, '')
        ))) AS Label_InterBranch_HSK,
        LabelNo,
        CountryCode,
        InvoiceNumber,
        InvoiceDate,
        InvoiceFromRF,
        InvoiceToRF,
        ProductID,
        Category,
        DeliveryDate,
        DeliveryTime,
        Price,
        BatchId
      FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Label_Interbranch_Stg`
    ) AS Src
    WHERE NOT EXISTS (
      SELECT 1 
      FROM `{{ project_id }}.{{ target_dataset_id }}.dv_LSAT_Label_Interbranch` AS Tgt
      WHERE Tgt.Label_InterBranch_HSK = Src.Label_InterBranch_HSK
    );

    SET v_Inserted = @@row_count;
    SET v_Result = 'Success';

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