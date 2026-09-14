CREATE MATERIALIZED VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_FL_Zones`
OPTIONS (
  allow_non_incremental_definition = true,
  max_staleness = INTERVAL "30" MINUTE -- Adjust staleness tolerance as needed (e.g., 30 MIN, 4 HOUR)
) AS
WITH fl_zones AS (
  SELECT * FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_fl_Zones`
)
SELECT
  SHA1(
    IF(
      CONCAT(
          IFNULL(NULLIF(CAST(CountryId AS STRING), ''), '') , '\r',
          IFNULL(NULLIF(CAST(ZoneCode AS STRING), ''), '') , '\r'
      ) IS NULL
      OR STRPOS(CONCAT(
          IFNULL(NULLIF(CAST(CountryId AS STRING), ''), '') , '\r',
          IFNULL(NULLIF(CAST(ZoneCode AS STRING), ''), '') , '\r'
      ), '^') = 0,
      UPPER(TRIM(CONCAT(
          IFNULL(NULLIF(CAST(CountryId AS STRING), ''), '') , '\r',
          IFNULL(NULLIF(CAST(ZoneCode AS STRING), ''), '') , '\r'
      ))),
      UPPER(
        ARRAY_TO_STRING(
          ARRAY(
            SELECT TRIM(part)
            FROM UNNEST(SPLIT(CONCAT(
          IFNULL(NULLIF(CAST(CountryId AS STRING), ''), '') , '\r',
          IFNULL(NULLIF(CAST(ZoneCode AS STRING), ''), '') , '\r'
      ), '^')) AS part
          ),
          '^'
        )
      )
    )
  ) as ZoneKey,
  CountryId,
  ZoneCode,
  Description,
  Type,
  DomOrInt,
  'Fastway_PriceOverrides' AS RecordSource
FROM fl_zones
