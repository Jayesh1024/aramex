CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_payzone_regions_stg`(
  p_LastValue DATETIME
)
BEGIN
  IF p_LastValue IS NULL THEN
    RAISE USING MESSAGE = 'p_LastValue is required (populate from get_last_value in Airflow)';
  END IF;

  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_payzone_regions_stg`
  SELECT Src.id
          ,Src.franchisee_code
          ,Src.region_company_name
          ,Src.region_company_phone
          ,Src.region_address
          ,Src.region_company_email
          ,Src.secondary_franchisee_codes
          ,Src.CountryId
          ,CAST(Src.ingestion_time AS DATETIME) AS ingestion_time
      FROM `{{ project_id }}.{{ source_dataset_id }}.OnlineEnquiries_NEW_dbo_payzone_regions` AS Src
     WHERE Src.ingestion_time IS NOT NULL
       AND CAST(Src.ingestion_time AS DATETIME) > p_LastValue;

END;
