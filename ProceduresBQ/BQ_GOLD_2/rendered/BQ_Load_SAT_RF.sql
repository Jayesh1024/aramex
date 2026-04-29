-- ==========================================================================================
-- Routine:		Load_SAT_RF
-- Description: Loads attributes into SAT_RF 
-- Example:		Exec [dv].[Load_SAT_RF] 123, 'Fastway' 
-- History:
--	09/11/2018  P. Waldron		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_SAT_RF`(
  IN p_ProcessId    INT64,
  IN p_RecordSource STRING
)
BEGIN

  DECLARE v_Component     STRING DEFAULT 'dv_Load_SAT_RF';
  DECLARE v_Started       DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended         DATETIME;
  DECLARE v_Result        STRING;
  DECLARE v_ErrorMessage  STRING;
  DECLARE v_Inserted      INT64 DEFAULT 0;
  DECLARE v_Updated       INT64 DEFAULT 0;
  DECLARE v_Loaded        DATETIME DEFAULT CURRENT_DATETIME();

  BEGIN

    -- -----------------------------------------------------------------------
    -- Step 1: Expire changed current records and Insert brand-new HSKs
    -- -----------------------------------------------------------------------
    MERGE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_RF` AS Tgt
    USING (
      SELECT DISTINCT
        -- Generate HSK as BYTES for the join and insert
        SHA256(CAST(Stg.FranchiseeCode AS STRING)) AS Calculated_HSK,
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
        IFNULL(Stg.UsingWebFMSBanking, 0)          AS UsingWebFMSBanking
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Franchisee_Stg` Stg
    ) AS Src
    ON  Tgt.FranchiseeCode_HSK = Src.Calculated_HSK
    AND Tgt.IsCurrent          = 1

    -- 1a. Expire records where the HSK exists but attributes have changed
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

    -- 1b. Insert brand-new records (New Hash Keys never seen before)
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
      Src.Calculated_HSK, -- Already BYTES from the USING subquery
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
      Src.CompanyOwnedRF,
      Src.UsingWebFMSBanking,
      v_Loaded,
      p_ProcessId,
      p_RecordSource,
      DATETIME '1900-01-01 00:00:00',
      DATETIME '9999-12-31 00:00:00',
      1
    );

    -- -----------------------------------------------------------------------
    -- Step 2: Insert new current versions for records that were just expired
    -- -----------------------------------------------------------------------
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_RF`
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
      SHA256(CAST(Stg.FranchiseeCode AS STRING)),
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
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_RF` Sat
    INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Franchisee_Stg` Stg
      ON Sat.FranchiseeCode = Stg.FranchiseeCode
    WHERE Sat.IsCurrent  = 0
      AND Sat.ValidTo    = v_Loaded;

    -- -----------------------------------------------------------------------
    -- Derive insert / update counts
    -- -----------------------------------------------------------------------
    SET v_Updated = (
      SELECT COUNT(1)
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_RF`
      WHERE ProcessId = p_ProcessId
        AND ValidTo   = v_Loaded
        AND IsCurrent = 0
    );

    SET v_Inserted = (
      SELECT COUNT(1)
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_RF`
      WHERE ProcessId = p_ProcessId
        AND ValidFrom = v_Loaded
        AND IsCurrent = 1
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
    v_Updated,
    -1
  );

END;