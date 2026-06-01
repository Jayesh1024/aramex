CREATE OR REPLACE TABLE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Interbranch`
(
  Label_InterBranch_HSK BYTES NOT NULL,
  LabelNo STRING NOT NULL,
  CountryCode STRING,
  InvoiceNumber STRING,
  InvoiceDate DATETIME,
  InvoiceFromRF STRING,
  InvoiceToRF STRING,
  ProductID INT64,
  Category STRING,
  DeliveryDate DATETIME,
  DeliveryTime STRING,
  Price FLOAT64,
  Loaded DATETIME NOT NULL,
  ProcessId INT64 NOT NULL,
  RecordSource STRING NOT NULL,
  BatchId INT64
)
PARTITION BY DATETIME_TRUNC(InvoiceDate, MONTH)
OPTIONS (
  require_partition_filter = FALSE
);
