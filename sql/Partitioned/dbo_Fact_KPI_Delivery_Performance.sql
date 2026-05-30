CREATE OR REPLACE TABLE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI_Delivery_Performance`
(
  CountryCode INT64 NOT NULL,
  PickupRF STRING NOT NULL,
  DeliveryRF STRING NOT NULL,
  FromCf STRING NOT NULL,
  ToCf STRING NOT NULL,
  DeliveryDate DATE NOT NULL,
  Category STRING,
  NumofLabels INT64,
  OnTimePickup INT64,
  OnTimeLEA INT64,
  OnTimeDelivery INT64,
  OnTimeSLA INT64,
  PRIMARY KEY (CountryCode, PickupRF, DeliveryRF, FromCf, ToCf, DeliveryDate) NOT ENFORCED
)
PARTITION BY DeliveryDate
OPTIONS (
  require_partition_filter = FALSE
);