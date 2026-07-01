CREATE MATERIALIZED VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_RuralOnforwards`
OPTIONS(
  allow_non_incremental_definition = true,
  max_staleness = INTERVAL "30" MINUTE
) AS
SELECT
    SHA1(
        IF(
            Src.RF || '^' || Src.Courier || '^' || Src.Label || '^' || FORMAT_DATETIME('%Y-%m-%dT%H:%M:%E3S', Src.Date) IS NULL
                OR STRPOS(Src.RF || '^' || Src.Courier || '^' || Src.Label || '^' || FORMAT_DATETIME('%Y-%m-%dT%H:%M:%E3S', Src.Date), '^') = 0,
            UPPER(TRIM(Src.RF || '^' || Src.Courier || '^' || Src.Label || '^' || FORMAT_DATETIME('%Y-%m-%dT%H:%M:%E3S', Src.Date))),
            UPPER(
                ARRAY_TO_STRING(
                    ARRAY(
                        SELECT TRIM(part)
                        FROM UNNEST(SPLIT(Src.RF || '^' || Src.Courier || '^' || Src.Label || '^' || FORMAT_DATETIME('%Y-%m-%dT%H:%M:%E3S', Src.Date), '^')) AS part
                    ),
                    '^'
                )
            )
        )
    ) AS OnForwards_HSK,
    SHA1(
        IF(
            Src.Label IS NULL
                OR STRPOS(Src.Label, '^') = 0,
            UPPER(TRIM(Src.Label)),
            UPPER(
                ARRAY_TO_STRING(
                    ARRAY(
                        SELECT TRIM(part)
                        FROM UNNEST(SPLIT(Src.Label, '^')) AS part
                    ),
                    '^'
                )
            )
        )
    ) AS LabelNo_HSK,
    SHA1(
        IF(
            Src.RF IS NULL
                OR STRPOS(Src.RF, '^') = 0,
            UPPER(TRIM(Src.RF)),
            UPPER(
                ARRAY_TO_STRING(
                    ARRAY(
                        SELECT TRIM(part)
                        FROM UNNEST(SPLIT(Src.RF, '^')) AS part
                    ),
                    '^'
                )
            )
        )
    ) AS FranchiseeCode_HSK,
    SHA1(
        IF(
            Src.RF || '^' || Src.Courier IS NULL
                OR STRPOS(Src.RF || '^' || Src.Courier, '^') = 0,
            UPPER(TRIM(Src.RF || '^' || Src.Courier)),
            UPPER(
                ARRAY_TO_STRING(
                    ARRAY(
                        SELECT TRIM(part)
                        FROM UNNEST(SPLIT(Src.RF || '^' || Src.Courier, '^')) AS part
                    ),
                    '^'
                )
            )
        )
    ) AS Courier_HSK,
    Src.Country AS CountryCode,
    Src.RF,
    Src.Courier AS CF,
    Src.Label AS LabelNo,
    Src.Date AS CreatedDate,
    Src.Onforwards,
    C.CountryName,
    Src.FileId,
    '' AS RecordSource
FROM
    `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_LA_RuralOnforwards` Src
LEFT JOIN
    `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Country` C
    ON C.CountryCode = Src.Country
