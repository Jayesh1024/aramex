CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.sp_load_Staging_FMS_InvoiceLines_Stg`(
  FromDate DATETIME
)
BEGIN
  INSERT INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_FMS_InvoiceLines_Stg`
  /*
    Invoices are read with a >= SystemDate rather than >
    meaning some invoices already in FastwayDW are re-read
    by this query. these duplicates are removed later
  */
  SELECT 
         RFId
        ,InvoiceNumber
        ,ProductId
        ,Qty
        ,Price
        ,Commission
        ,CAST(PayCommission AS INT64) AS PayCommission
        ,DontPayCommissionReason
        ,RecieptLabelsScanned
        ,ReceiptLabelssUnknown
        ,IssueTotalLabelsScanned
        ,IssuesLabelsOwedAtEntry
        ,IssueOwedOnThisInvoice
        ,QtyToIssue
        ,SaleType
        ,InvoiceDateInvLine
        ,InvoiceDateTime
        ,CAST(PriceDiscounted AS INT64) AS PriceDiscounted
        ,GSTAmount
        ,NMId
        ,BatchId
        ,SystemDate
        ,CreditedQty
        ,CreditedPrice
        ,CreditedTax
        ,LineType
        ,BatchingProgram
        ,BatchingArguments
    FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_krillin_silver.Fastway_dbo_FMS_InvoiceLines` stg
    WHERE EXISTS (
        select 1 from `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_krillin_silver.Fastway_dbo_FMS_InvoiceHead` h 
        where h.EnteredDate >= FromDate
          and h.InvoiceNumber = stg.InvoiceNumber 
          and h.RFCode = stg.RFId 
          and H.NMId in (1,6)
    )
  ;

END;