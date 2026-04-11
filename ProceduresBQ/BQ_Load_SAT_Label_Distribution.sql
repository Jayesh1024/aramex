-- ==========================================================================================
-- Routine:		Load_SAT_Label_Distribution
-- Description: Loads attributes into SAT_Label_Distribution from LabelMaster
-- Example:		Exec [dv].[Load_SAT_Label_Distribution] 388, 'LabelMaster' 
-- History:
--	20/11/2018  P. Waldron		Routine Written
--  27/06/2019  P. Waldron      Refactor to use SAT_Label_Distribution instead of SAT_Label
--  12/12/2019  P. Waldron      Add CustomerKey
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ dataset_id }}.dv_Load_SAT_Label_Distribution`(
  IN p_ProcessId    INT64,
  IN p_RecordSource STRING
)
BEGIN

  DECLARE v_Component     STRING DEFAULT 'dv.Load_SAT_Label_Distribution';
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
    -- Source uses ROW_NUMBER() to take the latest Distribution_Date per
    -- LabelNo + CountryCode before merging — preserved from original
    -- -----------------------------------------------------------------------
    MERGE `{{ project_id }}.{{ dataset_id }}.dv_SAT_Label_Distribution` AS Tgt
    USING (
      SELECT * FROM (
        SELECT
          Sat.LabelNo_HSK,
          Stg.LabelNo,
          Stg.CountryCode,
          IFNULL(cty.CountryName, 'Unknown')    AS Country,
          -- Src.CustomerKey,                   -- commented out in original
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
        FROM `{{ project_id }}.{{ dataset_id }}.staging_LabelMaster_Stg` Stg
        LEFT JOIN `{{ project_id }}.{{ dataset_id }}.dbo_Dim_Country` cty
          ON cty.CountryCode = Stg.CountryCode
        LEFT JOIN `{{ project_id }}.{{ dataset_id }}.dv_SAT_Label_Distribution` Sat
          ON  Sat.LabelNo    = Stg.LabelNo
          AND Sat.CountryCode = Stg.CountryCode
          AND Sat.IsCurrent  = 1
        /*
        OUTER APPLY (
          SELECT TOP 1 CustomerKey
          FROM `{{ project_id }}.{{ dataset_id }}.staging_CustomerLinks_Stg` lnk
          WHERE lnk.RFCode      = Stg.Distribution_FranchiseeCode
            AND lnk.CountryCode = Stg.CountryCode
            AND (
              (Stg.FMSCustomerID       IS NOT NULL AND Stg.FMSCustomerID       = lnk.FMSCustomerId)    OR
              (Stg.OES_CustomerId      IS NOT NULL AND Stg.OES_CustomerID      = lnk.OESCustomerId)    OR
              (Stg.Electronic_CustomerID IS NOT NULL AND Stg.Electronic_CustomerID = lnk.IFSCustomerCode
                AND Stg.Electronic_CustomerType = lnk.IFSCustomerType)
            )
        ) ck
        */
      ) S
      WHERE RowNum = 1
    ) AS Src
    ON  Tgt.LabelNo    = Src.LabelNo
    AND Tgt.CountryCode = Src.CountryCode
    AND Tgt.IsCurrent  = 1

    -- Expire changed records
    WHEN MATCHED AND (
        IFNULL(CAST(Tgt.LabelNo AS STRING),                    '') != IFNULL(CAST(Src.LabelNo AS STRING),                    '') OR
        IFNULL(CAST(Tgt.CountryCode AS STRING),                '') != IFNULL(CAST(Src.CountryCode AS STRING),                '') OR
        IFNULL(Tgt.Country,                                    '') != IFNULL(Src.Country,                                    '') OR
        -- Tgt.CustomerKey != Src.CustomerKey                       -- commented out in original
        IFNULL(Tgt.Electronic_CustomerType,                    '') != IFNULL(Src.Electronic_CustomerType,                    '') OR
        IFNULL(Tgt.Electronic_CustomerID,                      '') != IFNULL(Src.Electronic_CustomerID,                      '') OR
        IFNULL(Tgt.Electronic_Reference,                       '') != IFNULL(Src.Electronic_Reference,                       '') OR
        IFNULL(Tgt.FastLabel_ConsignmentID,                    '') != IFNULL(Src.FastLabel_ConsignmentID,                    '') OR
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

    -- Insert brand-new records (no existing LabelNo + CountryCode match)
    WHEN NOT MATCHED BY TARGET
    THEN INSERT (
      LabelNo_HSK,
      LabelNo,
      CountryCode,
      Country,
      -- CustomerKey,                           -- commented out in original
      Electronic_CustomerType,
      Electronic_CustomerID,
      Electronic_Reference,
      FastLabel_ConsignmentID,
      FastLabel_DestinationRF,
      Distribution_Date,
      Distribution_FranchiseeCode,
      OESCustomerID,
      FMSCustomerID,
      FMSRfID,
      Loaded,
      ProcessId,
      RecordSource,
      ValidFrom,
      ValidTo,
      IsCurrent
    )
    VALUES (
      TO_HEX(MD5(Src.LabelNo)),               -- GetHashKey(LabelNo, default)
      Src.LabelNo,
      Src.CountryCode,
      Src.Country,
      -- Src.CustomerKey,                      -- commented out in original
      Src.Electronic_CustomerType,
      Src.Electronic_CustomerID,
      Src.Electronic_Reference,
      Src.FastLabel_ConsignmentID,
      Src.FastLabel_DestinationRF,
      Src.Distribution_Date,
      Src.Distribution_FranchiseeCode,
      Src.OESCustomerID,
      Src.FMSCustomerID,
      Src.FMSRfID,
      v_Loaded,
      p_ProcessId,
      p_RecordSource,
      DATETIME '1900-01-01 00:00:00',
      DATETIME '9999-12-31 00:00:00',
      1
    );

    -- -----------------------------------------------------------------------
    -- Step 2: Insert new current versions for expired records
    -- Re-joins expired rows (ValidTo = v_Loaded, IsCurrent = 0) back to
    -- deduplicated source to produce the new IsCurrent = 1 row
    -- -----------------------------------------------------------------------
    INSERT INTO `{{ project_id }}.{{ dataset_id }}.dv_SAT_Label_Distribution`
    (
      LabelNo_HSK,
      LabelNo,
      CountryCode,
      Country,
      -- CustomerKey,                           -- commented out in original
      Electronic_CustomerType,
      Electronic_CustomerID,
      Electronic_Reference,
      FastLabel_ConsignmentID,
      FastLabel_DestinationRF,
      Distribution_Date,
      Distribution_FranchiseeCode,
      OESCustomerID,
      FMSCustomerID,
      FMSRfID,
      Loaded,
      ProcessId,
      RecordSource,
      ValidFrom,
      ValidTo,
      IsCurrent
    )
    WITH LatestSrc AS (
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
        FROM `{{ project_id }}.{{ dataset_id }}.staging_LabelMaster_Stg` Stg
        LEFT JOIN `{{ project_id }}.{{ dataset_id }}.dbo_Dim_Country` cty
          ON cty.CountryCode = Stg.CountryCode
        LEFT JOIN `{{ project_id }}.{{ dataset_id }}.dv_SAT_Label_Distribution` Sat
          ON  Sat.LabelNo    = Stg.LabelNo
          AND Sat.CountryCode = Stg.CountryCode
          AND Sat.IsCurrent  = 0
          AND Sat.ValidTo    = v_Loaded
      ) S
      WHERE RowNum = 1
    )
    SELECT
      Sat.LabelNo_HSK,
      Src.LabelNo,
      Src.CountryCode,
      Src.Country,
      Src.Electronic_CustomerType,
      Src.Electronic_CustomerID,
      Src.Electronic_Reference,
      Src.FastLabel_ConsignmentID,
      Src.FastLabel_DestinationRF,
      Src.Distribution_Date,
      Src.Distribution_FranchiseeCode,
      Src.OESCustomerID,
      Src.FMSCustomerID,
      Src.FMSRfID,
      v_Loaded,
      p_ProcessId,
      p_RecordSource,
      v_Loaded                              AS ValidFrom,
      DATETIME '9999-12-31 00:00:00'        AS ValidTo,
      1                                     AS IsCurrent
    FROM `{{ project_id }}.{{ dataset_id }}.dv_SAT_Label_Distribution` Sat
    INNER JOIN LatestSrc Src
      ON  Sat.LabelNo    = Src.LabelNo
      AND Sat.CountryCode = Src.CountryCode
    WHERE Sat.IsCurrent      = 0
      AND Sat.ValidTo        = v_Loaded
      AND Sat.LabelNo_HSK    IS NOT NULL;

    -- -----------------------------------------------------------------------
    -- Derive insert / update counts
    -- Replaces PIVOT on IsCurrent — matches Load_SAT_RF / Load_SAT_Product
    -- -----------------------------------------------------------------------
    SET v_Updated = (
      SELECT COUNTIF(IsCurrent = 0)
      FROM `{{ project_id }}.{{ dataset_id }}.dv_SAT_Label_Distribution`
      WHERE ProcessId = p_ProcessId
        AND ValidTo   = v_Loaded
    );

    SET v_Inserted = (
      SELECT COUNTIF(IsCurrent = 1)
      FROM `{{ project_id }}.{{ dataset_id }}.dv_SAT_Label_Distribution`
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