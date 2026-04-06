-- ==========================================================================================
-- Routine:     Load_LNK_Label_Product_ServiceItem
-- Description: Loads Label_Product_ServiceItem_Stg from Staging.fl_ConItemSrv_Stg 
-- Example:     Exec [dv].[Load_Label_Product_ServiceItem_Stg] 659,  'MyFastway' 
-- History:
--  17/08/2020  P. Waldron      Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `dv.Load_Product_ServiceCon_Stg`(IN p_ProcessID INT64, IN p_RecordSource STRING)
BEGIN
  /*
  ** Routine: Load_Product_ServiceCon_Stg
  ** Description: Loads Label_Product_ServiceItem_Stg from Staging.fl_ConItemSrv_Stg
  */

  DECLARE v_DefaultValidFrom DATETIME DEFAULT '1900-01-01 00:00:00';
  DECLARE v_DefaultValidTo DATETIME DEFAULT '9999-12-31 23:59:59';
  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();

  DECLARE v_Component STRING DEFAULT 'dv.Load_Product_ServiceCon_Stg';
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING;
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_Inserted INT64 DEFAULT 0;
  DECLARE v_Updated INT64 DEFAULT 0;

  BEGIN
    -- Only INSERT is present in the source logic, so using INSERT ... SELECT per CORE RULES.
    INSERT INTO `Staging.Product_ServiceCon_Stg` (
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
      ProcessID,
      RecordSource,
      RecordSourceId
    )
    SELECT
      TO_HEX(SHA256(CONCAT(Src.Country, '^', CAST(Src.ConId AS STRING), '^', Src.ProductCode, '^', CAST(Src.ServiceItemId AS STRING)))) AS Product_ServiceCon_HSK,
      TO_HEX(SHA256(CONCAT(Src.Country, '^', Src.ProductCode))) AS Product_HSK,
      Src.ConId,
      Src.Country,
      Src.ProductCode,
      Src.CountryCode,
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
      p_ProcessID AS ProcessID,
      p_RecordSource AS RecordSource,
      Src.ConId AS RecordSourceId
    FROM (
      SELECT DISTINCT 
        Srv.ConId,
        IFNULL(cty.CountryName, 'Unknown') AS Country,
        Prod.Code AS ProductCode,
        Srv.CountryId AS CountryCode,
        Srv.ProductId,
        Srv.ServiceItemId,
        Srv.CreatedOn,
        Srv.FMSInvoiceNo,
        Srv.FMSInvoiceDate,
        Srv.Price,
        Srv.Tax,
        Srv.Total,
        Srv.PickupPrice,
        Srv.DeliveryPrice,
        Srv.PLBSBatchId,
        Srv.PLBSInvoiceNo,
        Srv.PLBSInvoiceDate,
        Srv.PLBSPrice,
        Srv.PLBSTax,
        Srv.PLBSTotal,
        Srv.DLBSBatchId,
        Srv.DLBSInvoiceNo,
        Srv.DLBSInvoiceDate,
        Srv.DLBSPrice,
        Srv.DLBSTax,
        Srv.DLBSTotal,
        Srv.ServicePrice,
        Srv.ServicePriceDiscountPercent,
        Srv.ServicePriceDiscountFixed,
        Srv.ServicePriceCommPercent,
        Srv.ServicePriceComm,
        Srv.UpdatedOn
      FROM `Staging.fl_ConSrv_Stg` AS Srv  
      LEFT JOIN `dbo.Dim_Country` AS cty ON cty.CountryCode = Srv.CountryId
      LEFT JOIN `Staging.Product_Stg` AS Prod ON Srv.CountryId = Prod.CountryCode AND Srv.ProductId = Prod.ProductId
    ) AS Src;

    SET v_Inserted = @@row_count;
    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result = 'Failed';
    SET v_ErrorMessage = @@error.message;
  END;

  -- Record load metrics in log
  SET v_Ended = CURRENT_DATETIME();
  CALL `Staging.SaveLog`(
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