
-- ==========================================================================================
-- Routine:		Load_SAT_RF
-- Description: Loads attributes into SAT_RF 
-- Example:		Exec [dv].[Load_SAT_RF] 123, 'Fastway' 
-- History:
--	09/11/2018  P. Waldron		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ dataset_id }}.dv_Load_SAT_RF`(
  IN p_ProcessId    INT64,
  IN p_RecordSource STRING
)
BEGIN

  DECLARE v_Component     STRING DEFAULT 'dv.Load_SAT_RF';
  DECLARE v_Started       DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended         DATETIME;
  DECLARE v_Result        STRING;
  DECLARE v_ErrorMessage  STRING;
  DECLARE v_Inserted      INT64 DEFAULT 0;
  DECLARE v_Updated       INT64 DEFAULT 0;
  DECLARE v_Loaded        DATETIME DEFAULT CURRENT_DATETIME();

  BEGIN

    -- -----------------------------------------------------------------------
    -- Step 1: Expire changed current records (WHEN MATCHED AND changed → UPDATE)
    -- BQ MERGE does not support EXCEPT in WHEN MATCHED predicate;
    -- explicit column inequality used instead
    -- -----------------------------------------------------------------------
    MERGE `{{ project_id }}.{{ dataset_id }}.dv_SAT_RF` AS Tgt
    USING (
      SELECT DISTINCT
        Sat.FranchiseeCode_HSK,
        Stg.FranchiseeCode,
        Stg.CountryCode,
        Stg.RFId,
        IFNULL(TRIM(Stg.Name),                '') AS Name,
        IFNULL(TRIM(Stg.LegalTradingEntity),  '') AS LegalTradingEntity,
        IFNULL(TRIM(Stg.TaxNumber),           '') AS TaxNumber,
        IFNULL(TRIM(Stg.ABN),                 '') AS ABN,
        IFNULL(TRIM(Stg.ACN),                 '') AS ACN,
        IFNULL(TRIM(Stg.Phone),               '') AS Phone,
        IFNULL(TRIM(Stg.Fax),                 '') AS Fax,
        -- Inline replacement for dbo.FormatAddress(Add1, Add2, Add3, Add4)
        -- Joins non-null, non-empty address parts with ', '
        ARRAY_TO_STRING(
          ARRAY(
            SELECT part FROM UNNEST([
              NULLIF(TRIM(Stg.Add1), ''),
              NULLIF(TRIM(Stg.Add2), ''),
              NULLIF(TRIM(Stg.Add3), ''),
              NULLIF(TRIM(Stg.Add4), '')
            ]) AS part
            WHERE part IS NOT NULL
          ), ', '
        )                                          AS Address,
        IFNULL(Stg.CompanyOwnedRF,    0)           AS CompanyOwnedRF,
        IFNULL(Stg.UsingWebFMSBanking, 0)          AS UsingWebFMSBanking
      FROM `{{ project_id }}.{{ dataset_id }}.staging_Franchisee_Stg` Stg
      LEFT JOIN `{{ project_id }}.{{ dataset_id }}.dv_SAT_RF` Sat
        ON Sat.FranchiseeCode = Stg.FranchiseeCode
    ) AS Src
    ON  Tgt.FranchiseeCode_HSK = Src.FranchiseeCode_HSK
    AND Tgt.IsCurrent          = 1

    -- Expire changed records
    WHEN MATCHED AND (
        Tgt.FranchiseeCode      != Src.FranchiseeCode      OR
        Tgt.CountryCode         != Src.CountryCode         OR
        Tgt.RFId                != Src.RFId                OR
        Tgt.Name                != Src.Name                OR
        Tgt.LegalTradingEntity  != Src.LegalTradingEntity  OR
        Tgt.TaxNumber           != Src.TaxNumber           OR
        Tgt.ABN                 != Src.ABN                 OR
        Tgt.ACN                 != Src.ACN                 OR
        Tgt.Phone               != Src.Phone               OR
        Tgt.Fax                 != Src.Fax                 OR
        Tgt.Address             != Src.Address             OR
        Tgt.CompanyOwnedRF      != Src.CompanyOwnedRF      OR
        Tgt.UsingWebFMSBanking  != Src.UsingWebFMSBanking
    )
    THEN UPDATE SET
      IsCurrent = 0,
      ValidTo   = v_Loaded

    -- Insert brand-new records (no existing HSK match)
    WHEN NOT MATCHED BY TARGET
    THEN INSERT (
      FranchiseeCode_HSK,
      FranchiseeCode,
      CountryCode,
      RFId,
      Name,
      LegalTradingEntity,
      TaxNumber,
      ABN,
      ACN,
      Phone,
      Fax,
      Address,
      CompanyOwnedRF,
      UsingWebFMSBanking,
      Loaded,
      ProcessId,
      RecordSource,
      ValidFrom,
      ValidTo,
      IsCurrent
    )
    VALUES (
      TO_HEX(SHA256(Src.FranchiseeCode)),
      Src.FranchiseeCode,
      Src.CountryCode,
      Src.RFId,
      Src.Name,
      Src.LegalTradingEntity,
      Src.TaxNumber,
      Src.ABN,
      Src.ACN,
      Src.Phone,
      Src.Fax,
      Src.Address,
      IFNULL(Src.CompanyOwnedRF,    0),
      IFNULL(Src.UsingWebFMSBanking, 0),
      v_Loaded,
      p_ProcessId,
      p_RecordSource,
      DATETIME '1900-01-01 00:00:00',
      DATETIME '9999-12-31 00:00:00',
      1
    );

    -- -----------------------------------------------------------------------
    -- Step 2: Insert new current versions for expired records
    -- Replaces the OUTPUT $action + outer INSERT pattern from SQL Server
    -- Selects rows just expired in Step 1 (ValidTo = v_Loaded, IsCurrent = 0)
    -- and re-joins to source to produce the new IsCurrent = 1 row
    -- -----------------------------------------------------------------------
    INSERT INTO `{{ project_id }}.{{ dataset_id }}.dv_SAT_RF`
    (
      FranchiseeCode_HSK,
      FranchiseeCode,
      CountryCode,
      RFId,
      Name,
      LegalTradingEntity,
      TaxNumber,
      ABN,
      ACN,
      Phone,
      Fax,
      Address,
      CompanyOwnedRF,
      UsingWebFMSBanking,
      Loaded,
      ProcessId,
      RecordSource,
      ValidFrom,
      ValidTo,
      IsCurrent
    )
    SELECT DISTINCT
      Sat.FranchiseeCode_HSK,
      Stg.FranchiseeCode,
      Stg.CountryCode,
      Stg.RFId,
      IFNULL(TRIM(Stg.Name),                '') AS Name,
      IFNULL(TRIM(Stg.LegalTradingEntity),  '') AS LegalTradingEntity,
      IFNULL(TRIM(Stg.TaxNumber),           '') AS TaxNumber,
      IFNULL(TRIM(Stg.ABN),                 '') AS ABN,
      IFNULL(TRIM(Stg.ACN),                 '') AS ACN,
      IFNULL(TRIM(Stg.Phone),               '') AS Phone,
      IFNULL(TRIM(Stg.Fax),                 '') AS Fax,
      ARRAY_TO_STRING(
        ARRAY(
          SELECT part FROM UNNEST([
            NULLIF(TRIM(Stg.Add1), ''),
            NULLIF(TRIM(Stg.Add2), ''),
            NULLIF(TRIM(Stg.Add3), ''),
            NULLIF(TRIM(Stg.Add4), '')
          ]) AS part
          WHERE part IS NOT NULL
        ), ', '
      )                                          AS Address,
      IFNULL(Stg.CompanyOwnedRF,    0)           AS CompanyOwnedRF,
      IFNULL(Stg.UsingWebFMSBanking, 0)          AS UsingWebFMSBanking,
      v_Loaded,
      p_ProcessId,
      p_RecordSource,
      v_Loaded                                   AS ValidFrom,
      DATETIME '9999-12-31 00:00:00'             AS ValidTo,
      1                                          AS IsCurrent
    FROM `{{ project_id }}.{{ dataset_id }}.dv_SAT_RF` Sat
    INNER JOIN `{{ project_id }}.{{ dataset_id }}.staging_Franchisee_Stg` Stg
      ON Sat.FranchiseeCode = Stg.FranchiseeCode
    WHERE Sat.IsCurrent  = 0
      AND Sat.ValidTo    = v_Loaded
      AND Sat.FranchiseeCode_HSK IS NOT NULL;

    -- -----------------------------------------------------------------------
    -- Derive insert / update counts
    -- Replaces PIVOT on IsCurrent
    -- Updated = IsCurrent 0 rows written this load (expired)
    -- Inserted = IsCurrent 1 rows written this load (new current)
    -- -----------------------------------------------------------------------
    SET v_Updated = (
      SELECT COUNTIF(IsCurrent = 0)
      FROM `{{ project_id }}.{{ dataset_id }}.dv_SAT_RF`
      WHERE ProcessId = p_ProcessId
        AND ValidTo   = v_Loaded
    );

    SET v_Inserted = (
      SELECT COUNTIF(IsCurrent = 1)
      FROM `{{ project_id }}.{{ dataset_id }}.dv_SAT_RF`
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