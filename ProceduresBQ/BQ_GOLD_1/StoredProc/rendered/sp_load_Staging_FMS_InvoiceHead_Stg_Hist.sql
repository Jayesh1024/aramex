CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.sp_load_Staging_FMS_InvoiceHead_Stg_Hist`(
)
BEGIN
  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_FMS_InvoiceHead_Stg`
  /*
    Invoices are read with a >= EnteredDate rather than >
    meaning some invoices already in FastwayDW are re-read
    by this query. these duplicates are removed later
  */
  SELECT 
         RFCode
        ,InvoiceNumber
        ,EnteredDate
        ,EnterTime
        ,CourierInvoiceBelongsTo
        ,CustomerId
        ,CourierIdCommisionPaidTo
        ,InvoiceTotalAmount
        ,TaxAmount
        ,AmountPaid
        ,Balance
        ,CAST(PaidOnEntry AS INT64) AS PaidOnEntry
        ,InsuranceAmount
        ,DissectionLines
        ,CourierFloatIssuesGoTo
        ,CAST(FullyPaid AS INT64) AS FullyPaid
        ,CAST(Committed AS INT64) AS Committed
        ,NMId
        ,InvoiceCopyDate
        ,BatchId
        ,SystemDate
        ,CreditedAmount
        ,CreditedTax
        ,PurchaseOrderNumber
        ,Comments
        ,CAST(ExcludedFromBaseRate AS INT64) AS ExcludedFromBaseRate
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_FMS_InvoiceHead`
  WHERE NMId IN(1,6)
  ;

END