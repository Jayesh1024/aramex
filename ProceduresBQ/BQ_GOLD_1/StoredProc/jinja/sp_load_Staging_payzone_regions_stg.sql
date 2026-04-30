CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_payzone_regions_stg`(
  synchronization_version INT64,
  IsReload BOOL
)
BEGIN
  -- NOTE: SQL Server CHANGETABLE (CDC) is not available in BigQuery.
  -- Converted to direct table scan. Implement CDC watermarks via Airflow.

  DECLARE minimumVersion INT64;

  -- TODO: CHANGE_TRACKING_MIN_VALID_VERSION not available in BQIF (synchronization_version < minimumVersion  AND IsReload  = 0 ) RAISE USING MESSAGE = 'ERROR - Synchronization version invalid';

  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_payzone_regions_stg`
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
    FROM `{{ project_id }}.{{ source_dataset_id }}.OnlineEnquiries_NEW_dbo_payzone_regions` AS Src
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
    FROM `{{ project_id }}.{{ source_dataset_id }}.OnlineEnquiries_NEW_dbo_payzone_regions` AS Src
    WHERE IsReload = TRUE
  ;

END;
