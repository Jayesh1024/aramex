CREATE OR REPLACE TABLE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Time_partitioned`
(
  Date_Key INT64 NOT NULL,
  Calendar_Date DATETIME NOT NULL,
  cal_day_in_week STRING NOT NULL,
  cal_day_in_week_no INT64 NOT NULL,
  cal_day_in_month INT64 NOT NULL,
  cal_day_in_year INT64 NOT NULL,
  cal_week_in_year INT64 NOT NULL,
  cal_month_no INT64 NOT NULL,
  cal_month INT64 NOT NULL,
  cal_month_name STRING NOT NULL,
  cal_quarter_no INT64 NOT NULL,
  cal_quarter INT64 NOT NULL,
  cal_year INT64 NOT NULL,
  week_day_flag STRING NOT NULL,
  week_end_flag STRING NOT NULL
)
PARTITION BY DATETIME_TRUNC(Calendar_Date, MONTH)
OPTIONS (
  require_partition_filter = FALSE
);