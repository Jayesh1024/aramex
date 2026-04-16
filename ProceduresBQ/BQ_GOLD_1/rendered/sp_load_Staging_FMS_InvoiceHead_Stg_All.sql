CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.sp_load_Staging_FMS_InvoiceHead_Stg_All`(
)
BEGIN
  INSERT INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_FMS_InvoiceHead_Stg_All`
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
        ,PaidOnEntry
        ,InsuranceAmount
        ,DissectionLines
        ,CourierFloatIssuesGoTo
        ,FullyPaid
        ,Committed
        ,NMId
        ,InvoiceCopyDate
        ,BatchId
        ,SystemDate
        ,CreditedAmount
        ,CreditedTax
        ,PurchaseOrderNumber
        ,Comments
        ,ExcludedFromBaseRate
    FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_krillin_silver.Fastway_dbo_FMS_InvoiceHead` 
  WHERE NMId IN(1,6)
  ;

END;