CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.sp_load_Staging_FWFastlabel_ClickAndCollect_Stg`(
  p_LastValue DATETIME
)
BEGIN
  IF p_LastValue IS NULL THEN
    RAISE USING MESSAGE = 'p_LastValue is required (populate from get_last_value in Airflow)';
  END IF;

  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_FWFastlabel_ClickAndCollect_Stg`
  SELECT CNC.Id
          ,CNC.Label
          ,CNC.ToContactName
          ,CNC.ToStreetAddress
          ,CNC.ToLocality
          ,CNC.ToStateOrProvince
          ,CNC.ToPostalCode
          ,CNC.ToCountry
          ,CNC.ToPhoneNumber
          ,CNC.ToEmail
          ,CNC.WeightDead
          ,CNC.WeightCubic
          ,CNC.Length
          ,CNC.Width
          ,CNC.Height
          ,CNC.FromRf
          ,CNC.FromStreetAddress
          ,CNC.FromLocality
          ,CNC.FromStateOrProvince
          ,CNC.FromPostalCode
          ,CNC.FromCountry
          ,CNC.FromPhoneNumber
          ,CNC.FromEmail
          ,CNC.CreatedOn
          ,CNC.CreatedBy
          ,CAST(CNC.Processed AS INT64) AS Processed
          ,CNC.ProcessedOn
          ,CAST(CNC.ingestion_time AS DATETIME) AS ingestion_time
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_FWFastlabel_ClickAndCollect` AS CNC
     WHERE CNC.ingestion_time IS NOT NULL
       AND CAST(CNC.ingestion_time AS DATETIME) > p_LastValue;

END;
