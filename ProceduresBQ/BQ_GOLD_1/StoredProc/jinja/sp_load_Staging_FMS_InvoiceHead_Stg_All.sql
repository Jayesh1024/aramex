CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_FMS_InvoiceHead_Stg_All`(
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_FMS_InvoiceHead_Stg_All`
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
    FROM `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_FMS_InvoiceHead` 
  WHERE NMId IN(1,6)
  ;

END;