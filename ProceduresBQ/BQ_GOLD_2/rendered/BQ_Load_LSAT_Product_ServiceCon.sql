-- ==========================================================================================
-- Routine:     Load_LSAT_Label_Product_ServiceItem
-- Description: Loads attributes into LSAT_Label_Product_ServiceItem from Staging_fl_ConItemSrv_Stg 
-- Example:     Exec [dv].[Load_LSAT_Label_Product_ServiceItem] 659
-- History:
--  17/09/2020  P. Waldron      Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.dv_Load_LSAT_Product_ServiceCon`(IN p_ProcessID INT64)
BEGIN
  /*
  ** Routine: Load_LSAT_Label_Product_ServiceItem
  ** Description: Loads attributes into LSAT_Label_Product_ServiceItem from Staging_fl_ConItemSrv_Stg
  */

  DECLARE v_DefaultValidFrom DATETIME DEFAULT '1900-01-01 00:00:00';
  DECLARE v_DefaultValidTo DATETIME DEFAULT '9999-12-31 23:59:59';
  DECLARE v_Loaded DATETIME DEFAULT CAST(CURRENT_TIMESTAMP() AS DATETIME);

  DECLARE v_Component STRING DEFAULT 'dv_Load_LSAT_Product_ServiceCon';
  DECLARE v_Started DATETIME DEFAULT CAST(CURRENT_TIMESTAMP() AS DATETIME);
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING;
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_Inserted INT64 DEFAULT 0;
  DECLARE v_Updated INT64 DEFAULT 0;
  DECLARE v_RecordSource STRING DEFAULT 'MyConSrv';

  BEGIN
    -- Only INSERT is present in the active logic, so using INSERT ... SELECT per CORE RULES.
    INSERT INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dv_LSAT_Product_ServiceCon` (
      Product_ServiceCon_HSK,
      Product_HSK,
      ConId,
      Country,
      ProductCode,
      CountryId,
      ProductId,
      ServiceItemId,
      CreatedOn,
      FMSInvoiceNo,
      FMSInvoiceDate,
      Price,
      Tax,
      Total,
      PickupPrice,
      DeliveryPrice,
      PLBSBatchId,
      PLBSInvoiceNo,
      PLBSInvoiceDate,
      PLBSPrice,
      PLBSTax,
      PLBSTotal,
      DLBSBatchId,
      DLBSInvoiceNo,
      DLBSInvoiceDate,
      DLBSPrice,
      DLBSTax,
      DLBSTotal,
      ServicePrice,
      ServicePriceDiscountPercent,
      ServicePriceDiscountFixed,
      ServicePriceCommPercent,
      ServicePriceComm,
      UpdatedOn,
      Loaded,
      ProcessId,
      RecordSource,
      RecordSourceId,
      ValidFrom,
      ValidTo,
      IsCurrent
    )
    SELECT
      Src.Product_ServiceCon_HSK,
      Src.Product_HSK,
      Src.ConId,
      Src.Country,
      Src.ProductCode,
      Src.CountryId,
      Src.ProductId,
      Src.ServiceItemId,
      Src.CreatedOn,
      Src.FMSInvoiceNo,
      Src.FMSInvoiceDate,
      Src.Price,
      Src.Tax,
      Src.Total,
      Src.PickupPrice,
      Src.DeliveryPrice,
      Src.PLBSBatchId,
      Src.PLBSInvoiceNo,
      Src.PLBSInvoiceDate,
      Src.PLBSPrice,
      Src.PLBSTax,
      Src.PLBSTotal,
      Src.DLBSBatchId,
      Src.DLBSInvoiceNo,
      Src.DLBSInvoiceDate,
      Src.DLBSPrice,
      Src.DLBSTax,
      Src.DLBSTotal,
      Src.ServicePrice,
      Src.ServicePriceDiscountPercent,
      Src.ServicePriceDiscountFixed,
      Src.ServicePriceCommPercent,
      Src.ServicePriceComm,
      Src.UpdatedOn,
      v_Loaded AS Loaded,
      p_ProcessID AS ProcessId,
      v_RecordSource AS RecordSource,
      Src.ConId AS RecordSourceId,
      v_Loaded AS ValidFrom,
      v_DefaultValidTo AS ValidTo,
      1 AS IsCurrent
    FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_Product_ServiceCon_Stg` AS Src
    LEFT JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dv_LSAT_Product_ServiceCon` AS Tgt ON Tgt.Product_ServiceCon_HSK = Src.Product_ServiceCon_HSK
    WHERE Tgt.Product_ServiceCon_HSK IS NULL;

    SET v_Inserted = @@row_count;
    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result = 'Failed';
    SET v_ErrorMessage = @@error.message;
  END;

  -- Record load metrics in log
  SET v_Ended = CAST(CURRENT_TIMESTAMP() AS DATETIME);
  CALL `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.Staging_SaveLog`(
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