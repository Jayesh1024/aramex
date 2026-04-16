-- ==========================================================================================
-- Routine:     Load_Missing_SAT_Label_Allocation_IFS
-- Description: Load missing HDManifest records into SAT_Label_Allocation_IFS from Staging_HDManifests_stg
-- History:
--  25/07/2019  B. Woods      Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_Missing_SAT_Label_Allocation_IFS`(IN p_ProcessID INT64)
BEGIN
  /*
  ** Routine: Load_Missing_SAT_Label_Allocation_IFS
  ** Description: Load missing HDManifest records into SAT_Label_Allocation_IFS from Staging_HDManifests_stg
  */

  DECLARE v_DefaultValidFrom DATETIME DEFAULT '1900-01-01 00:00:00';
  DECLARE v_DefaultValidTo DATETIME DEFAULT '9999-12-31 23:59:59';
  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();

  DECLARE v_Component STRING DEFAULT 'dv_Load_Missing_SAT_Label_Allocation_IFS';
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING;
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_Inserted INT64 DEFAULT 0;
  DECLARE v_Updated INT64 DEFAULT 0;
  DECLARE v_RecordSource STRING DEFAULT 'IFS';

  BEGIN
    -- Only INSERT is present in the source logic, so using INSERT ... SELECT per CORE RULES.
    INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_IFS` (
      LabelNo_HSK,
      LabelNo,
      CountryCode,
      Country,
      ManifestId,
      ConDate,
      ClientId,
      CustomerID,
      DeliveryCountryCode,
      CollectionCountryCode,
      DeliveryRF,
      CollectionRF,
      Quantity,
      Weight,
      Width,
      Length,
      Height,
      DateInserted,
      RecordId,
      Loaded,
      ProcessId,
      RecordSource,
      RecordSourceId,
      ValidFrom,
      ValidTo,
      IsCurrent,
      UniqueParcelIdentifier
    )
    SELECT
      (SHA256(CAST(Stg.LabelNo AS STRING))) AS Label_HSK,
      Stg.LabelNo,
      Stg.CountryCode,
      cty.CountryName,
      Stg.ManifestId,
      Stg.ConDate,
      Stg.ClientId,
      Stg.CustomerID,
      Stg.DeliveryCountryCode,
      Stg.CollectionCountryCode,
      Stg.DeliveryRF,
      Stg.CollectionRF,
      Stg.Quantity,
      Stg.Weight,
      Stg.Width,
      Stg.Length,
      Stg.Height,
      Stg.DateInserted,
      Stg.RecordId,
      v_Loaded AS Loaded,
      p_ProcessID AS ProcessId,
      v_RecordSource AS RecordSource,
      Stg.RecordId AS RecordSourceId,
      v_Loaded AS ValidFrom,
      v_DefaultValidTo AS ValidTo,
      1 AS IsCurrent,
      Stg.UniqueParcelIdentifier
    FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_HDManifests_Stg` AS Stg
    LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_IFS` AS Tgt ON Stg.RecordId = Tgt.RecordID
    LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` AS cty ON cty.CountryCode = Stg.CountryCode
    WHERE Tgt.RecordId IS NULL;

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