CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_SAT_CF`(
    IN p_ProcessID    INT64,
    IN p_RecordSource STRING
)
BEGIN

    DECLARE DefaultValidFrom DATETIME DEFAULT DATETIME '1900-01-01 00:00:00';
    DECLARE DefaultValidTo   DATETIME DEFAULT DATETIME '9999-12-31 00:00:00';
    DECLARE Loaded           DATETIME DEFAULT CURRENT_DATETIME();

    BEGIN

        -- -----------------------------------------------------------------------
        -- STEP 1: Expire changed current rows (IsCurrent=0, ValidTo=Loaded)
        -- -----------------------------------------------------------------------
        MERGE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_CF` AS Tgt
        USING (
            SELECT
                Courier_HSK,
                RFCode,
                CourierNumber,
                Name,
                ShortName,
                CFName,
                Address,
                EmailAddress,
                PhoneNumber,
                MobileNumber,
                BlackbayRouteId,
                CourierGroup,
                CFOwnershipModel,
                Inactive,
                ParcelConnectCFTerritory
            FROM (
                SELECT
                    Sat.Courier_HSK,
                    Stg.RFCode,
                    Stg.CourierNumber,
                    TRIM(Stg.Name)                              AS Name,
                    TRIM(Stg.ShortName)                         AS ShortName,
                    TRIM(Stg.CFName)                            AS CFName,
                    TRIM(ARRAY_TO_STRING(
                        ARRAY(
                            SELECT part FROM UNNEST([
                                NULLIF(TRIM(Stg.Address1), ''),
                                NULLIF(TRIM(Stg.Address2), ''),
                                NULLIF(TRIM(Stg.Address3), ''),
                                NULLIF(TRIM(Stg.Address4), '')
                            ]) AS part
                            WHERE part IS NOT NULL
                        ), ', '
                    ))                                          AS Address,
                    TRIM(Stg.EmailAddress)                      AS EmailAddress,
                    TRIM(Stg.PhoneNumber)                       AS PhoneNumber,
                    TRIM(Stg.Mobile)                            AS MobileNumber,
                    Stg.BlackbayRouteId,
                    TRIM(Stg.CourierGroup)                      AS CourierGroup,
                    TRIM(Stg.CFOwnershipModel)                  AS CFOwnershipModel,
                    Stg.Inactive,
                    TRIM(Stg.ParcelConnectCFTerritory)          AS ParcelConnectCFTerritory,
                    -- Deduplicate: keep one row per Courier_HSK
                    ROW_NUMBER() OVER (
                        PARTITION BY IFNULL(Sat.Courier_HSK, `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(Stg.RFCode || '^' || Stg.CourierNumber, '^'))
                        ORDER BY Stg.RFCode, Stg.CourierNumber
                    ) AS rn
                FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Courier_Stg` Stg
                LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_CF` Sat
                    ON Sat.RFCode = Stg.RFCode AND Sat.CourierNumber = Stg.CourierNumber
            )
            WHERE rn = 1
        ) AS Src
        ON  Tgt.Courier_HSK = Src.Courier_HSK
        AND Tgt.IsCurrent   = 1
        -- EXCEPT change-detection replaced with column-by-column IFNULL comparison
        WHEN MATCHED AND (
            IFNULL(Tgt.RFCode,                  '') <> IFNULL(Src.RFCode,                  '')
         OR IFNULL(Tgt.CourierNumber,            '') <> IFNULL(Src.CourierNumber,            '')
         OR IFNULL(Tgt.Name,                     '') <> IFNULL(Src.Name,                     '')
         OR IFNULL(Tgt.ShortName,                '') <> IFNULL(Src.ShortName,                '')
         OR IFNULL(Tgt.CFName,                   '') <> IFNULL(Src.CFName,                   '')
         OR IFNULL(Tgt.Address,                  '') <> IFNULL(Src.Address,                  '')
         OR IFNULL(Tgt.EmailAddress,             '') <> IFNULL(Src.EmailAddress,             '')
         OR IFNULL(Tgt.PhoneNumber,              '') <> IFNULL(Src.PhoneNumber,              '')
         OR IFNULL(Tgt.MobileNumber,             '') <> IFNULL(Src.MobileNumber,             '')
         OR IFNULL(CAST(Tgt.BlackbayRouteId AS STRING), '') <> IFNULL(CAST(Src.BlackbayRouteId AS STRING), '')
         OR IFNULL(Tgt.CourierGroup,             '') <> IFNULL(Src.CourierGroup,             '')
         OR IFNULL(Tgt.CFOwnershipModel,         '') <> IFNULL(Src.CFOwnershipModel,         '')
         OR IFNULL(CAST(Tgt.Inactive AS STRING), '') <> IFNULL(CAST(Src.Inactive AS STRING), '')
         OR IFNULL(Tgt.ParcelConnectCFTerritory, '') <> IFNULL(Src.ParcelConnectCFTerritory, '')
        )
        THEN UPDATE SET
            IsCurrent = 0,
            ValidTo   = Loaded;

        -- -----------------------------------------------------------------------
        -- STEP 2: Insert new rows for unmatched source records (IsCurrent=1)
        -- -----------------------------------------------------------------------
        INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_CF`
        (
            Courier_HSK,
            RFCode,
            CourierNumber,
            Name,
            ShortName,
            CFName,
            Address,
            EmailAddress,
            PhoneNumber,
            MobileNumber,
            BlackbayRouteId,
            CourierGroup,
            CFOwnershipModel,
            ParcelConnectCFTerritory,
            Inactive,
            Loaded,
            ProcessId,
            RecordSource,
            ValidFrom,
            ValidTo,
            IsCurrent
        )
        SELECT
            Stg.Courier_HSK,
            Stg.RFCode,
            Stg.CourierNumber,
            TRIM(Stg.Name)                              AS Name,
            TRIM(Stg.ShortName)                         AS ShortName,
            TRIM(Stg.CFName)                            AS CFName,
            TRIM(ARRAY_TO_STRING(
                ARRAY(
                    SELECT part FROM UNNEST([
                        NULLIF(TRIM(Stg.Address1), ''),
                        NULLIF(TRIM(Stg.Address2), ''),
                        NULLIF(TRIM(Stg.Address3), ''),
                        NULLIF(TRIM(Stg.Address4), '')
                    ]) AS part
                    WHERE part IS NOT NULL
                ), ', '
            ))                                          AS Address,
            TRIM(Stg.EmailAddress)                      AS EmailAddress,
            TRIM(Stg.PhoneNumber)                       AS PhoneNumber,
            TRIM(Stg.Mobile)                            AS MobileNumber,
            Stg.BlackbayRouteId,
            TRIM(Stg.CourierGroup)                      AS CourierGroup,
            TRIM(Stg.CFOwnershipModel)                  AS CFOwnershipModel,
            TRIM(Stg.ParcelConnectCFTerritory)          AS ParcelConnectCFTerritory,
            Stg.Inactive,
            CURRENT_DATETIME()                          AS Loaded,
            p_ProcessID AS ProcessID,
            p_RecordSource AS RecordSource,
            DefaultValidFrom                            AS ValidFrom,
            DefaultValidTo                              AS ValidTo,
            1                                           AS IsCurrent
        FROM (
            SELECT
                *,
                `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(courier_stg.RFCode || '^' || courier_stg.CourierNumber, '^') AS Courier_HSK,
                ROW_NUMBER() OVER (
                    PARTITION BY RFCode, CourierNumber
                    ORDER BY RFCode, CourierNumber
                ) AS rn
            FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Courier_Stg` courier_stg
        ) Stg
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_CF` Sat
            ON Sat.RFCode = Stg.RFCode AND Sat.CourierNumber = Stg.CourierNumber
        WHERE Stg.rn = 1
          AND NOT EXISTS (
            SELECT 1 FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_CF` Tgt
            WHERE Tgt.Courier_HSK = Stg.Courier_HSK
              AND Tgt.IsCurrent   = 1
        );

    EXCEPTION WHEN ERROR THEN
        RAISE USING MESSAGE = 'dv_Load_SAT_CF failed: ' || @@error.message;
    END;

END;