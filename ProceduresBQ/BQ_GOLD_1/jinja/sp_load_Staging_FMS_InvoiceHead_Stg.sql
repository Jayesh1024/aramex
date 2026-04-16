CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_FMS_InvoiceHead_Stg`(
  FromDate DATETIME
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_FMS_InvoiceHead_Stg`
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
    FROM `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_FMS_InvoiceHead`
  WHERE EnteredDate >= FromDate
    AND NMId IN(1,6)
  ;

END;