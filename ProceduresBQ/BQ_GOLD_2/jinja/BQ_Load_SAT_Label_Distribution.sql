-- ==========================================================================================
-- Routine:		Load_SAT_Label_Distribution
-- Description: Loads attributes into SAT_Label_Distribution from LabelMaster
-- Example:		Exec [dv].[Load_SAT_Label_Distribution] 388, 'LabelMaster' 
-- History:
--	20/11/2018  P. Waldron		Routine Written
--  27/06/2019  P. Waldron      Refactor to use SAT_Label_Distribution instead of SAT_Label
--  12/12/2019  P. Waldron      Add CustomerKey
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_SAT_Label_Distribution`(
  IN p_ProcessId    INT64,
  IN p_RecordSource STRING
)
BEGIN

  DECLARE v_Component     STRING DEFAULT 'dv_Load_SAT_Label_Distribution';
  DECLARE v_Started       DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended         DATETIME;
  DECLARE v_Result        STRING;
  DECLARE v_ErrorMessage  STRING;
  DECLARE v_Inserted      INT64 DEFAULT 0;
  DECLARE v_Updated       INT64 DEFAULT 0;
  DECLARE v_Loaded        DATETIME DEFAULT CURRENT_DATETIME();

  BEGIN

    -- -----------------------------------------------------------------------
    -- Step 1: MERGE logic (Expire old and Insert brand new)
    -- -----------------------------------------------------------------------
    MERGE `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Distribution` AS Tgt
    USING (
      SELECT * FROM (
        SELECT
          Sat.LabelNo_HSK,
          Stg.LabelNo,
          Stg.CountryCode,
          IFNULL(cty.CountryName, 'Unknown')    AS Country,
          Stg.Electronic_CustomerType,
          Stg.Electronic_CustomerID,
          Stg.Electronic_Reference,
          Stg.FastLabel_ConsignmentID,
          Stg.FastLabel_DestinationRF,
          Stg.Distribution_Date,
          Stg.Distribution_FranchiseeCode,
          Stg.OES_CustomerID                    AS OESCustomerID,
          Stg.FMSCustomerID,
          Stg.FMSRfID,
          ROW_NUMBER() OVER (
            PARTITION BY Stg.LabelNo, Stg.CountryCode
            ORDER BY Stg.Distribution_Date DESC
          )                                     AS RowNum
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_LabelMaster_Stg` Stg
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` cty
          ON cty.CountryCode = Stg.CountryCode
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Distribution` Sat
          ON  Sat.LabelNo    = Stg.LabelNo
          AND Sat.CountryCode = Stg.CountryCode
          AND Sat.IsCurrent  = 1
      ) S
      WHERE RowNum = 1
    ) AS Src
    ON  Tgt.LabelNo    = Src.LabelNo
    AND Tgt.CountryCode = Src.CountryCode
    AND Tgt.IsCurrent  = 1

    -- Expire changed records
    WHEN MATCHED AND (
        -- FIX: Every numeric/ID field is cast to STRING to allow comparison via '' fallback
        IFNULL(CAST(Tgt.LabelNo AS STRING),                    '') != IFNULL(CAST(Src.LabelNo AS STRING),                    '') OR
        IFNULL(CAST(Tgt.CountryCode AS STRING),                '') != IFNULL(CAST(Src.CountryCode AS STRING),                '') OR
        IFNULL(Tgt.Country,                                    '') != IFNULL(Src.Country,                                    '') OR
        IFNULL(CAST(Tgt.Electronic_CustomerType AS STRING),    '') != IFNULL(CAST(Src.Electronic_CustomerType AS STRING),    '') OR
        IFNULL(CAST(Tgt.Electronic_CustomerID AS STRING),      '') != IFNULL(CAST(Src.Electronic_CustomerID AS STRING),      '') OR
        IFNULL(Tgt.Electronic_Reference,                       '') != IFNULL(Src.Electronic_Reference,                       '') OR
        IFNULL(CAST(Tgt.FastLabel_ConsignmentID AS STRING),    '') != IFNULL(CAST(Src.FastLabel_ConsignmentID AS STRING),    '') OR
        IFNULL(Tgt.FastLabel_DestinationRF,                    '') != IFNULL(Src.FastLabel_DestinationRF,                    '') OR
        IFNULL(CAST(Tgt.Distribution_Date AS STRING),          '') != IFNULL(CAST(Src.Distribution_Date AS STRING),          '') OR
        IFNULL(Tgt.Distribution_FranchiseeCode,                '') != IFNULL(Src.Distribution_FranchiseeCode,                '') OR
        IFNULL(CAST(Tgt.OESCustomerID AS STRING),              '') != IFNULL(CAST(Src.OESCustomerID AS STRING),              '') OR
        IFNULL(CAST(Tgt.FMSCustomerID AS STRING),              '') != IFNULL(CAST(Src.FMSCustomerID AS STRING),              '') OR
        IFNULL(CAST(Tgt.FMSRfID AS STRING),                    '') != IFNULL(CAST(Src.FMSRfID AS STRING),                    '')
    )
    THEN UPDATE SET
      IsCurrent = 0,
      ValidTo   = v_Loaded

    -- Insert brand-new records
    WHEN NOT MATCHED BY TARGET
    THEN INSERT (
      LabelNo_HSK, LabelNo, CountryCode, Country,
      Electronic_CustomerType, Electronic_CustomerID, Electronic_Reference,
      FastLabel_ConsignmentID, FastLabel_DestinationRF, Distribution_Date,
      Distribution_FranchiseeCode, OESCustomerID, FMSCustomerID, FMSRfID,
      Loaded, ProcessId, RecordSource, ValidFrom, ValidTo, IsCurrent
    )
    VALUES (
      `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(Src.LabelNo),
      Src.LabelNo, Src.CountryCode, Src.Country,
      Src.Electronic_CustomerType, Src.Electronic_CustomerID, Src.Electronic_Reference,
      Src.FastLabel_ConsignmentID, Src.FastLabel_DestinationRF, Src.Distribution_Date,
      Src.Distribution_FranchiseeCode, Src.OESCustomerID, Src.FMSCustomerID, Src.FMSRfID,
      v_Loaded, p_ProcessId, p_RecordSource,
      DATETIME '1900-01-01 00:00:00', DATETIME '9999-12-31 00:00:00', 1
    );

    -- -----------------------------------------------------------------------
    -- Step 2: Insert new current versions for expired records
    -- -----------------------------------------------------------------------
    INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Distribution`
    (
      LabelNo_HSK, LabelNo, CountryCode, Country,
      Electronic_CustomerType, Electronic_CustomerID, Electronic_Reference,
      FastLabel_ConsignmentID, FastLabel_DestinationRF, Distribution_Date,
      Distribution_FranchiseeCode, OESCustomerID, FMSCustomerID, FMSRfID,
      Loaded, ProcessId, RecordSource, ValidFrom, ValidTo, IsCurrent
    )
    WITH LatestSrc AS (
      SELECT * FROM (
        SELECT
          Stg.LabelNo,
          Stg.CountryCode,
          IFNULL(cty.CountryName, 'Unknown')    AS Country,
          Stg.Electronic_CustomerType,
          Stg.Electronic_CustomerID,
          Stg.Electronic_Reference,
          Stg.FastLabel_ConsignmentID,
          Stg.FastLabel_DestinationRF,
          Stg.Distribution_Date,
          Stg.Distribution_FranchiseeCode,
          Stg.OES_CustomerID                    AS OESCustomerID,
          Stg.FMSCustomerID,
          Stg.FMSRfID,
          ROW_NUMBER() OVER (
            PARTITION BY Stg.LabelNo, Stg.CountryCode
            ORDER BY Stg.Distribution_Date DESC
          )                                     AS RowNum
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_LabelMaster_Stg` Stg
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` cty
          ON cty.CountryCode = Stg.CountryCode
      ) S
      WHERE RowNum = 1
    )
    SELECT
      Sat.LabelNo_HSK,
      Src.LabelNo, Src.CountryCode, Src.Country,
      Src.Electronic_CustomerType, Src.Electronic_CustomerID, Src.Electronic_Reference,
      Src.FastLabel_ConsignmentID, Src.FastLabel_DestinationRF, Src.Distribution_Date,
      Src.Distribution_FranchiseeCode, Src.OESCustomerID, Src.FMSCustomerID, Src.FMSRfID,
      v_Loaded, p_ProcessId, p_RecordSource,
      v_Loaded AS ValidFrom, DATETIME '9999-12-31 00:00:00' AS ValidTo, 1 AS IsCurrent
    FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Distribution` Sat
    INNER JOIN LatestSrc Src
      ON  Sat.LabelNo    = Src.LabelNo
      AND Sat.CountryCode = Src.CountryCode
    WHERE Sat.IsCurrent      = 0
      AND Sat.ValidTo        = v_Loaded;

    -- Update counts for logging
    SET v_Updated = (SELECT COUNTIF(IsCurrent = 0 AND ValidTo = v_Loaded) FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Distribution` WHERE ProcessId = p_ProcessId);
    SET v_Inserted = (SELECT COUNTIF(IsCurrent = 1 AND ValidFrom = v_Loaded) FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Distribution` WHERE ProcessId = p_ProcessId);

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