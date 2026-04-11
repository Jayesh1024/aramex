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
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ dataset_id }}.dv_Load_SAT_Product`(
  IN p_ProcessId    INT64,
  IN p_RecordSource STRING
)
BEGIN

  DECLARE v_Component     STRING DEFAULT 'dv.Load_SAT_Product';
  DECLARE v_Started       DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended         DATETIME;
  DECLARE v_Result        STRING;
  DECLARE v_ErrorMessage  STRING;
  DECLARE v_Inserted      INT64 DEFAULT 0;
  DECLARE v_Updated       INT64 DEFAULT 0;
  DECLARE v_Loaded        DATETIME DEFAULT CURRENT_DATETIME();

  BEGIN

    -- -----------------------------------------------------------------------
    -- Step 1: Expire changed current records + insert brand-new records
    -- BQ MERGE does not support EXCEPT in WHEN MATCHED predicate;
    -- explicit column inequality used instead
    -- -----------------------------------------------------------------------
    MERGE `{{ project_id }}.{{ dataset_id }}.dv_SAT_Product` AS Tgt
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
      FROM `{{ project_id }}.{{ dataset_id }}.staging_Product_Stg` Stg
      LEFT JOIN `{{ project_id }}.{{ dataset_id }}.dv_SAT_Product` Sat
        ON  Sat.Country     = Stg.Country
        AND Sat.ProductCode = Stg.Code
        AND Sat.IsCurrent   = 1
    ) AS Src
    ON  Tgt.Product_HSK = Src.Product_HSK
    AND Tgt.IsCurrent   = 1

    -- Expire changed records
    WHEN MATCHED AND (
        Tgt.Country           != Src.Country           OR
        Tgt.ProductCode       != Src.ProductCode       OR
        Tgt.ProductId         != Src.ProductId         OR
        Tgt.Description       != Src.Description       OR
        Tgt.ItemType          != Src.ItemType          OR
        Tgt.LabelPrefix       != Src.LabelPrefix       OR
        Tgt.LabelsPerBook     != Src.LabelsPerBook     OR
        Tgt.Price             != Src.Price             OR
        Tgt.FMSBookPrice      != Src.FMSBookPrice      OR
        Tgt.FMSDeliveryPrice  != Src.FMSDeliveryPrice  OR
        Tgt.FMSPickupPrice    != Src.FMSPickupPrice    OR
        Tgt.IncludesGST       != Src.IncludesGST       OR
        Tgt.FMSSalesType      != Src.FMSSalesType      OR
        Tgt.ProductCategory   != Src.ProductCategory   OR
        Tgt.NotSoldByFSO      != Src.NotSoldByFSO      OR
        IFNULL(CAST(Tgt.SAPGroup AS STRING),        '') != IFNULL(CAST(Src.SAPGroup AS STRING),        '') OR
        IFNULL(CAST(Tgt.SAPProductGroup AS STRING), '') != IFNULL(CAST(Src.SAPProductGroup AS STRING), '') OR
        IFNULL(CAST(Tgt.SAPSubProduct AS STRING),   '') != IFNULL(CAST(Src.SAPSubProduct AS STRING),   '')
    )
    THEN UPDATE SET
      IsCurrent = 0,
      ValidTo   = v_Loaded

    -- Insert brand-new records (no existing HSK match)
    WHEN NOT MATCHED BY TARGET
    THEN INSERT (
      Product_HSK,
      Country,
      ProductCode,
      ProductId,
      Description,
      ItemType,
      LabelPrefix,
      LabelsPerBook,
      Price,
      FMSBookPrice,
      FMSDeliveryPrice,
      FMSPickupPrice,
      IncludesGST,
      FMSSalesType,
      ProductCategory,
      NotSoldByFSO,
      SAPGroup,
      SAPProductGroup,
      SAPSubProduct,
      Loaded,
      ProcessId,
      RecordSource,
      ValidFrom,
      ValidTo,
      IsCurrent
    )
    VALUES (
      -- Hash key: Country ^^ ProductId — matches updated GetHashKey logic
      TO_HEX(MD5(CONCAT(Src.Country, '^', CAST(Src.ProductId AS STRING)))),
      Src.Country,
      Src.ProductCode,
      Src.ProductId,
      Src.Description,
      Src.ItemType,
      Src.LabelPrefix,
      Src.LabelsPerBook,
      Src.Price,
      Src.FMSBookPrice,
      Src.FMSDeliveryPrice,
      Src.FMSPickupPrice,
      Src.IncludesGST,
      Src.FMSSalesType,
      Src.ProductCategory,
      Src.NotSoldByFSO,
      Src.SAPGroup,
      Src.SAPProductGroup,
      Src.SAPSubProduct,
      v_Loaded,
      p_ProcessId,
      p_RecordSource,
      DATETIME '1900-01-01 00:00:00',
      DATETIME '9999-12-31 00:00:00',
      1
    );

    -- -----------------------------------------------------------------------
    -- Step 2: Insert new current versions for expired records
    -- Joins rows just expired in Step 1 back to source to produce
    -- the new IsCurrent = 1 row — replaces OUTPUT $action pattern
    -- -----------------------------------------------------------------------
    INSERT INTO `{{ project_id }}.{{ dataset_id }}.dv_SAT_Product`
    (
      Product_HSK,
      Country,
      ProductCode,
      ProductId,
      Description,
      ItemType,
      LabelPrefix,
      LabelsPerBook,
      Price,
      FMSBookPrice,
      FMSDeliveryPrice,
      FMSPickupPrice,
      IncludesGST,
      FMSSalesType,
      ProductCategory,
      NotSoldByFSO,
      SAPGroup,
      SAPProductGroup,
      SAPSubProduct,
      Loaded,
      ProcessId,
      RecordSource,
      ValidFrom,
      ValidTo,
      IsCurrent
    )
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
      Stg.SAPSubProduct,
      v_Loaded,
      p_ProcessId,
      p_RecordSource,
      v_Loaded                          AS ValidFrom,
      DATETIME '9999-12-31 00:00:00'    AS ValidTo,
      1                                 AS IsCurrent
    FROM `{{ project_id }}.{{ dataset_id }}.dv_SAT_Product` Sat
    INNER JOIN `{{ project_id }}.{{ dataset_id }}.staging_Product_Stg` Stg
      ON  Sat.Country     = Stg.Country
      AND Sat.ProductCode = Stg.Code
    WHERE Sat.IsCurrent        = 0
      AND Sat.ValidTo          = v_Loaded
      AND Sat.Product_HSK      IS NOT NULL;

    -- -----------------------------------------------------------------------
    -- Derive insert / update counts
    -- Replaces PIVOT on IsCurrent — matches Load_SAT_RF pattern
    -- -----------------------------------------------------------------------
    SET v_Updated = (
      SELECT COUNTIF(IsCurrent = 0)
      FROM `{{ project_id }}.{{ dataset_id }}.dv_SAT_Product`
      WHERE ProcessId = p_ProcessId
        AND ValidTo   = v_Loaded
    );

    SET v_Inserted = (
      SELECT COUNTIF(IsCurrent = 1)
      FROM `{{ project_id }}.{{ dataset_id }}.dv_SAT_Product`
      WHERE ProcessId = p_ProcessId
        AND ValidFrom = v_Loaded
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

  CALL `{{ project_id }}.{{ dataset_id }}.staging_SaveLog`(
    v_Component,
    p_ProcessId,
    v_Started,
    v_Ended,
    v_Result,
    v_ErrorMessage,
    v_Inserted,
    v_Updated,
    -1
  );

END;