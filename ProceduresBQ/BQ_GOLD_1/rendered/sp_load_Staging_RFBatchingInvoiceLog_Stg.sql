CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.sp_load_Staging_RFBatchingInvoiceLog_Stg`(
)
BEGIN
  INSERT INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_RFBatchingInvoiceLog_Stg`
  SELECT CAST(CountryCode AS INT64) AS CountryCode
        ,CAST(BatchID AS INT64) AS BatchID
        ,CAST(InvoiceNo AS INT64) AS InvoiceNo
        ,FromRF
        ,ToRF
        ,CAST(Paid AS INT64) AS Paid
        ,RemittedAmount
        ,InvoiceDate
    FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_krillin_silver.Fastway_dbo_FMS_RFBatchingInvoiceLog`
  WHERE InvoiceDate >= '2019-01-01'
  ;

END;