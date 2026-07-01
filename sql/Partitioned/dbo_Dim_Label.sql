DROP TABLE IF EXISTS `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label`;

CREATE OR REPLACE TABLE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label`
(
  LabelNo STRING NOT NULL,
  CountryCode INT64,
  Country STRING,
  PickupTown STRING,
  PickupPostcode STRING,
  DeliveryTown STRING,
  DeliveryPostcode STRING,
  PickupRF STRING,
  PickupCF STRING,
  DeliveryRF STRING,
  DeliveryCF STRING,
  Electronic_CustomerType STRING,
  Electronic_CustomerID STRING,
  Electronic_Reference STRING,
  FastLabel_ConsignmentID INT64,
  FastLabel_DestinationRF STRING,
  Distribution_Date DATETIME,
  Distribution_FranchiseeCode STRING,
  FKSource STRING,
  OESCustomerID INT64,
  FMSCustomerID INT64,
  FMSInvoiceID INT64,
  FMSProductID INT64,
  FMSRfID STRING,
  LabelColour STRING,
  Reference STRING,
  NumberOfParcels INT64,
  Price FLOAT64,
  CreateDate DATETIME,
  ParcelLength FLOAT64,
  ParcelWidth FLOAT64,
  ParcelHeight FLOAT64,
  ParcelWeight FLOAT64,
  ParcelCubicWeight FLOAT64,
  Created DATETIME NOT NULL,
  Updated DATETIME NOT NULL,
  ProcessId INT64 NOT NULL,
  DLSInvoiceID INT64,
  LabelPrefix STRING
)
PARTITION BY DATETIME_TRUNC(CreateDate, MONTH)
OPTIONS (
  require_partition_filter = FALSE
);