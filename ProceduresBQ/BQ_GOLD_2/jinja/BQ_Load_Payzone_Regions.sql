-- dbo_Load_Payzone_Regions — MERGE staging → dbo_Payzone_Regions (BigQuery scripting).

CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dbo_Load_Payzone_Regions`(
  IN p_ProcessID INT64
)
BEGIN
  DECLARE v_Component STRING DEFAULT '{{ project_id }}.{{ target_dataset_id }}.dbo_Load_Payzone_Regions';
  DECLARE v_Step STRING DEFAULT 'MERGE';
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING DEFAULT 'Success';
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_AffectedRows INT64 DEFAULT 0;

  BEGIN
    MERGE INTO `{{ project_id }}.{{ target_dataset_id }}.dbo_Payzone_Regions` AS Tgt
    USING (
      SELECT * EXCEPT (dedupe_rn)
      FROM (
        SELECT
          s.*,
          ROW_NUMBER() OVER (PARTITION BY s.id ORDER BY s.id) AS dedupe_rn
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_payzone_regions_stg` AS s
      )
      WHERE dedupe_rn = 1
    ) AS Src
    ON Tgt.id = Src.id
    WHEN MATCHED THEN
      UPDATE SET
        franchisee_code = Src.franchisee_code,
        region_company_name = Src.region_company_name,
        region_company_phone = Src.region_company_phone,
        region_address = Src.region_address,
        region_company_email = Src.region_company_email,
        secondary_franchisee_codes = Src.secondary_franchisee_codes,
        CountryId = Src.CountryId,
        SYS_CHANGE_VERSION = Src.SYS_CHANGE_VERSION
    WHEN NOT MATCHED THEN
      INSERT (
        id,
        franchisee_code,
        region_company_name,
        region_company_phone,
        region_address,
        region_company_email,
        secondary_franchisee_codes,
        CountryId,
        SYS_CHANGE_VERSION
      )
      VALUES (
        Src.id,
        Src.franchisee_code,
        Src.region_company_name,
        Src.region_company_phone,
        Src.region_address,
        Src.region_company_email,
        Src.secondary_franchisee_codes,
        Src.CountryId,
        Src.SYS_CHANGE_VERSION
      );

    SET v_AffectedRows = @@row_count;

  EXCEPTION WHEN ERROR THEN
    SET v_Result = CONCAT('Failed (', v_Step, ')');
    SET v_ErrorMessage = @@error.message;
  END;

  SET v_Ended = CURRENT_DATETIME();

  -- Same SaveLog shape as dbo_Load_Payzone_Agents: total MERGE rowcount, unknown insert/update split.
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
