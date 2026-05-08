CREATE MATERIALIZED VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_FL_PriceListCustomerOverride`
OPTIONS(
  allow_non_incremental_definition = true,
  max_staleness = INTERVAL "30" MINUTE
) AS
SELECT
SHA1(
    IF(
      CONCAT(
      IFNULL(NULLIF(CAST(CountryId AS STRING), ''), '') || '\r',
      IFNULL(NULLIF(CAST(CustomerId AS STRING), ''), '') || '\r',
      IFNULL(NULLIF(CAST(PriceList AS STRING), ''), '') || '\r',
      IFNULL(NULLIF(CAST(ProductId AS STRING), ''), '') || '\r') IS NULL
      OR STRPOS(CONCAT(
      IFNULL(NULLIF(CAST(CountryId AS STRING), ''), '') || '\r',
      IFNULL(NULLIF(CAST(CustomerId AS STRING), ''), '') || '\r',
      IFNULL(NULLIF(CAST(PriceList AS STRING), ''), '') || '\r',
      IFNULL(NULLIF(CAST(ProductId AS STRING), ''), '') || '\r'), '^') = 0,
      UPPER(TRIM(CONCAT(
      IFNULL(NULLIF(CAST(CountryId AS STRING), ''), '') || '\r',
      IFNULL(NULLIF(CAST(CustomerId AS STRING), ''), '') || '\r',
      IFNULL(NULLIF(CAST(PriceList AS STRING), ''), '') || '\r',
      IFNULL(NULLIF(CAST(ProductId AS STRING), ''), '') || '\r'))),
      UPPER(
        ARRAY_TO_STRING(
          ARRAY(
            SELECT TRIM(part)
            FROM UNNEST(SPLIT(CONCAT(
      IFNULL(NULLIF(CAST(CountryId AS STRING), ''), '') || '\r',
      IFNULL(NULLIF(CAST(CustomerId AS STRING), ''), '') || '\r',
      IFNULL(NULLIF(CAST(PriceList AS STRING), ''), '') || '\r',
      IFNULL(NULLIF(CAST(ProductId AS STRING), ''), '') || '\r'), '^')) AS part
          ),
          '^'
        )
      )
    )
  ) AS CustomerPriceOverride_HSK,
  CountryId,
  CustomerId,
  PriceList,
  ProductId,
  BaseDiscountPercent,
  ExcessDiscountPercent,
  BaseCommissionOverridePercent,
  BaseCommissionOverridePercentForce,
  ExcessCommissionOverridePercent,
  ExcessCommissionOverrideForce,
  'Fastway_PriceOverrides' AS RecordSource
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_fl_PriceListCustomerOverride`;


