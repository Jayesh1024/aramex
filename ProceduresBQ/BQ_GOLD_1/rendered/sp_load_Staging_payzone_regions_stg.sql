CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.sp_load_Staging_payzone_regions_stg`(
  synchronization_version INT64,
  IsReload BOOL
)
BEGIN
  -- NOTE: SQL Server CHANGETABLE (CDC) is not available in BigQuery.
  -- Converted to direct table scan. Implement CDC watermarks via Airflow.

  DECLARE minimumVersion INT64;

  -- TODO: CHANGE_TRACKING_MIN_VALID_VERSION not available in BQIF (synchronization_version < minimumVersion  AND IsReload  = 0 ) RAISE USING MESSAGE = 'ERROR - Synchronization version invalid';

  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_payzone_regions_stg`
  SELECT Src.id
        ,Src.franchisee_code
        ,Src.region_company_name
        ,Src.region_company_phone
        ,Src.region_address
        ,Src.region_company_email
        ,Src.secondary_franchisee_codes
        ,Src.CountryId
        ,CAST(NULL AS INT64) AS SYS_CHANGE_VERSION
        ,CAST(NULL AS STRING) AS SYS_CHANGE_OPERATION
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_payzone_regions` AS Src
    WHERE IsReload = FALSE

    UNION DISTINCT
    SELECT Src.id
        ,Src.franchisee_code
        ,Src.region_company_name
        ,Src.region_company_phone
        ,Src.region_address
        ,Src.region_company_email
        ,Src.secondary_franchisee_codes
        ,Src.CountryId
        ,minimumVersion AS SYS_CHANGE_VERSION
        ,'I' AS SYS_CHANGE_OPERATION
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_payzone_regions` AS Src
    WHERE IsReload = TRUE
  ;

END;