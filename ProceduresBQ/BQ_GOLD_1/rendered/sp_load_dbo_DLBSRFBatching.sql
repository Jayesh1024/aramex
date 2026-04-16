CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.sp_load_dbo_DLBSRFBatching`(
)
BEGIN
  INSERT INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_DLBSRFBatching`
  SELECT CAST(BatchId AS INT64) AS BatchId
        ,Date
        ,Time
        ,FromDate
        ,ToDate
        ,CAST(NumberOfInvoices AS INT64) AS NumberOfInvoices
        ,CAST(CountryCode AS INT64) AS CountryCode
        ,Processing
        ,Info
        ,CAST(Released AS STRING) AS Released
        ,CAST(IsOpen AS STRING) AS IsOpen
        ,CAST(LastExceptionNo AS INT64) AS LastExceptionNo
        ,CAST(PricedAndPrinted AS STRING) AS PricedAndPrinted
    FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_krillin_silver.Fastway_dbo_invbtch`
    WHERE CountryCode in (1,6)
  ;

END;