-- ==========================================================================================
-- Routine:     Load_LNK_Label_Product_ServiceItem
-- Description: Loads Label_Product_ServiceItem_Stg from Staging_fl_ConItemSrv_Stg 
-- Example:     Exec [dv].[Load_Label_Product_ServiceItem_Stg] 659,  'MyFastway' 
-- History:
--  17/08/2020  P. Waldron      Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_Label_Product_ServiceItem_Stg`(IN p_ProcessID INT64, IN p_RecordSource STRING)
BEGIN
  /*
  ** Routine: Load_LNK_Label_Product_ServiceItem
  ** Description: Loads Label_Product_ServiceItem_Stg from Staging_fl_ConItemSrv_Stg 
  */

  DECLARE v_DefaultValidFrom DATETIME DEFAULT '1900-01-01 00:00:00';
  DECLARE v_DefaultValidTo DATETIME DEFAULT '9999-12-31 23:59:59';
  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();

  DECLARE v_Component STRING DEFAULT 'dv_Load_Label_Product_ServiceItem_Stg';
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING;
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_Inserted INT64 DEFAULT 0;
  DECLARE v_Updated INT64 DEFAULT 0;
  BEGIN
    -- Only INSERT is present in the source logic, so using INSERT ... SELECT per CORE RULES.
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Label_Product_ServiceItem_Stg`
    (
      Label_Product_ServiceItem_HSK,
      LabelNo_HSK,
      Product_HSK,
      ServiceItem_HSK,
      LabelNo,
      ConId,
      ConItemId,
      LineNo,
      CountryCode,
      Country,
      ProductId,
      ProductCode,
      ServiceItemId,
      ServiceItem,
      CreatedOn,
      FMSInvoiceNo,
      FMSInvoiceDate,
      Price,
      Tax,
      Total,
      PickUpPrice,
      DeliveryPrice,
      DLBSBatchId,
      DLBSInvoiceNo,
      DLBSInvoiceDate,
      DLBSPrice,
      DLBSTax,
      DLBSTotal,
      PLBSBatchId,
      PLBSInvoiceNo,
      PLBSInvoiceDate,
      PLBSPrice,
      PLBSTax,
      PLBSTotal,
      BareProfileId,
      ServicePrice,
      ServicePriceComm,
      ServicePriceCommPercent,
      ServicePriceDiscountFixed,
      ServicePriceDiscountPercent,
      UpdatedOn,
      Loaded,
      ProcessId,
      RecordSource,
      RecordSourceId
    )
    SELECT
      (`prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(CONCAT(Src.Country, '^', Src.LabelNo, '^', Src.ProductCode, '^', Src.ServiceItem), '^')) AS Label_Product_ServiceItem_HSK,
      (`prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(CONCAT(Src.Country, '^', Src.LabelNo), '^')) AS LabelNo_HSK,
      (`prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(CONCAT(Src.Country, '^', Src.ProductCode), '^')) AS Product_HSK,
      (`prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(CONCAT(Src.Country, '^', Src.ServiceItem), '^')) AS ServiceItem_HSK,
      LabelNo,
      ConId,
      ConItemId,
      LineNo,
      CountryCode,
      Country,
      ProductId,
      ProductCode,
      ServiceItemId,
      ServiceItem,
      CreatedOn,
      FMSInvoiceNo,
      FMSInvoiceDate,
      Price,
      Tax,
      Total,
      PickUpPrice,
      DeliveryPrice,
      DLBSBatchId,
      DLBSInvoiceNo,
      DLBSInvoiceDate,
      DLBSPrice,
      DLBSTax,
      DLBSTotal,
      PLBSBatchId,
      PLBSInvoiceNo,
      PLBSInvoiceDate,
      PLBSPrice,
      PLBSTax,
      PLBSTotal,
      BareProfileId,
      ServicePrice,
      ServicePriceComm,
      ServicePriceCommPercent,
      ServicePriceDiscountFixed,
      ServicePriceDiscountPercent,
      UpdatedOn,
      v_Loaded AS Loaded,
      p_ProcessID AS ProcessId,
      p_RecordSource AS RecordSource,
      ServiceItemId AS RecordSourceId
    FROM (
      SELECT DISTINCT 
        Srv.Label AS LabelNo,
        ConId,
        ConItemId,
        LineNo,
        Srv.CountryId AS CountryCode,
        IFNULL(cty.CountryName, 'Unknown') AS Country,
        Srv.ProductId,
        Prod.Code AS ProductCode,
        Srv.ServiceItemId,
        IFNULL(IF(si.DisplayText <> '', si.DisplayText, si.Description), REPLACE('(:1:)', ':1:', CAST(Srv.ServiceItemId AS STRING))) AS ServiceItem,
        CreatedOn,
        FMSInvoiceNo,
        FMSInvoiceDate,
        Srv.Price,
        Tax,
        Total,
        PickUpPrice,
        DeliveryPrice,
        DLBSBatchId,
        DLBSInvoiceNo,
        DLBSInvoiceDate,
        DLBSPrice,
        DLBSTax,
        DLBSTotal,
        PLBSBatchId,
        PLBSInvoiceNo,
        PLBSInvoiceDate,
        PLBSPrice,
        PLBSTax,
        PLBSTotal,
        BareProfileId,
        ServicePrice,
        ServicePriceComm,
        ServicePriceCommPercent,
        ServicePriceDiscountFixed,
        ServicePriceDiscountPercent,
        UpdatedOn
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_fl_ConItemSrv_Stg` AS Srv  
      LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Country` AS cty ON cty.CountryCode = Srv.CountryId
      LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Product_Stg` AS Prod ON Srv.CountryId = Prod.CountryCode AND Srv.ProductId = Prod.ProductId
      INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_fl_ServiceItem_Stg` AS SI ON Srv.CountryId = SI.CountryId AND Srv.ProductId = SI.ProductId AND Srv.ServiceItemId = SI.ServiceItemId 
    ) AS Src;

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