-- Materialized view backing RFBatchingInvoiceLog DAG final step (SELECT * FROM dv_LNK_RFBatchingInvoiceLog).
-- CTE mirrors the SELECT body of sp_load_Staging_RFBatchingInvoiceLog_Stg (MV definitions cannot CALL procedures).
CREATE MATERIALIZED VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_RFBatchingInvoiceLog`
OPTIONS (
  allow_non_incremental_definition = true,
  max_staleness = INTERVAL "30" MINUTE
) AS
  SELECT
    CAST(CountryCode AS INT64) AS CountryCode,
    CAST(BatchID AS INT64) AS BatchID,
    CAST(InvoiceNo AS INT64) AS InvoiceNo,
    FromRF,
    ToRF,
    CAST(Paid AS INT64) AS Paid,
    RemittedAmount,
    InvoiceDate
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_FMS_RFBatchingInvoiceLog`
  WHERE InvoiceDate >= '2019-01-01'
