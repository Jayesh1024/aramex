CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.sp_load_Staging_FWFastlabel_ClickAndCollect_Stg`(
  synchronization_version INT64,
  IsReload BOOL
)
BEGIN
  -- NOTE: SQL Server CHANGETABLE (CDC) is not available in BigQuery.
  -- Converted to direct table scan. Implement CDC watermarks via Airflow.

  DECLARE minimumVersion INT64;

  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_FWFastlabel_ClickAndCollect_Stg`
  SELECT 
                              CNC.Id
                              ,CAST(NULL AS INT64) AS SYS_CHANGE_VERSION
                              ,CAST(NULL AS STRING) AS SYS_CHANGE_OPERATION
                              ,Label
                              ,ToContactName
                              ,ToStreetAddress
                              ,ToLocality
                              ,ToStateOrProvince
                              ,ToPostalCode
                              ,ToCountry
                              ,ToPhoneNumber
                              ,ToEmail
                              ,WeightDead
                              ,WeightCubic
                              ,Length
                              ,Width
                              ,Height
                              ,FromRf
                              ,FromStreetAddress
                              ,FromLocality
                              ,FromStateOrProvince
                              ,FromPostalCode
                              ,FromCountry
                              ,FromPhoneNumber
                              ,FromEmail
                              ,CreatedOn
                              ,CreatedBy
                              ,CAST(Processed AS INT64) AS Processed
                              ,ProcessedOn
                          FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_FWFastlabel_ClickAndCollect` AS CNC
                          WHERE IsReload = FALSE
  
                          UNION DISTINCT
                          SELECT
                              Id
                              ,minimumVersion AS SYS_CHANGE_VERSION
                              ,'I' AS SYS_CHANGE_OPERATION
                              ,Label
                              ,ToContactName
                              ,ToStreetAddress
                              ,ToLocality
                              ,ToStateOrProvince
                              ,ToPostalCode
                              ,ToCountry
                              ,ToPhoneNumber
                              ,ToEmail
                              ,WeightDead
                              ,WeightCubic
                              ,Length
                              ,Width
                              ,Height
                              ,FromRf
                              ,FromStreetAddress
                              ,FromLocality
                              ,FromStateOrProvince
                              ,FromPostalCode
                              ,FromCountry
                              ,FromPhoneNumber
                              ,FromEmail
                              ,CreatedOn
                              ,CreatedBy
                              ,CAST(Processed AS INT64) AS Processed
                              ,ProcessedOn
                          FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_FWFastlabel_ClickAndCollect` AS CNC
                          WHERE IsReload = TRUE
  ;

END;