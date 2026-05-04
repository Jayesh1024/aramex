-- dbo_Load_Payzone_Agents — MERGE staging → dbo_Payzone_Agents (BigQuery scripting).

CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dbo_Load_Payzone_Agents`(
  IN p_ProcessID INT64
)
BEGIN
  DECLARE v_Component STRING DEFAULT '{{ project_id }}.{{ target_dataset_id }}.dbo_Load_Payzone_Agents';
  DECLARE v_Step STRING DEFAULT 'MERGE';
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING DEFAULT 'Success';
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_AffectedRows INT64 DEFAULT 0;

  BEGIN
    -- Deduplicate USING rows so MERGE never sees duplicate join keys (BigQuery MERGE requirement).
    MERGE INTO `{{ project_id }}.{{ target_dataset_id }}.dbo_Payzone_Agents` AS Tgt
    USING (
      SELECT * EXCEPT (dedupe_rn)
      FROM (
        SELECT
          s.*,
          ROW_NUMBER() OVER (PARTITION BY s.Id ORDER BY s.Id) AS dedupe_rn
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_payzone_agents_stg` AS s
      )
      WHERE dedupe_rn = 1
    ) AS Src
    ON Tgt.Id = Src.Id
    WHEN MATCHED THEN
      UPDATE SET
        region_id = Src.region_id,
        courier_no = Src.courier_no,
        store_identifier = Src.store_identifier,
        store_name = Src.store_name,
        store_address1 = Src.store_address1,
        store_latitude = Src.store_latitude,
        store_longitude = Src.store_longitude,
        store_address2 = Src.store_address2,
        store_town = Src.store_town,
        store_county = Src.store_county,
        store_active = Src.store_active,
        is_test = Src.is_test,
        Postcode = Src.Postcode,
        MyLocateCode = Src.MyLocateCode,
        ApplicationFormReceived = Src.ApplicationFormReceived,
        SignedAgreementReceived = Src.SignedAgreementReceived,
        InsuranceCertificateSupplied = Src.InsuranceCertificateSupplied,
        TradingHours = Src.TradingHours,
        PhoneNo = Src.PhoneNo,
        NotificationSent = Src.NotificationSent,
        CreatedBy = Src.CreatedBy,
        CreatedByCountry = Src.CreatedByCountry,
        UserId = Src.UserId,
        ApplicationId = Src.ApplicationId,
        Hubbed = Src.Hubbed,
        AllowFwClickAndCollect = Src.AllowFwClickAndCollect,
        MaxWeightDead = Src.MaxWeightDead,
        DimensionCombinedMax = Src.DimensionCombinedMax,
        store_state = Src.store_state,
        SYS_CHANGE_VERSION = Src.SYS_CHANGE_VERSION
    WHEN NOT MATCHED THEN
      INSERT (
        Id,
        region_id,
        courier_no,
        store_identifier,
        store_name,
        store_address1,
        store_latitude,
        store_longitude,
        store_address2,
        store_town,
        store_county,
        store_active,
        is_test,
        Postcode,
        MyLocateCode,
        ApplicationFormReceived,
        SignedAgreementReceived,
        InsuranceCertificateSupplied,
        TradingHours,
        PhoneNo,
        NotificationSent,
        CreatedBy,
        CreatedByCountry,
        UserId,
        ApplicationId,
        Hubbed,
        AllowFwClickAndCollect,
        MaxWeightDead,
        DimensionCombinedMax,
        store_state,
        SYS_CHANGE_VERSION
      )
      VALUES (
        Src.Id,
        Src.region_id,
        Src.courier_no,
        Src.store_identifier,
        Src.store_name,
        Src.store_address1,
        Src.store_latitude,
        Src.store_longitude,
        Src.store_address2,
        Src.store_town,
        Src.store_county,
        Src.store_active,
        Src.is_test,
        Src.Postcode,
        Src.MyLocateCode,
        Src.ApplicationFormReceived,
        Src.SignedAgreementReceived,
        Src.InsuranceCertificateSupplied,
        Src.TradingHours,
        Src.PhoneNo,
        Src.NotificationSent,
        Src.CreatedBy,
        Src.CreatedByCountry,
        Src.UserId,
        Src.ApplicationId,
        Src.Hubbed,
        Src.AllowFwClickAndCollect,
        Src.MaxWeightDead,
        Src.DimensionCombinedMax,
        Src.store_state,
        Src.SYS_CHANGE_VERSION
      );

    SET v_AffectedRows = @@row_count;

  EXCEPTION WHEN ERROR THEN
    SET v_Result = CONCAT('Failed (', v_Step, ')');
    SET v_ErrorMessage = @@error.message;
  END;

  SET v_Ended = CURRENT_DATETIME();

  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
    v_Component,
    p_ProcessID,
    v_Started,
    v_Ended,
    v_Result,
    v_ErrorMessage,
    v_AffectedRows,
    -1,
    -1
  );
END;
