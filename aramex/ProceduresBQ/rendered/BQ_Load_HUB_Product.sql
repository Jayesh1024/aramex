-- ==========================================================================================
-- Routine:     Load_HUB_Product
-- Description: Loads business keys into HUB_Product
-- Example:     Exec [dv].[Load_HUB_Product] 123, 'Fastway'  
-- History:
--  13/11/2018  P. Waldron      Routine Written
--  05/09/2022  B. Woods    Changed primary key to use ProductId instead of ProductCode
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `searce-sandbox-da-delivery.Aramex_oceania_SP.dv_Load_HUB_Product`(
  p_ProcessID INT64,
  p_RecordSource STRING
)
BEGIN
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Status STRING DEFAULT 'Success';
  DECLARE v_Error_Msg STRING DEFAULT NULL;
  DECLARE v_Inserted_Count INT64 DEFAULT 0;

  BEGIN
    -- BigQuery MERGE for idempotent business key insertion
    MERGE `searce-sandbox-da-delivery.Aramex_oceania.dv_HUB_Product` AS Target
    USING (
      SELECT DISTINCT
        -- Hashing: Country + '^' + ProductId (SHA256 returns BYTES)
        SHA256(CONCAT(TRIM(Country), '^', CAST(ProductId AS STRING))) AS Product_HSK,
        TRIM(Country) AS Country,
        ProductId,
        TRIM(Code) AS ProductCode,
        v_Loaded AS Loaded,
        p_ProcessID AS ProcessID,
        p_RecordSource AS RecordSource
      FROM `searce-sandbox-da-delivery.Aramex_oceania.Staging_Product_Stg`
      WHERE ProductId IS NOT NULL 
        AND Country IS NOT NULL
    ) AS Source
    ON Target.Product_HSK = Source.Product_HSK
    WHEN NOT MATCHED THEN
      INSERT (Product_HSK, Country, ProductId, ProductCode, Loaded, ProcessID, RecordSource)
      VALUES (Source.Product_HSK, Source.Country, Source.ProductId, Source.ProductCode, Source.Loaded, Source.ProcessID, Source.RecordSource);

    SET v_Inserted_Count = @@row_count;

  EXCEPTION WHEN ERROR THEN
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- Metadata Logging
  CALL `searce-sandbox-da-delivery.Aramex_oceania_SP.Staging_SaveLog`(
    'dv_Load_HUB_Product',
    p_ProcessID,
    v_Started,
    CURRENT_DATETIME(),
    v_Status,
    v_Error_Msg,
    v_Inserted_Count,
    0,
    0
  );

  IF v_Status = 'Failed' THEN
    RAISE USING MESSAGE = v_Error_Msg;
  END IF;

END;