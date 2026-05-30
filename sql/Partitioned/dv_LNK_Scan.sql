CREATE OR REPLACE TABLE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Scan`
(
  Scan_HSK BYTES NOT NULL,
  FranchiseeCode_HSK BYTES NOT NULL,
  Courier_HSK BYTES NOT NULL,
  LabelNo_HSK BYTES,
  Location_HSK BYTES NOT NULL,
  ScanStatus_HSK BYTES NOT NULL,
  FranchiseeCode STRING NOT NULL,
  CourierNumber STRING NOT NULL,
  LabelNo STRING NOT NULL,
  Latitude FLOAT64 NOT NULL,
  Longitude FLOAT64 NOT NULL,
  ScanStatus STRING NOT NULL,
  CountryName STRING NOT NULL,
  ScanDate DATETIME NOT NULL,
  ScanType STRING NOT NULL,
  Loaded DATETIME NOT NULL,
  ProcessId INT64 NOT NULL,
  RecordSource STRING NOT NULL,
  RecordSourceId INT64,
  TrackAndTraceID INT64,
  iLocate STRING,
  UploadDate DATE,
  ProductId INT64
)
PARTITION BY DATETIME_TRUNC(ScanDate, DAY)
OPTIONS (
  require_partition_filter = FALSE
);