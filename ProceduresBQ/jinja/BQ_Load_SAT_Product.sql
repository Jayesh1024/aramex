-- ==========================================================================================
-- Routine:     Load_SAT_ProductDetails 
-- Description: Loads attributes into SAT_Product 
-- Example:     Exec [dv].[Load_SAT_Product] 123, 'Fastway' 
-- History:
--  15/10/2018  P. Waldron      Routine Written
--  18/11/2019  P. Waldron      Add ProductId
--  05/09/2022	B. Woods		Changed primary key to use ProductId instead of ProductCode
--  09/07/2025  B. Woods		Added additional columns	SAPGroup, SAPProductGroup, SAPSubProduct
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_SAT_Product`(
  IN p_ProcessId    INT64,
  IN p_RecordSource STRING
)
BEGIN

  DECLARE v_Component     STRING DEFAULT 'dv_Load_SAT_Product';
  DECLARE v_Started       DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Result        STRING;
  DECLARE v_ErrorMessage  STRING;
  DECLARE v_Inserted      INT64 DEFAULT 0;
  DECLARE v_Updated       INT64 DEFAULT 0;
  DECLARE v_Loaded        DATETIME DEFAULT CURRENT_DATETIME();

  BEGIN

    -- -----------------------------------------------------------------------
    -- Step 1: Expire changed current records + insert brand-new records
    -- -----------------------------------------------------------------------
    MERGE `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Product` AS Tgt
    USING (
      SELECT DISTINCT
        Sat.Product_HSK,
        RTRIM(Stg.Country)           AS Country,
        Stg.Code                    AS ProductCode,
        Stg.ProductId,
        RTRIM(Stg.Description)       AS Description,
        Stg.ItemType,
        Stg.LabelPrefix,
        Stg.LabelsPerBook,
        Stg.Price,
        Stg.FMSBookPrice,
        Stg.FMSDeliveryPrice,
        Stg.FMSPickupPrice,
        Stg.IncludesGST,
        Stg.FMSSalesType,
        RTRIM(Stg.ProductCategory)   AS ProductCategory,
        Stg.NotSoldByFSO,
        Stg.SAPGroup,
        Stg.SAPProductGroup,
        Stg.SAPSubProduct
      FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Product_Stg` Stg
      LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Product` Sat
        ON  Sat.Country     = Stg.Country
        AND Sat.ProductCode = Stg.Code
        AND Sat.IsCurrent   = 1
    ) AS Src
    ON  Tgt.Product_HSK = Src.Product_HSK
    AND Tgt.IsCurrent   = 1

    -- Expire changed records
    WHEN MATCHED AND (
        IFNULL(Tgt.Country, '')                         != IFNULL(Src.Country, '')                          OR
        IFNULL(Tgt.ProductCode, '')                     != IFNULL(Src.ProductCode, '')                      OR
        IFNULL(CAST(Tgt.ProductId AS STRING), '')       != IFNULL(CAST(Src.ProductId AS STRING), '')        OR
        IFNULL(Tgt.Description, '')                     != IFNULL(Src.Description, '')                      OR
        IFNULL(CAST(Tgt.ItemType AS STRING), '')        != IFNULL(CAST(Src.ItemType AS STRING), '')         OR
        IFNULL(Tgt.LabelPrefix, '')                     != IFNULL(Src.LabelPrefix, '')                      OR
        -- Comparison as strings is fine for the logic, even if the column is INT64
        IFNULL(CAST(Tgt.LabelsPerBook AS STRING), '')   != IFNULL(CAST(Src.LabelsPerBook AS STRING), '')    OR
        IFNULL(CAST(Tgt.Price AS STRING), '')           != IFNULL(CAST(Src.Price AS STRING), '')            OR
        IFNULL(CAST(Tgt.FMSBookPrice AS STRING), '')    != IFNULL(CAST(Src.FMSBookPrice AS STRING), '')     OR
        IFNULL(CAST(Tgt.FMSDeliveryPrice AS STRING), '') != IFNULL(CAST(Src.FMSDeliveryPrice AS STRING), '') OR
        IFNULL(CAST(Tgt.FMSPickupPrice AS STRING), '')  != IFNULL(CAST(Src.FMSPickupPrice AS STRING), '')   OR
        IFNULL(CAST(Tgt.IncludesGST AS STRING), '')     != IFNULL(CAST(Src.IncludesGST AS STRING), '')      OR
        IFNULL(CAST(Tgt.FMSSalesType AS STRING), '')    != IFNULL(CAST(Src.FMSSalesType AS STRING), '')     OR
        IFNULL(Tgt.ProductCategory, '')                 != IFNULL(Src.ProductCategory, '')                  OR
        IFNULL(CAST(Tgt.NotSoldByFSO AS STRING), '')    != IFNULL(CAST(Src.NotSoldByFSO AS STRING), '')     OR
        IFNULL(CAST(Tgt.SAPGroup AS STRING), '')        != IFNULL(CAST(Src.SAPGroup AS STRING), '')         OR
        IFNULL(CAST(Tgt.SAPProductGroup AS STRING), '') != IFNULL(CAST(Src.SAPProductGroup AS STRING), '')  OR
        IFNULL(CAST(Tgt.SAPSubProduct AS STRING), '')   != IFNULL(CAST(Src.SAPSubProduct AS STRING), '')
    )
    THEN UPDATE SET
      IsCurrent = 0,
      ValidTo   = v_Loaded

    -- Insert brand-new records
    WHEN NOT MATCHED BY TARGET
    THEN INSERT (
      Product_HSK, Country, ProductCode, ProductId, Description, ItemType, LabelPrefix,
      LabelsPerBook, Price, FMSBookPrice, FMSDeliveryPrice, FMSPickupPrice, IncludesGST,
      FMSSalesType, ProductCategory, NotSoldByFSO, SAPGroup, SAPProductGroup, SAPSubProduct,
      Loaded, ProcessId, RecordSource, ValidFrom, ValidTo, IsCurrent
    )
    VALUES (
      `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(CONCAT(Src.Country, '^', CAST(Src.ProductId AS STRING))),
      Src.Country, Src.ProductCode, Src.ProductId, Src.Description,
      CAST(Src.ItemType AS STRING),     -- Target is STRING
      Src.LabelPrefix,
      CAST(Src.LabelsPerBook AS INT64), -- FIX: Target is INT64
      Src.Price, Src.FMSBookPrice, Src.FMSDeliveryPrice, Src.FMSPickupPrice, Src.IncludesGST,
      Src.FMSSalesType, Src.ProductCategory, Src.NotSoldByFSO,
      CAST(Src.SAPGroup AS STRING), CAST(Src.SAPProductGroup AS STRING), CAST(Src.SAPSubProduct AS STRING),
      v_Loaded, p_ProcessId, p_RecordSource,
      DATETIME '1900-01-01 00:00:00', DATETIME '9999-12-31 00:00:00', 1
    );

    -- -----------------------------------------------------------------------
    -- Step 2: Insert new current versions for expired records
    -- -----------------------------------------------------------------------
    INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Product`
    (
      Product_HSK, Country, ProductCode, ProductId, Description, ItemType, LabelPrefix,
      LabelsPerBook, Price, FMSBookPrice, FMSDeliveryPrice, FMSPickupPrice, IncludesGST,
      FMSSalesType, ProductCategory, NotSoldByFSO, SAPGroup, SAPProductGroup, SAPSubProduct,
      Loaded, ProcessId, RecordSource, ValidFrom, ValidTo, IsCurrent
    )
    SELECT DISTINCT
      Sat.Product_HSK, RTRIM(Stg.Country), Stg.Code, Stg.ProductId, RTRIM(Stg.Description),
      CAST(Stg.ItemType AS STRING),     -- Target is STRING
      Stg.LabelPrefix,
      CAST(Stg.LabelsPerBook AS INT64), -- FIX: Target is INT64 (Line 107)
      Stg.Price, Stg.FMSBookPrice, Stg.FMSDeliveryPrice, Stg.FMSPickupPrice, Stg.IncludesGST, Stg.FMSSalesType,
      RTRIM(Stg.ProductCategory), Stg.NotSoldByFSO,
      CAST(Stg.SAPGroup AS STRING), CAST(Stg.SAPProductGroup AS STRING), CAST(Stg.SAPSubProduct AS STRING),
      v_Loaded, p_ProcessId, p_RecordSource,
      v_Loaded AS ValidFrom, DATETIME '9999-12-31 00:00:00' AS ValidTo, 1 AS IsCurrent
    FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Product` Sat
    INNER JOIN `{{ project_id }}.{{ target_dataset_id }}.Staging_Product_Stg` Stg
      ON  Sat.Country     = Stg.Country
      AND Sat.ProductCode = Stg.Code
    WHERE Sat.IsCurrent        = 0
      AND Sat.ValidTo          = v_Loaded
      AND Sat.Product_HSK      IS NOT NULL;

    -- Update logging counts
    SET v_Updated = (SELECT COUNTIF(IsCurrent = 0 AND ValidTo = v_Loaded) FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Product` WHERE ProcessId = p_ProcessId);
    SET v_Inserted = (SELECT COUNTIF(IsCurrent = 1 AND ValidFrom = v_Loaded) FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Product` WHERE ProcessId = p_ProcessId);

    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result       = 'Failed';
    SET v_ErrorMessage = @@error.message;
  END;

  -- -----------------------------------------------------------------------
  -- Record load metrics in log
  -- -----------------------------------------------------------------------
  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
    v_Component, p_ProcessId, v_Started, CURRENT_DATETIME(), v_Result, v_ErrorMessage, v_Inserted, v_Updated, -1
  );

END;