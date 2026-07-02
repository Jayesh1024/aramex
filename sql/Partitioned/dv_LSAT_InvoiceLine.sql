DROP TABLE IF EXISTS `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_InvoiceLine`;

CREATE OR REPLACE TABLE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_InvoiceLine`
(
  InvoiceLine_HSK BYTES NOT NULL,
  Invoice_HSK BYTES,
  FranchiseeCode_HSK BYTES,
  Courier_HSK BYTES,
  Customer_HSK BYTES,
  Product_HSK BYTES,
  InvoiceNumber INT64 NOT NULL,
  FranchiseeCode STRING NOT NULL,
  CourierNumber STRING NOT NULL,
  CustomerKey STRING NOT NULL,
  ProductCode STRING NOT NULL,
  Country STRING NOT NULL,
  EnteredDate DATETIME,
  SystemDate DATETIME,
  InvoiceDateInvLine DATETIME,
  Qty INT64 NOT NULL,
  Price FLOAT64 NOT NULL,
  Commission FLOAT64 NOT NULL,
  PayCommission INT64 NOT NULL,
  SaleType STRING NOT NULL,
  PriceDiscounted INT64 NOT NULL,
  GSTAmount FLOAT64 NOT NULL,
  LineType STRING NOT NULL,
  Loaded DATETIME NOT NULL,
  ProcessId INT64 NOT NULL,
  RecordSource STRING NOT NULL,
  RecordSourceId INT64
)
PARTITION BY DATETIME_TRUNC(InvoiceDateInvLine, MONTH)
OPTIONS (
  require_partition_filter = FALSE
);