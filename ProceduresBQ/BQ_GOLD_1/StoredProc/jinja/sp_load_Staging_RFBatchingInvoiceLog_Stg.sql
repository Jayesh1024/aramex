CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_RFBatchingInvoiceLog_Stg`(
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_RFBatchingInvoiceLog_Stg`
  SELECT CAST(CountryCode AS INT64) AS CountryCode
        ,CAST(BatchID AS INT64) AS BatchID
        ,CAST(InvoiceNo AS INT64) AS InvoiceNo
        ,FromRF
        ,ToRF
        ,CAST(Paid AS INT64) AS Paid
        ,RemittedAmount
        ,InvoiceDate
    FROM `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_FMS_RFBatchingInvoiceLog`
  WHERE InvoiceDate >= '2019-01-01'
  ;

END;