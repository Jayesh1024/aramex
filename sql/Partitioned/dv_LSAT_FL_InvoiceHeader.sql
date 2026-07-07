DROP TABLE IF EXISTS `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_FL_InvoiceHeader`;

CREATE OR REPLACE TABLE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_FL_InvoiceHeader`
(
  `InvoiceHeaderId` INT64 NOT NULL,
  `BatchId` INT64 NOT NULL,
  `RF` STRING NOT NULL,
  `ParentRF` STRING,
  `CountryId` INT64 NOT NULL,
  `CustomerId` INT64 NOT NULL,
  `ParentCustomerId` INT64 NOT NULL,
  `InvoiceNo` INT64 NOT NULL,
  `InvoiceDate` DATETIME NOT NULL,
  `Price` FLOAT64 NOT NULL,
  `Tax` FLOAT64 NOT NULL,
  `Total` FLOAT64 NOT NULL,
  `GroupPrice` FLOAT64,
  `GroupTax` FLOAT64,
  `GroupTotal` FLOAT64,
  `Released` INT64 NOT NULL,
  `RFLegalEntity` INT64 NOT NULL,
  `ParentRFLegalEntity` INT64,
  `CFLegalEntity` INT64 NOT NULL,
  `Level` STRING NOT NULL,
  `BankProcess` INT64 NOT NULL,
  `ParentInvoiceHeaderId` INT64 NOT NULL,
  `CFOverride` STRING NOT NULL,
  `CFOverrideBasePriceCommPercent` FLOAT64 NOT NULL,
  `CFOverrideExcessPriceCommPercent` FLOAT64 NOT NULL,
  `SelectedUI` INT64 NOT NULL,
  `EnterpriseFastlabelType` INT64 NOT NULL,
  `DueDate` DATETIME NOT NULL,
  `CloseDate` DATETIME NOT NULL,
  `TotalPaid` FLOAT64 NOT NULL,
  `CourierNumber` STRING NOT NULL,
  `GroupTaxExempt` INT64,
  `Loaded` DATETIME NOT NULL,
  `ProcessId` INT64 NOT NULL,
  `RecordSource` STRING NOT NULL,

  PRIMARY KEY (`InvoiceHeaderId`) NOT ENFORCED
)
PARTITION BY DATETIME_TRUNC(InvoiceDate, MONTH)
OPTIONS (
  require_partition_filter = FALSE
);
