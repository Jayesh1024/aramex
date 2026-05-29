-- ==========================================================================================
-- Routine:     Load_LSAT_Label_Product_ServiceItem
-- Description: Loads attributes into LSAT_Label_Product_ServiceItem from Staging_fl_ConItemSrv_Stg 
-- Example:     Exec [dv].[Load_LSAT_Label_Product_ServiceItem] 659
-- History:
--  17/09/2020  P. Waldron      Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_LSAT_Label_Product_ServiceItem`(IN p_ProcessID INT64, IN p_RecordSource STRING)
BEGIN
  /*
  ** Routine: Load_LSAT_Label_Product_ServiceItem
  ** Description: Loads attributes into LSAT_Label_Product_ServiceItem from Staging_fl_ConItemSrv_Stg 
  */

  DECLARE v_DefaultValidFrom DATETIME DEFAULT '1900-01-01 00:00:00';
  DECLARE v_DefaultValidTo DATETIME DEFAULT '9999-12-31 23:59:59';
  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();

  DECLARE v_Component STRING DEFAULT 'dv_Load_LSAT_Label_Product_ServiceItem';
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING;
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_Inserted INT64 DEFAULT 0;
  DECLARE v_Updated INT64 DEFAULT 0;
  BEGIN
    -- Using a single MERGE to handle SCD Type 2 logic (Expire + Insert)
    -- As per CORE RULES: v_Updated = Inserted + Updated; v_Inserted = 0.
    MERGE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Product_ServiceItem` AS Tgt
    USING (
      WITH StagingData AS (
        SELECT 
          *,
          -- Hash key calculation consistent with original logic
          `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(CONCAT(IFNULL(Country, ''), '^', IFNULL(LabelNo, ''), '^', IFNULL(ProductCode, ''), '^', IFNULL(ServiceItem, '')), '^') AS Calc_HSK
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Label_Product_ServiceItem_Stg`
      ),
      -- Identify changes compared to current records
      DetectedChanges AS (
        SELECT 
          S.*,
          T.Label_Product_ServiceItem_HSK AS Tgt_HSK,
          (T.Label_Product_ServiceItem_HSK IS NOT NULL AND (
            T.LabelNo != S.LabelNo OR T.ConId != S.ConId OR T.ConItemId != S.ConItemId OR
            T.LineNo != S.LineNo OR T.CountryCode != S.CountryCode OR T.Country != S.Country OR
            T.ProductId != S.ProductId OR T.ProductCode != S.ProductCode OR T.ServiceItemId != S.ServiceItemId OR
            T.ServiceItem != S.ServiceItem OR T.CreatedOn != S.CreatedOn OR T.FMSInvoiceNo != S.FMSInvoiceNo OR
            T.FMSInvoiceDate != S.FMSInvoiceDate OR T.Price != S.Price OR T.Tax != S.Tax OR
            T.Total != S.Total OR T.PickUpPrice != S.PickUpPrice OR T.DeliveryPrice != S.DeliveryPrice OR
            T.DLBSBatchId != S.DLBSBatchId OR T.DLBSInvoiceNo != S.DLBSInvoiceNo OR T.DLBSInvoiceDate != S.DLBSInvoiceDate OR
            T.DLBSPrice != S.DLBSPrice OR T.DLBSTax != S.DLBSTax OR T.DLBSTotal != S.DLBSTotal OR
            T.PLBSBatchId != S.PLBSBatchId OR T.PLBSInvoiceNo != S.PLBSInvoiceNo OR T.PLBSInvoiceDate != S.PLBSInvoiceDate OR
            T.PLBSPrice != S.PLBSPrice OR T.PLBSTax != S.PLBSTax OR T.PLBSTotal != S.PLBSTotal OR
            T.BareProfileId != S.BareProfileId OR T.ServicePrice != S.ServicePrice OR T.ServicePriceComm != S.ServicePriceComm OR
            T.ServicePriceCommPercent != S.ServicePriceCommPercent OR T.ServicePriceDiscountFixed != S.ServicePriceDiscountFixed OR
            T.ServicePriceDiscountPercent != S.ServicePriceDiscountPercent OR T.UpdatedOn != S.UpdatedOn
          )) AS HasChanged
        FROM StagingData S
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Product_ServiceItem` T ON S.Calc_HSK = CAST(T.Label_Product_ServiceItem_HSK AS BYTES) AND T.IsCurrent = 1
      )
      -- Rows to expire existing current record
      SELECT *, 'EXPIRE' AS MergeAction FROM DetectedChanges WHERE HasChanged = TRUE
      UNION ALL
      -- Rows to insert as new current record (brand new or changed)
      SELECT *, 'INSERT' AS MergeAction FROM DetectedChanges WHERE Tgt_HSK IS NULL OR HasChanged = TRUE
    ) AS Src
    -- Join condition ensures 'INSERT' actions never match, forcing NOT MATCHED branch
    ON CAST(Tgt.Label_Product_ServiceItem_HSK AS BYTES) = Src.Calc_HSK
       AND Tgt.IsCurrent = 1
       AND Src.MergeAction = 'EXPIRE'
    
    WHEN MATCHED THEN
      UPDATE SET
        IsCurrent = 0,
        ValidTo = v_Loaded
        
    WHEN NOT MATCHED BY TARGET AND Src.MergeAction = 'INSERT' THEN
      INSERT (
        Label_Product_ServiceItem_HSK, LabelNo, ConId, ConItemId, LineNo,
        CountryCode, Country, ProductId, ProductCode, ServiceItemId,
        ServiceItem, CreatedOn, FMSInvoiceNo, FMSInvoiceDate, Price,
        Tax, Total, PickUpPrice, DeliveryPrice, DLBSBatchId,
        DLBSInvoiceNo, DLBSInvoiceDate, DLBSPrice, DLBSTax, DLBSTotal,
        PLBSBatchId, PLBSInvoiceNo, PLBSInvoiceDate, PLBSPrice, PLBSTax,
        PLBSTotal, BareProfileId, ServicePrice, ServicePriceComm, ServicePriceCommPercent,
        ServicePriceDiscountFixed, ServicePriceDiscountPercent, UpdatedOn, 
        Loaded, ProcessId, RecordSource, RecordSourceId, ValidFrom, ValidTo, IsCurrent
      )
      VALUES (
        Src.Calc_HSK, Src.LabelNo, Src.ConId, Src.ConItemId, Src.LineNo,
        Src.CountryCode, Src.Country, Src.ProductId, Src.ProductCode, Src.ServiceItemId,
        Src.ServiceItem, Src.CreatedOn, Src.FMSInvoiceNo, Src.FMSInvoiceDate, Src.Price,
        Src.Tax, Src.Total, Src.PickUpPrice, Src.DeliveryPrice, Src.DLBSBatchId,
        Src.DLBSInvoiceNo, Src.DLBSInvoiceDate, Src.DLBSPrice, Src.DLBSTax, Src.DLBSTotal,
        Src.PLBSBatchId, Src.PLBSInvoiceNo, Src.PLBSInvoiceDate, Src.PLBSPrice, Src.PLBSTax,
        Src.PLBSTotal, Src.BareProfileId, Src.ServicePrice, Src.ServicePriceComm, Src.ServicePriceCommPercent,
        Src.ServicePriceDiscountFixed, Src.ServicePriceDiscountPercent, Src.UpdatedOn,
        v_Loaded, p_ProcessID, p_RecordSource, Src.ConId, 
        IF(Src.Tgt_HSK IS NULL, v_DefaultValidFrom, v_Loaded), v_DefaultValidTo, 1
      );

    SET v_Updated = @@row_count;
    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result = 'Failed';
    SET v_ErrorMessage = @@error.message;
  END;

  SET v_Ended = CURRENT_DATETIME();
  -- SaveLog signature: component, processId, started, ended, result, errorMessage, inserted, updated, -1
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