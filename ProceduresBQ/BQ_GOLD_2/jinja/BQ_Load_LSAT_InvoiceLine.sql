-- ==========================================================================================
-- Routine:		Load_LSAT_InvoiceLine
-- Description: Loads Invoice Lines into into [dv].[LSAT_InvoiceLine]
-- Example:		Exec [dv].[Load_LSAT_InvoiceLine2] 453 
-- History:
--	27/12/2019  P. Waldron		Routine Written
--	24/03/2019  P. Waldron		Add EnteredDate to dv_LSAT_InvoiceLine
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_LSAT_InvoiceLine`(IN p_ProcessID INT64, IN p_RecordSource STRING)
BEGIN
  /*
  ** Routine: Load_LSAT_InvoiceLine
  ** Description: Loads Invoice Lines into into dv_LSAT_InvoiceLine
  */

  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();

  DECLARE v_Component STRING DEFAULT 'dv_Load_LSAT_InvoiceLine';
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING;
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_Inserted INT64 DEFAULT 0;
  DECLARE v_Updated INT64 DEFAULT 0;
  BEGIN
    -- Only INSERT is present in the source logic, so using INSERT ... SELECT per CORE RULES.
    INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_LSAT_InvoiceLine` (
      InvoiceLine_HSK, 
      Invoice_HSK,
      FranchiseeCode_HSK,
      Courier_HSK,
      Customer_HSK,
      Product_HSK,
      InvoiceNumber,
      FranchiseeCode,
      CourierNumber,
      CustomerKey,
      ProductCode,
      Country,
      EnteredDate,
      SystemDate,
      InvoiceDateInvLine,
      Qty,
      Price,
      Commission,
      PayCommission,
      PriceDiscounted,
      GSTAmount,
      SaleType,
      LineType,
      Loaded,
      ProcessId,
      RecordSource
    )
    WITH RawData AS (
      SELECT DISTINCT
        ih.InvoiceNumber,
        ih.RFCode AS FranchiseeCode,
        ih.CourierInvoiceBelongsTo AS CourierNumber,
        cust.CustomerKey,
        ps.Code AS ProductCode,
        c.CountryName AS Country,
        ih.EnteredDate,
        ih.SystemDate,
        il.InvoiceDateInvLine,
        il.Qty,
        il.Price,
        il.Commission,
        il.PayCommission,
        il.PriceDiscounted,
        il.GSTAmount,
        il.SaleType,
        il.LineType
      FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_FMS_InvoiceHead_Stg` AS ih
      JOIN `{{ project_id }}.{{ target_dataset_id }}.Staging_FMS_InvoiceLines_Stg` AS il ON il.InvoiceNumber = ih.InvoiceNumber
      JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` AS c ON c.CountryCode = il.NMId 
      JOIN `{{ project_id }}.{{ target_dataset_id }}.Staging_Product_Stg` AS ps ON ps.ProductId = il.ProductId AND ps.Country = c.CountryName 
      INNER JOIN (
        -- Replacing T-SQL CROSS APPLY Top 1 logic
        SELECT 
          CustomerID, 
          RFId, 
          CustomerKey, 
          ROW_NUMBER() OVER (PARTITION BY CustomerID, RFId ORDER BY Active DESC) as rn
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_FMS_Customer_Stg`
      ) AS cust ON cust.CustomerID = ih.CustomerId AND cust.RFId = il.RFId AND cust.rn = 1
    ),
    NewInvoiceLines AS (
      SELECT 
        `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(CONCAT(CAST(InvoiceNumber AS STRING), '^', FranchiseeCode, '^', CourierNumber, '^', CustomerKey, '^', ProductCode, '^', Country), '^') AS InvoiceLine_HSK,
        `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(CONCAT(CAST(InvoiceNumber AS STRING), '^', FranchiseeCode), '^') AS Invoice_HSK,
        `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(FranchiseeCode, '^') AS FranchiseeCode_HSK,
        `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(CONCAT(FranchiseeCode, '^', CourierNumber), '^') AS Courier_HSK,
        `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(CustomerKey, '^') AS Customer_HSK,
        `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(CONCAT(Country, '^', ProductCode), '^') AS Product_HSK,
        InvoiceNumber,
        FranchiseeCode,
        CourierNumber,
        CustomerKey,
        ProductCode,
        Country,
        EnteredDate,
        SystemDate,
        InvoiceDateInvLine,
        Qty,
        Price,
        Commission,
        PayCommission,
        PriceDiscounted,
        GSTAmount,
        SaleType,
        LineType
      FROM RawData AS Src
      WHERE NOT EXISTS (
        SELECT 1 FROM `{{ project_id }}.{{ target_dataset_id }}.dv_LSAT_InvoiceLine` AS Tgt WHERE Tgt.InvoiceLine_HSK = `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(CONCAT(CAST(Src.InvoiceNumber AS STRING), '^', Src.FranchiseeCode, '^', Src.CourierNumber, '^', Src.CustomerKey, '^', Src.ProductCode, '^', Src.Country), '^')
      )
    )
    SELECT
      InvoiceLine_HSK,
      Invoice_HSK,
      FranchiseeCode_HSK,
      Courier_HSK,
      Customer_HSK,
      Product_HSK,
      InvoiceNumber,
      FranchiseeCode,
      CourierNumber,
      CustomerKey,
      ProductCode,
      Country,
      EnteredDate,
      SystemDate,
      InvoiceDateInvLine,
      Qty,
      Price,
      Commission,
      PayCommission,
      PriceDiscounted,
      GSTAmount,
      SaleType,
      LineType,
      v_Loaded AS Loaded,
      p_ProcessId AS ProcessId,
      p_RecordSource
    FROM NewInvoiceLines;

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