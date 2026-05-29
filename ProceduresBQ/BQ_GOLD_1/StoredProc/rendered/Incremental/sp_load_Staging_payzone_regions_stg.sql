CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.sp_load_Staging_payzone_regions_Stg`(
  p_LastValue DATETIME
)
BEGIN
  IF p_LastValue IS NULL THEN
    RAISE USING MESSAGE = 'p_LastValue is required (populate from get_last_value in Airflow)';
  END IF;

  INSERT INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_payzone_regions_Stg`
  SELECT Src.id
          ,Src.franchisee_code
          ,Src.region_company_name
          ,Src.region_company_phone
          ,Src.region_address
          ,Src.region_company_email
          ,Src.secondary_franchisee_codes
          ,Src.CountryId
          ,CAST(Src.ingestion_time AS DATETIME) AS ingestion_time
      FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_payzone_regions` AS Src
     WHERE Src.ingestion_time IS NOT NULL
       AND CAST(Src.ingestion_time AS DATETIME) > p_LastValue;

END;
