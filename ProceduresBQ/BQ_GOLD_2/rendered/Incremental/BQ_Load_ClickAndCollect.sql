-- ==========================================================================================
-- Routine:     dbo_Load_ClickAndCollect
-- Description: MERGE staging → dbo_FWFastlabel_ClickAndCollect (BigQuery-native scripting).
-- ==========================================================================================

CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.dbo_Load_ClickAndCollect`(
  IN p_ProcessID INT64
)
BEGIN
  DECLARE v_Component STRING DEFAULT 'prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_Load_ClickAndCollect';
  DECLARE v_Step STRING DEFAULT 'MERGE';
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING DEFAULT 'Success';
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_AffectedRows INT64 DEFAULT 0;

  BEGIN
    MERGE INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_FWFastlabel_ClickAndCollect` AS Tgt
    USING (
      SELECT * EXCEPT (dedupe_rn)
      FROM (
        SELECT
          s.*,
          ROW_NUMBER() OVER (PARTITION BY s.Id ORDER BY s.Id) AS dedupe_rn
        FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_FWFastlabel_ClickAndCollect_Stg` AS s
      )
      WHERE dedupe_rn = 1
    ) AS Src
    ON Tgt.Id = Src.Id
    WHEN MATCHED THEN
      UPDATE SET
        LabelNo = Src.Label,
        ToContactName = Src.ToContactName,
        ToStreetAddress = Src.ToStreetAddress,
        ToLocality = Src.ToLocality,
        ToStateOrProvince = Src.ToStateOrProvince,
        ToPostalCode = Src.ToPostalCode,
        ToCountry = Src.ToCountry,
        ToPhoneNumber = Src.ToPhoneNumber,
        ToEmail = Src.ToEmail,
        WeightDead = Src.WeightDead,
        WeightCubic = Src.WeightCubic,
        Length = Src.Length,
        Width = Src.Width,
        Height = Src.Height,
        FromRf = Src.FromRf,
        FromStreetAddress = Src.FromStreetAddress,
        FromLocality = Src.FromLocality,
        FromStateOrProvince = Src.FromStateOrProvince,
        FromPostalCode = Src.FromPostalCode,
        FromCountry = Src.FromCountry,
        FromPhoneNumber = Src.FromPhoneNumber,
        FromEmail = Src.FromEmail,
        CreatedOn = Src.CreatedOn,
        CreatedBy = Src.CreatedBy,
        Processed = Src.Processed,
        ProcessedOn = Src.ProcessedOn
    WHEN NOT MATCHED THEN
      INSERT (
        Id,
        LabelNo,
        ToContactName,
        ToStreetAddress,
        ToLocality,
        ToStateOrProvince,
        ToPostalCode,
        ToCountry,
        ToPhoneNumber,
        ToEmail,
        WeightDead,
        WeightCubic,
        Length,
        Width,
        Height,
        FromRf,
        FromStreetAddress,
        FromLocality,
        FromStateOrProvince,
        FromPostalCode,
        FromCountry,
        FromPhoneNumber,
        FromEmail,
        CreatedOn,
        CreatedBy,
        Processed,
        ProcessedOn
      )
      VALUES (
        Src.Id,
        Src.Label,
        Src.ToContactName,
        Src.ToStreetAddress,
        Src.ToLocality,
        Src.ToStateOrProvince,
        Src.ToPostalCode,
        Src.ToCountry,
        Src.ToPhoneNumber,
        Src.ToEmail,
        Src.WeightDead,
        Src.WeightCubic,
        Src.Length,
        Src.Width,
        Src.Height,
        Src.FromRf,
        Src.FromStreetAddress,
        Src.FromLocality,
        Src.FromStateOrProvince,
        Src.FromPostalCode,
        Src.FromCountry,
        Src.FromPhoneNumber,
        Src.FromEmail,
        Src.CreatedOn,
        Src.CreatedBy,
        Src.Processed,
        Src.ProcessedOn
      );

    SET v_AffectedRows = @@row_count;

  EXCEPTION WHEN ERROR THEN
    SET v_Result = CONCAT('Failed (', v_Step, ')');
    SET v_ErrorMessage = @@error.message;
  END;

  SET v_Ended = CURRENT_DATETIME();

  CALL `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.Staging_SaveLog`(
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
