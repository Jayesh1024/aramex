-- ==========================================================================================
-- Routine:     Load_HUB_Product
-- Description: Loads business keys into HUB_Product
-- Example:     Exec [dv].[Load_HUB_Product] 123, 'Fastway'  
-- History:
--  13/11/2018  P. Waldron      Routine Written
--  05/09/2022	B. Woods		Changed primary key to use ProductId instead of ProductCode
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `your_project.dv.Load_HUB_Product`(
  p_ProcessID INT64,
  p_RecordSource STRING
)
BEGIN
  DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
  DECLARE v_Inserted_Count INT64 DEFAULT 0;
  DECLARE v_Status STRING DEFAULT 'Success';
  DECLARE v_Error_Msg STRING DEFAULT NULL;

  BEGIN
    -- Using MERGE for set-based idempotency in BigQuery
    MERGE `your_project.dv.HUB_Product` AS Target
    USING (
      SELECT DISTINCT
        -- Hashing: Country + '^' + ProductId (cast to string)
        UPPER(TO_HEX(SHA256(CONCAT(TRIM(Country), '^', CAST(ProductId AS STRING))))) AS Product_HSK,
        TRIM(Country) AS Country,
        ProductId,
        TRIM(ProductCode) AS ProductCode,
        v_Started AS Loaded,
        p_ProcessID AS ProcessID,
        p_RecordSource AS RecordSource
      FROM (
        SELECT 
          Country,
          ProductId,
          Code AS ProductCode
        FROM `your_project.Staging.Product_Stg`
      ) AS Src
      WHERE ProductId IS NOT NULL 
        AND Country IS NOT NULL
    ) AS Source
    ON Target.Product_HSK = Source.Product_HSK
    -- Only insert if the composite key hash doesn't already exist
    WHEN NOT MATCHED THEN
      INSERT (Product_HSK, Country, ProductId, ProductCode, Loaded, ProcessID, RecordSource)
      VALUES (Source.Product_HSK, Source.Country, Source.ProductId, Source.ProductCode, Source.Loaded, Source.ProcessID, Source.RecordSource);

    SET v_Inserted_Count = @@row_count;

  EXCEPTION WHEN ERROR THEN
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- Metadata Logging
  CALL `your_project.Staging.SaveLog`(
    'dv.Load_HUB_Product',
    p_ProcessID,
    v_Started,
    CURRENT_TIMESTAMP(),
    v_Status,
    v_Error_Msg,
    v_Inserted_Count
  );

  IF v_Status = 'Failed' THEN
    ERROR(v_Error_Msg);
  END IF;

END;
