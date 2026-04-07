-- ==========================================================================================
-- Routine:     BQ_Load_SAT_CF (courier franchisee)
-- Description: Loads attributes into SAT_CF
--              BigQuery compatible version of Load_SAT_CF
-- Example:     CALL dv.BQ_Load_SAT_CF(123, 'Fastway')
-- History:
--  25/10/2018  P. Waldron      Routine Written
--  28/07/2021  B. Woods        Added column [CourierGroup]
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.BQ_Load_SAT_CF`(
    IN ProcessID    INT64,
    IN RecordSource STRING
)
BEGIN

    DECLARE DefaultValidFrom DATETIME DEFAULT DATETIME '1900-01-01 00:00:00';
    DECLARE DefaultValidTo   DATETIME DEFAULT DATETIME '9999-12-31 00:00:00';
    DECLARE Loaded           DATETIME DEFAULT CURRENT_DATETIME();

    -- MERGE with OUTPUT $action not supported in BQ.
    -- Replaced with:
    --   STEP 1: MERGE to expire changed current rows (IsCurrent=0, ValidTo=Loaded)
    --   STEP 2: INSERT new rows (IsCurrent=1)
    -- dbo.GetHashKey replaced with TO_HEX(MD5(...)).
    -- RTRIM → TRIM. SYSDATETIME() → CURRENT_DATETIME().
    -- dbo.FormatAddress → user-defined function call preserved as-is
    --   (must exist as BQ UDF or be replaced with equivalent CONCAT logic).
    -- BEGIN TRANSACTION / COMMIT / ROLLBACK removed.
    -- WITH (NOLOCK) removed.

    BEGIN

        -- -----------------------------------------------------------------------
        -- STEP 1: Expire changed current rows (IsCurrent=0, ValidTo=Loaded)
        -- -----------------------------------------------------------------------
        MERGE `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_CF` AS Tgt
        USING (
            SELECT DISTINCT
                Sat.Courier_HSK,
                Stg.RFCode,
                Stg.CourierNumber,
                TRIM(Stg.Name)                              AS Name,
                TRIM(Stg.ShortName)                         AS ShortName,
                TRIM(Stg.CFName)                            AS CFName,
                dbo.FormatAddress(Stg.Address1, Stg.Address2, Stg.Address3, Stg.Address4) AS Address,
                TRIM(Stg.EmailAddress)                      AS EmailAddress,
                TRIM(Stg.PhoneNumber)                       AS PhoneNumber,
                TRIM(Stg.Mobile)                            AS MobileNumber,
                Stg.BlackbayRouteId,
                TRIM(Stg.CourierGroup)                      AS CourierGroup,
                TRIM(Stg.CFOwnershipModel)                  AS CFOwnershipModel,
                Stg.Inactive,
                TRIM(Stg.ParcelConnectCFTerritory)          AS ParcelConnectCFTerritory
            FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Courier_Stg` Stg
            LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_CF` Sat
                ON Sat.RFCode = Stg.RFCode AND Sat.CourierNumber = Stg.CourierNumber
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
            -- dbo.GetHashKey → TO_HEX(MD5(...))
            IFNULL(Sat.Courier_HSK, TO_HEX(MD5(Stg.RFCode || '^' || Stg.CourierNumber))) AS Courier_HSK,
            Stg.RFCode,
            Stg.CourierNumber,
            TRIM(Stg.Name)                              AS Name,
            TRIM(Stg.ShortName)                         AS ShortName,
            TRIM(Stg.CFName)                            AS CFName,
            dbo.FormatAddress(Stg.Address1, Stg.Address2, Stg.Address3, Stg.Address4) AS Address,
            TRIM(Stg.EmailAddress)                      AS EmailAddress,
            TRIM(Stg.PhoneNumber)                       AS PhoneNumber,
            TRIM(Stg.Mobile)                            AS MobileNumber,
            Stg.BlackbayRouteId,
            TRIM(Stg.CourierGroup)                      AS CourierGroup,
            TRIM(Stg.CFOwnershipModel)                  AS CFOwnershipModel,
            TRIM(Stg.ParcelConnectCFTerritory)          AS ParcelConnectCFTerritory,
            Stg.Inactive,
            CURRENT_DATETIME()                          AS Loaded,
            ProcessID,
            RecordSource,
            DefaultValidFrom                            AS ValidFrom,
            DefaultValidTo                              AS ValidTo,
            1                                           AS IsCurrent
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Courier_Stg` Stg
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_CF` Sat
            ON Sat.RFCode = Stg.RFCode AND Sat.CourierNumber = Stg.CourierNumber
        WHERE NOT EXISTS (
            SELECT 1 FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_CF` Tgt
            WHERE Tgt.Courier_HSK = IFNULL(Sat.Courier_HSK, TO_HEX(MD5(Stg.RFCode || '^' || Stg.CourierNumber)))
              AND Tgt.IsCurrent   = 1
        );

    EXCEPTION WHEN ERROR THEN
        -- Original returned failure result; BQ surfaces exception to caller
        RAISE USING MESSAGE = 'BQ_Load_SAT_CF failed: ' || @@error.message;
    END;

END;
