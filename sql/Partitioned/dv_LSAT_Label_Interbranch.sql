DROP TABLE IF EXISTS `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Interbranch`;

CREATE OR REPLACE TABLE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Interbranch`
(
  Label_InterBranch_HSK BYTES NOT NULL,
  LabelNo STRING NOT NULL,
  CountryCode STRING NOT NULL,
  InvoiceNumber INT64 NOT NULL,
  InvoiceDate DATETIME,
  InvoiceFromRF STRING NOT NULL,
  InvoiceToRF STRING NOT NULL,
  ProductID INT64 NOT NULL,
  Category STRING NOT NULL,
  DeliveryDate DATE NOT NULL,
  DeliveryTime STRING,
  Price FLOAT64 NOT NULL,
  Loaded DATETIME NOT NULL,
  ProcessId INT64 NOT NULL,
  RecordSource STRING NOT NULL,
  BatchId INT64
)
PARTITION BY DATETIME_TRUNC(InvoiceDate, MONTH)
OPTIONS (
  require_partition_filter = FALSE
);
