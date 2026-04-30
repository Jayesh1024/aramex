-- ==========================================================================================
-- Routine:		Load_SAT_Address (Parcel from/to locations)
-- Description: Loads addresses into SAT_Address  
-- Example:		Exec [dv].[Load_SAT_Address] 287 
-- History:
--	30/10/2019  P. Waldron		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_SAT_Address`(IN p_ProcessID INT64)
BEGIN
  /*
  ** Routine: Load_SAT_Address (Parcel from/to locations)
  ** Description: Loads addresses into SAT_Address
  */

  DECLARE v_DefaultValidFrom DATETIME DEFAULT '1900-01-01 00:00:00';
  DECLARE v_DefaultValidTo DATETIME DEFAULT '9999-12-31 23:59:59';
  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();

  DECLARE v_Component STRING DEFAULT 'dv_Load_SAT_Address';
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING;
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_Inserted INT64 DEFAULT 0;
  DECLARE v_Updated INT64 DEFAULT 0;

  BEGIN
    -- Only INSERT is present in the source logic, so using INSERT ... SELECT per CORE RULES.
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Address` (
      Address_HSK,
      AddressLine1,
      AddressLine2,
      Town,
      `State`,
      Postcode,
      CountryCode,
      CountryName,
      AddressKey,
      RecordSource,
      Loaded,
      ProcessId,
      ValidFrom,
      ValidTo,
      IsCurrent
    )
    SELECT DISTINCT
      Stg.Address_HSK,
      Stg.AddressLine1,
      Stg.AddressLine2,
      Stg.Town,
      Stg.`State`,
      Stg.Postcode,
      Stg.CountryCode,
      Stg.CountryName,
      Stg.AddressKey,
      Stg.RecordSource,
      v_Loaded AS Loaded,
      p_ProcessID AS ProcessID,
      v_DefaultValidFrom AS ValidFrom,
      v_DefaultValidTo AS ValidTo,
      1 AS IsCurrent
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Label_Address_Stg` AS Stg
    WHERE Stg.AddressSeq = 1
      AND NOT EXISTS (
        SELECT 1 
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Address` AS Dest
        WHERE Dest.Address_HSK = Stg.Address_HSK
      );

    SET v_Inserted = @@row_count;
    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result = 'Failed';
    SET v_ErrorMessage = @@error.message;
  END;

  -- Record load metrics in log
  SET v_Ended = CURRENT_DATETIME();
  CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
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