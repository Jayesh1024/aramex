-- ==========================================================================================
-- Routine:     dv_Load_SAT_CF (courier franchisee)
-- Description: Loads attributes into SAT_CF
--              BigQuery compatible version of Load_SAT_CF
-- Example:     CALL dv.dv_Load_SAT_CF(123, 'Fastway')
-- History:
--  25/10/2018  P. Waldron      Routine Written
--  28/07/2021  B. Woods        Added column [CourierGroup]
--  [BQ Port]   Converted from SQL Server to BigQuery
--  [BQ Fix]    dbo.FormatAddress(a,b,c,d) replaced with ARRAY_TO_STRING/UNNEST/NULLIF logic.
--  [BQ Fix]    TO_HEX(MD5(...)) → MD5(...) for Courier_HSK (target column is BYTES not STRING).
--  [BQ Fix]    MERGE source deduplicated with ROW_NUMBER() to avoid "multiple source rows"
--              error when staging has duplicate RFCode/CourierNumber combinations.
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_SAT_CF`(
    IN p_ProcessID    INT64,
    IN p_RecordSource STRING
)
BEGIN

    DECLARE DefaultValidFrom DATETIME DEFAULT DATETIME '1900-01-01 00:00:00';
    DECLARE DefaultValidTo   DATETIME DEFAULT DATETIME '9999-12-31 00:00:00';
    DECLARE Loaded           DATETIME DEFAULT CURRENT_DATETIME();

    -- MERGE with OUTPUT $action not supported in BQ.
    -- Replaced with:
    --   STEP 1: MERGE to expire changed current rows (IsCurrent=0, ValidTo=Loaded)
    --   STEP 2: INSERT new rows (IsCurrent=1)
    -- dbo.GetHashKey replaced with MD5(...) (BYTES).
    -- RTRIM → TRIM. SYSDATETIME() → CURRENT_DATETIME().
    -- dbo.FormatAddress → ARRAY_TO_STRING/UNNEST/NULLIF logic.
    -- BEGIN TRANSACTION / COMMIT / ROLLBACK removed.
    -- WITH (NOLOCK) removed.

    BEGIN

        -- -----------------------------------------------------------------------
        -- STEP 1: Expire changed current rows (IsCurrent=0, ValidTo=Loaded)
        -- -----------------------------------------------------------------------
        MERGE `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_CF` AS Tgt
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
                        PARTITION BY IFNULL(Sat.Courier_HSK, MD5(Stg.RFCode || '^' || Stg.CourierNumber))
                        ORDER BY Stg.RFCode, Stg.CourierNumber
                    ) AS rn
                FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Courier_Stg` Stg
                LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_CF` Sat
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
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_CF`
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
            -- MD5 returns BYTES to match target BYTES column type; TO_HEX removed
            IFNULL(Sat.Courier_HSK, MD5(Stg.RFCode || '^' || Stg.CourierNumber)) AS Courier_HSK,
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
            SELECT *,
                ROW_NUMBER() OVER (
                    PARTITION BY RFCode, CourierNumber
                    ORDER BY RFCode, CourierNumber
                ) AS rn
            FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Courier_Stg`
        ) Stg
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_CF` Sat
            ON Sat.RFCode = Stg.RFCode AND Sat.CourierNumber = Stg.CourierNumber
        WHERE Stg.rn = 1
          AND NOT EXISTS (
            SELECT 1 FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_CF` Tgt
            WHERE Tgt.Courier_HSK = IFNULL(Sat.Courier_HSK, MD5(Stg.RFCode || '^' || Stg.CourierNumber))
              AND Tgt.IsCurrent   = 1
        );

    EXCEPTION WHEN ERROR THEN
        -- Original returned failure result; BQ surfaces exception to caller
        RAISE USING MESSAGE = 'dv_Load_SAT_CF failed: ' || @@error.message;
    END;

END;