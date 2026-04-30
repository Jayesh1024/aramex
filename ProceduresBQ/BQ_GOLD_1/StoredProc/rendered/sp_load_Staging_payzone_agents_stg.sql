CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.sp_load_Staging_payzone_agents_stg`(
  synchronization_version INT64,
  IsReload BOOL
)
BEGIN
  -- NOTE: SQL Server CHANGETABLE (CDC) is not available in BigQuery.
  -- Converted to direct table scan. Implement CDC watermarks via Airflow.

  DECLARE minimumVersion INT64;

  -- TODO: CHANGE_TRACKING_MIN_VALID_VERSION not available in BQIF (synchronization_version < minimumVersion  AND IsReload  = 0 )  RAISE USING MESSAGE = 'ERROR - Synchronization version invalid';

  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_payzone_agents_stg`
  SELECT Src.id
        ,Src.region_id
        ,Src.courier_no
        ,Src.store_identifier
        ,Src.store_name
        ,Src.store_address1
        ,Src.store_latitude
        ,Src.store_longitude
        ,Src.store_address2
        ,Src.store_town
        ,Src.store_county
        ,CAST(Src.store_active AS INT64) AS store_active
        ,CAST(Src.is_test AS INT64) AS is_test
        ,Src.Postcode
        ,Src.MyLocateCode
        ,CAST(Src.ApplicationFormReceived AS INT64) AS ApplicationFormReceived
        ,CAST(Src.SignedAgreementReceived AS INT64) AS SignedAgreementReceived
        ,CAST(Src.InsuranceCertificateSupplied AS INT64) AS InsuranceCertificateSupplied
        ,Src.TradingHours
        ,Src.PhoneNo
        ,CAST(Src.NotificationSent AS INT64) AS NotificationSent
        ,Src.CreatedBy
        ,Src.CreatedByCountry
        ,Src.UserId
        ,Src.ApplicationId
        ,CAST(Src.Hubbed AS INT64) AS Hubbed
        ,CAST(Src.AllowFwClickAndCollect AS INT64) AS AllowFwClickAndCollect
        ,Src.MaxWeightDead
        ,Src.DimensionCombinedMax
        ,Src.store_state
        ,CAST(NULL AS INT64) AS SYS_CHANGE_VERSION
        ,CAST(NULL AS STRING) AS SYS_CHANGE_OPERATION
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_payzone_agents` AS Src
    WHERE IsReload = FALSE

  UNION DISTINCT
  SELECT Src.id
        ,Src.region_id
        ,Src.courier_no
        ,Src.store_identifier
        ,Src.store_name
        ,Src.store_address1
        ,Src.store_latitude
        ,Src.store_longitude
        ,Src.store_address2
        ,Src.store_town
        ,Src.store_county
        ,CAST(Src.store_active AS INT64) AS store_active
        ,CAST(Src.is_test AS INT64) AS is_test
        ,Src.Postcode
        ,Src.MyLocateCode
        ,CAST(Src.ApplicationFormReceived AS INT64) AS ApplicationFormReceived
        ,CAST(Src.SignedAgreementReceived AS INT64) AS SignedAgreementReceived
        ,CAST(Src.InsuranceCertificateSupplied AS INT64) AS InsuranceCertificateSupplied
        ,Src.TradingHours
        ,Src.PhoneNo
        ,CAST(Src.NotificationSent AS INT64) AS NotificationSent
        ,Src.CreatedBy
        ,Src.CreatedByCountry
        ,Src.UserId
        ,Src.ApplicationId
        ,CAST(Src.Hubbed AS INT64) AS Hubbed
        ,CAST(Src.AllowFwClickAndCollect AS INT64) AS AllowFwClickAndCollect
        ,Src.MaxWeightDead
        ,Src.DimensionCombinedMax
        ,Src.store_state
        ,minimumVersion AS SYS_CHANGE_VERSION
        ,'I' AS SYS_CHANGE_OPERATION
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_payzone_agents` AS Src
    WHERE IsReload = TRUE
  ;

END;