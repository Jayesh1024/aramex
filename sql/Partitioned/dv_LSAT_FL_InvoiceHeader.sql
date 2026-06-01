CREATE OR REPLACE TABLE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_FL_InvoiceHeader`
(
  InvoiceHeaderId INT64 NOT NULL,
  BatchId INT64,
  RF STRING,
  ParentRF STRING,
  CountryId INT64,
  CustomerId INT64,
  ParentCustomerId INT64,
  InvoiceNo STRING,
  InvoiceDate DATETIME,
  Price FLOAT64,
  Tax FLOAT64,
  Total FLOAT64,
  GroupPrice FLOAT64,
  GroupTax FLOAT64,
  GroupTotal FLOAT64,
  Released INT64,
  RFLegalEntity STRING,
  ParentRFLegalEntity STRING,
  CFLegalEntity STRING,
  Level INT64,
  BankProcess INT64,
  ParentInvoiceHeaderId INT64,
  CFOverride INT64,
  CFOverrideBasePriceCommPercent FLOAT64,
  CFOverrideExcessPriceCommPercent FLOAT64,
  SelectedUI INT64,
  EnterpriseFastlabelType INT64,
  DueDate DATETIME,
  CloseDate DATETIME,
  TotalPaid FLOAT64,
  CourierNumber STRING,
  GroupTaxExempt INT64,
  Loaded DATETIME NOT NULL,
  ProcessId INT64 NOT NULL,
  RecordSource STRING NOT NULL
)
PARTITION BY DATETIME_TRUNC(InvoiceDate, MONTH)
OPTIONS (
  require_partition_filter = FALSE
);
