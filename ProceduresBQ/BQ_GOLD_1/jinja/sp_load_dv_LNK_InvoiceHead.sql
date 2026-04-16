CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_dv_LNK_InvoiceHead`(
)
BEGIN
  DECLARE LoadDate DATETIME;
  SET LoadDate = CAST('2024-03-13' AS DATETIME);

  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_LNK_InvoiceHead`
  SELECT
    TO_HEX(MD5(CONCAT(CAST(InvoiceNumber AS STRING), '^', RFCode))) AS Invoice_HSK,
    TO_HEX(MD5(RFCode)) AS FranchiseeCode_HSK,
    RFCode,
    InvoiceNumber,
    EnteredDate,
    EnterTime,
    CourierInvoiceBelongsTo,
    CustomerId,
    CourierIdCommisionPaidTo,
    InvoiceTotalAmount,
    TaxAmount,
    AmountPaid,
    Balance,
    PaidOnEntry,
    InsuranceAmount,
    DissectionLines,
    CourierFloatIssuesGoTo,
    FullyPaid,
    Committed,
    NMId,
    InvoiceCopyDate,
    BatchId,
    SystemDate,
    CreditedAmount,
    CreditedTax,
    PurchaseOrderNumber,
    Comments,
    ExcludedFromBaseRate,
    LoadDate AS Loaded,
    -1 AS ProcessID,
    'INITIAL LOAD' AS RecordSource
  FROM `{{ project_id }}.{{ source_dataset_id }}.Staging_FMS_InvoiceHead_Stg_All`
  WHERE SystemDate >= '2019-01-01'
  ;

END;
