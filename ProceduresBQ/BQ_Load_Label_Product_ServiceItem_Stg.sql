
-- ==========================================================================================
-- Routine:		Load_LNK_Label_Product_ServiceItem
-- Description: Loads Label_Product_ServiceItem_Stg from Staging.fl_ConItemSrv_Stg 
-- Example:		Exec [dv].[Load_Label_Product_ServiceItem_Stg] 659,  'MyFastway' 
-- History:
--	17/08/2020  P. Waldron		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `project.staging.Load_Label_Product_ServiceItem_Stg`(
  IN p_ProcessId    INT64,
  IN p_RecordSource STRING
)
BEGIN

  DECLARE v_Component     STRING DEFAULT 'staging.Load_Label_Product_ServiceItem_Stg';
  DECLARE v_Started       DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended         DATETIME;
  DECLARE v_Result        STRING;
  DECLARE v_ErrorMessage  STRING;
  DECLARE v_Inserted      INT64 DEFAULT 0;
  DECLARE v_Loaded        DATETIME DEFAULT CURRENT_DATETIME();

  BEGIN

    INSERT INTO `project.staging.Label_Product_ServiceItem_Stg`
    (
      Label_Product_ServiceItem_HSK,
      LabelNo_HSK,
      Product_HSK,
      ServiceItem_HSK,
      LabelNo,
      Country,
      ProductCode,
      ServiceItem,
      CountryCode,
      ProductId,
      ServiceItemId,
      CreatedOn,
      ConId,
      LineNo,
      FMSInvoiceNo,
      FMSInvoiceDate,
      Price,
      PickupPrice,
      DeliveryPrice,
      DLBSPrice,
      Loaded,
      ProcessId,
      RecordSource,
      RecordSourceId
    )
    SELECT
      -- Data Vault hash keys — SHA256 over concatenated business keys, uppercased to match GetHashKey convention
      TO_HEX(SHA256(CONCAT(Src.Country, '^', Src.LabelNo, '^', Src.ProductCode, '^', Src.ServiceItem))) AS Label_Product_ServiceItem_HSK,
      TO_HEX(SHA256(CONCAT(Src.Country, '^', Src.LabelNo)))                                            AS LabelNo_HSK,
      TO_HEX(SHA256(CONCAT(Src.Country, '^', Src.ProductCode)))                                        AS Product_HSK,
      TO_HEX(SHA256(CONCAT(Src.Country, '^', Src.ServiceItem)))                                        AS ServiceItem_HSK,
      Src.LabelNo,
      Src.Country,
      Src.ProductCode,
      Src.ServiceItem,
      Src.CountryCode,
      Src.ProductId,
      Src.ServiceItemId,
      Src.CreatedOn,
      Src.ConId,
      Src.LineNo,
      Src.FMSInvoiceNo,
      Src.FMSInvoiceDate,
      Src.Price,
      Src.PickupPrice,
      Src.DeliveryPrice,
      Src.DLBSPrice,
      v_Loaded          AS Loaded,
      p_ProcessId       AS ProcessId,
      p_RecordSource    AS RecordSource,
      Src.ServiceItemId AS RecordSourceId
    FROM (
      SELECT DISTINCT
        Srv.Label                                                                        AS LabelNo,
        IFNULL(cty.CountryName, 'Unknown')                                               AS Country,
        Prod.Code                                                                        AS ProductCode,
        -- IIF(si.DisplayText <> '', si.DisplayText, si.Description) → IF(...) in BQ
        -- REPLACE('(:1:)', ':1:', ServiceItemId) fallback when both DisplayText and Description are null
        IFNULL(
          IF(si.DisplayText <> '', si.DisplayText, si.Description),
          REPLACE('(:1:)', ':1:', CAST(Srv.ServiceItemId AS STRING))
        )                                                                                AS ServiceItem,
        Srv.CountryId                                                                    AS CountryCode,
        Srv.ProductId,
        Srv.ServiceItemId,
        Srv.CreatedOn,
        Srv.ConId,
        Srv.LineNo,
        Srv.FMSInvoiceNo,
        Srv.FMSInvoiceDate,
        Srv.Price,
        Srv.PickupPrice,
        Srv.DeliveryPrice,
        Srv.DLBSPrice
      FROM `project.staging.fl_ConItemSrv_Stg` AS Srv
      LEFT JOIN `project.dbo.Dim_Country` cty
        ON cty.CountryCode  = Srv.CountryId
      LEFT JOIN `project.staging.Product_Stg` AS Prod
        ON Srv.CountryId    = Prod.CountryCode
       AND Srv.ProductId    = Prod.ProductId
      LEFT JOIN `project.staging.fl_ServiceItem_Stg` AS SI
        ON Srv.CountryId    = SI.CountryId
       AND Srv.ProductId    = SI.ProductId
       AND Srv.ServiceItemId = SI.ServiceItemId
    ) AS Src;

    -- Capture inserted row count scoped to this process
    SET v_Inserted = (
      SELECT COUNT(*)
      FROM `project.staging.Label_Product_ServiceItem_Stg`
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

  CALL `project.staging.SaveLog`(
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