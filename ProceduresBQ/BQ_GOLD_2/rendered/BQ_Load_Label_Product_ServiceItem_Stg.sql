-- ==========================================================================================
-- Routine:		Load_LNK_Label_Product_ServiceItem
-- Description: Loads Label_Product_ServiceItem_Stg from Staging_fl_ConItemSrv_Stg 
-- Example:		Exec [dv].[Load_Label_Product_ServiceItem_Stg] 659,  'MyFastway' 
-- History:
--	17/08/2020  P. Waldron		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_Load_Label_Product_ServiceItem_Stg`(
  IN p_ProcessId    INT64,
  IN p_RecordSource STRING
)
BEGIN

  DECLARE v_Component     STRING DEFAULT 'Staging_Load_Label_Product_ServiceItem_Stg';
  DECLARE v_Started       DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended         DATETIME;
  DECLARE v_Result        STRING;
  DECLARE v_ErrorMessage  STRING;
  DECLARE v_Inserted      INT64 DEFAULT 0;
  DECLARE v_Loaded        DATETIME DEFAULT CURRENT_DATETIME();

  BEGIN

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
      -- Data Vault hash keys
      (SHA256(CONCAT(Src.Country, '^', Src.LabelNo, '^', Src.ProductCode, '^', Src.ServiceItem))) AS Label_Product_ServiceItem_HSK,
      (SHA256(CONCAT(Src.Country, '^', Src.LabelNo)))                                            AS LabelNo_HSK,
      (SHA256(CONCAT(Src.Country, '^', Src.ProductCode)))                                        AS Product_HSK,
      (SHA256(CONCAT(Src.Country, '^', Src.ServiceItem)))                                        AS ServiceItem_HSK,
      Src.LabelNo,
      Src.ConId,
      Src.ConItemId,
      Src.LineNo,
      Src.CountryCode,
      Src.Country,
      Src.ProductId,
      Src.ProductCode,
      Src.ServiceItemId,
      Src.ServiceItem,
      Src.CreatedOn,
      Src.FMSInvoiceNo,
      Src.FMSInvoiceDate,
      Src.Price,
      Src.Tax,
      Src.Total,
      Src.PickUpPrice,
      Src.DeliveryPrice,
      Src.DLBSBatchId,
      Src.DLBSInvoiceNo,
      Src.DLBSInvoiceDate,
      Src.DLBSPrice,
      Src.DLBSTax,
      Src.DLBSTotal,
      Src.PLBSBatchId,
      Src.PLBSInvoiceNo,
      Src.PLBSInvoiceDate,
      Src.PLBSPrice,
      Src.PLBSTax,
      Src.PLBSTotal,
      Src.BareProfileId,
      Src.ServicePrice,
      Src.ServicePriceComm,
      Src.ServicePriceCommPercent,
      Src.ServicePriceDiscountFixed,
      Src.ServicePriceDiscountPercent,
      Src.UpdatedOn,
      v_Loaded          AS Loaded,
      p_ProcessId       AS ProcessId,
      p_RecordSource    AS RecordSource,
      Src.ServiceItemId AS RecordSourceId
    FROM (
      SELECT DISTINCT
        Srv.Label                                                                        AS LabelNo,
        Srv.ConId,
        Srv.ConItemId,
        Srv.LineNo,
        Srv.CountryId                                                                    AS CountryCode,
        IFNULL(cty.CountryName, 'Unknown')                                               AS Country,
        Srv.ProductId,
        Prod.Code                                                                        AS ProductCode,
        Srv.ServiceItemId,
        IFNULL(
          IF(si.DisplayText <> '', si.DisplayText, si.Description),
          REPLACE('(:1:)', ':1:', CAST(Srv.ServiceItemId AS STRING))
        )                                                                                AS ServiceItem,
        Srv.CreatedOn,
        Srv.FMSInvoiceNo,
        Srv.FMSInvoiceDate,
        Srv.Price,
        Srv.Tax,
        Srv.Total,
        Srv.PickUpPrice,
        Srv.DeliveryPrice,
        Srv.DLBSBatchId,
        Srv.DLBSInvoiceNo,
        Srv.DLBSInvoiceDate,
        Srv.DLBSPrice,
        Srv.DLBSTax,
        Srv.DLBSTotal,
        Srv.PLBSBatchId,
        Srv.PLBSInvoiceNo,
        Srv.PLBSInvoiceDate,
        Srv.PLBSPrice,
        Srv.PLBSTax,
        Srv.PLBSTotal,
        Srv.BareProfileId,
        Srv.ServicePrice,
        Srv.ServicePriceComm,
        Srv.ServicePriceCommPercent,
        Srv.ServicePriceDiscountFixed,
        Srv.ServicePriceDiscountPercent,
        Srv.UpdatedOn
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_fl_ConItemSrv_Stg` AS Srv
      LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Country` cty
        ON cty.CountryCode   = Srv.CountryId
      LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Product_Stg` AS Prod
        ON Srv.CountryId     = Prod.CountryCode
       AND Srv.ProductId     = Prod.ProductId
      INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_fl_ServiceItem_Stg` AS SI   -- INNER JOIN preserved from original
        ON Srv.CountryId     = SI.CountryId
       AND Srv.ProductId     = SI.ProductId
       AND Srv.ServiceItemId = SI.ServiceItemId
    ) AS Src;

    -- Capture inserted row count scoped to this process
    SET v_Inserted = (
      SELECT COUNT(*)
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Label_Product_ServiceItem_Stg`
      WHERE ProcessId = p_ProcessId
        AND Loaded    = v_Loaded
    );

    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result       = 'Failed';
    SET v_ErrorMessage = @@error.message;

  END;

  -- -----------------------------------------------------------------------
  -- Record load metrics in log
  -- -----------------------------------------------------------------------
  SET v_Ended = CURRENT_DATETIME();

  CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
    v_Component,
    p_ProcessId,
    v_Started,
    v_Ended,
    v_Result,
    v_ErrorMessage,
    v_Inserted,
    -1,
    -1
  );

END;