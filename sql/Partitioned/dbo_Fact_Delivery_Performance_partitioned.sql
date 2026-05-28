CREATE OR REPLACE TABLE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Delivery_Performance_partitioned`
(
  ReceivedRF STRING,
  DeliveryRF STRING,
  DeliveryCF STRING,
  DeliveryDate DATE,
  Category STRING,
  NumLabels INT64,
  OnTimeKPI INT64,
  OnTimeKPI1 INT64,
  OnTimeKPI2 INT64,
  OnTimeSLA INT64,
  ProcessId INT64 NOT NULL,
  Created DATETIME NOT NULL,
  Updated DATETIME NOT NULL
)
PARTITION BY DeliveryDate
OPTIONS (
  require_partition_filter = FALSE
);