CREATE OR REPLACE TABLE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_InvoiceHead_partitioned`
(
  Invoice_HSK BYTES NOT NULL,
  FranchiseeCode_HSK BYTES NOT NULL,
  FranchiseeCode STRING NOT NULL,
  InvoiceNumber INT64 NOT NULL,
  EnteredDate DATETIME NOT NULL,
  EnterTime INT64 NOT NULL,
  CourierNumber STRING NOT NULL,
  CustomerId INT64 NOT NULL,
  CourierIdCommisionPaidTo STRING NOT NULL,
  InvoiceTotalAmount FLOAT64 NOT NULL,
  TaxAmount FLOAT64 NOT NULL,
  AmountPaid FLOAT64 NOT NULL,
  Balance FLOAT64 NOT NULL,
  PaidOnEntry INT64 NOT NULL,
  InsuranceAmount FLOAT64 NOT NULL,
  DissectionLines INT64 NOT NULL,
  CourierFloatIssuesGoTo STRING NOT NULL,
  FullyPaid INT64 NOT NULL,
  Committed INT64 NOT NULL,
  CountryCode INT64 NOT NULL,
  InvoiceCopyDate DATETIME NOT NULL,
  BatchId INT64 NOT NULL,
  SystemDate DATETIME NOT NULL,
  CreditedAmount FLOAT64 NOT NULL,
  CreditedTax FLOAT64 NOT NULL,
  PurchaseOrderNumber STRING,
  Comments STRING,
  ExcludedFromBaseRate INT64,
  Loaded DATETIME NOT NULL,
  ProcessId INT64 NOT NULL,
  RecordSource STRING NOT NULL
)
PARTITION BY DATETIME_TRUNC(EnteredDate, MONTH)
OPTIONS (
  require_partition_filter = FALSE
);