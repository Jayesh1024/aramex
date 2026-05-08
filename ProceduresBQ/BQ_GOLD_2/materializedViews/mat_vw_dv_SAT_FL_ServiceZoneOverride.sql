CREATE MATERIALIZED VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_FL_ServiceZoneOverride`
OPTIONS(
  allow_non_incremental_definition = true,
  max_staleness = INTERVAL "30" MINUTE
) AS
SELECT
  SHA1(
    IF(
      CONCAT(
        'Satchel',
        CHR(13),
        IFNULL(CONCAT(NULLIF(CAST(OverrideId AS STRING), ''), CHR(13)), ''),
        IFNULL(CONCAT(NULLIF(CAST(ServiceItemId AS STRING), ''), CHR(13)), ''),
        IFNULL(CONCAT(NULLIF(Zone, ''), CHR(13)), ''),
        IFNULL(CONCAT(NULLIF(SatchelSize, ''), CHR(13)), ''))
          IS NULL
        OR STRPOS(
          CONCAT(
            'Satchel',
            CHR(13),
            IFNULL(CONCAT(NULLIF(CAST(OverrideId AS STRING), ''), CHR(13)), ''),
            IFNULL(
              CONCAT(NULLIF(CAST(ServiceItemId AS STRING), ''), CHR(13)), ''),
            IFNULL(CONCAT(NULLIF(Zone, ''), CHR(13)), ''),
            IFNULL(CONCAT(NULLIF(SatchelSize, ''), CHR(13)), '')),
          '^')
          = 0,
      UPPER(
        TRIM(
          CONCAT(
            'Satchel',
            CHR(13),
            IFNULL(CONCAT(NULLIF(CAST(OverrideId AS STRING), ''), CHR(13)), ''),
            IFNULL(
              CONCAT(NULLIF(CAST(ServiceItemId AS STRING), ''), CHR(13)), ''),
            IFNULL(CONCAT(NULLIF(Zone, ''), CHR(13)), ''),
            IFNULL(CONCAT(NULLIF(SatchelSize, ''), CHR(13)), '')))),
      UPPER(
        ARRAY_TO_STRING(
          ARRAY(
            SELECT TRIM(part)
            FROM
              UNNEST(
                SPLIT(
                  CONCAT(
                    'Satchel',
                    CHR(13),
                    IFNULL(
                      CONCAT(NULLIF(CAST(OverrideId AS STRING), ''), CHR(13)),
                      ''),
                    IFNULL(
                      CONCAT(
                        NULLIF(CAST(ServiceItemId AS STRING), ''), CHR(13)),
                      ''),
                    IFNULL(CONCAT(NULLIF(Zone, ''), CHR(13)), ''),
                    IFNULL(CONCAT(NULLIF(SatchelSize, ''), CHR(13)), '')),
                  '^')) AS part
          ),
          '^'))))
    AS ZoneOverrides_HSK,
  'Satchel' AS OverrideType,
  OverrideId,
  ServiceItemId,
  Zone,
  SatchelSize,
  0 AS FromWeight,
  0 AS ToWeight,
  PickupAmount,
  ServiceCommission,
  ServiceAmount,
  FixedOrPercentage,
  UpdatedOn,
  UpdatedBy,
  'Fastway_PriceOverrides' AS RecordSource
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_fl_ServiceZoneSatchelOverrides`
UNION DISTINCT
SELECT
  SHA1(
    IF(
      CONCAT(
      'Weight',
      CHR(13),
      IFNULL(CONCAT(NULLIF(CAST(OverrideId AS STRING), ''), CHR(13)), ''),
      IFNULL(CONCAT(NULLIF(CAST(ServiceItemId AS STRING), ''), CHR(13)), ''),
      IFNULL(CONCAT(NULLIF(Zone, ''), CHR(13)), ''),
      IFNULL(CONCAT(NULLIF(CAST(FromWeight AS STRING), ''), CHR(13)), '')) IS NULL
      OR STRPOS(CONCAT(
      'Weight',
      CHR(13),
      IFNULL(CONCAT(NULLIF(CAST(OverrideId AS STRING), ''), CHR(13)), ''),
      IFNULL(CONCAT(NULLIF(CAST(ServiceItemId AS STRING), ''), CHR(13)), ''),
      IFNULL(CONCAT(NULLIF(Zone, ''), CHR(13)), ''),
      IFNULL(CONCAT(NULLIF(CAST(FromWeight AS STRING), ''), CHR(13)), '')), CHR(13)) = 0,
      UPPER(TRIM(CONCAT(
      'Weight',
      CHR(13),
      IFNULL(CONCAT(NULLIF(CAST(OverrideId AS STRING), ''), CHR(13)), ''),
      IFNULL(CONCAT(NULLIF(CAST(ServiceItemId AS STRING), ''), CHR(13)), ''),
      IFNULL(CONCAT(NULLIF(Zone, ''), CHR(13)), ''),
      IFNULL(CONCAT(NULLIF(CAST(FromWeight AS STRING), ''), CHR(13)), '')))),
      UPPER(
        ARRAY_TO_STRING(
          ARRAY(
            SELECT TRIM(part)
            FROM UNNEST(SPLIT(CONCAT(
      'Weight',
      CHR(13),
      IFNULL(CONCAT(NULLIF(CAST(OverrideId AS STRING), ''), CHR(13)), ''),
      IFNULL(CONCAT(NULLIF(CAST(ServiceItemId AS STRING), ''), CHR(13)), ''),
      IFNULL(CONCAT(NULLIF(Zone, ''), CHR(13)), ''),
      IFNULL(CONCAT(NULLIF(CAST(FromWeight AS STRING), ''), CHR(13)), '')), CHR(13))) AS part
          ),
          CHR(13)
        )
      )
    )
  ) AS ZoneOverrides_HSK,
  'Weight' AS OverrideType,
  OverrideId,
  ServiceItemId,
  Zone,
  '' AS SatchelSize,
  FromWeight,
  ToWeight,
  PickupAmount,
  ServiceCommission,
  ServiceAmount,
  FixedOrPercentage,
  UpdatedOn,
  UpdatedBy,
  'Fastway_PriceOverrides' AS RecordSource
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_fl_ServiceZoneWeightOverrides`;


