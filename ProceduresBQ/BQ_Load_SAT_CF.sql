-- ==========================================================================================
-- Routine:     BQ_Load_SAT_CF (courier franchisee)
-- Description: Loads attributes into SAT_CF
--              BigQuery compatible version of dv.Load_SAT_CF
--              Note: MERGE with OUTPUT $action not supported in BQ.
--                    Replaced with:
--                      1. MERGE to expire changed current rows (IsCurrent=0, ValidTo=Loaded)
--                      2. INSERT new rows (IsCurrent=1)
--                    dbo.GetHashKey → TO_HEX(MD5(...))
--                    dbo.FormatAddress → inline CONCAT with NULLIF trimming (BQ has no UDF equiv)
--                    RTRIM → TRIM
--                    SYSDATETIME() → CURRENT_DATETIME()
--                    BEGIN TRY/CATCH → BEGIN/EXCEPTION WHEN ERROR THEN
--                    Audit table format preserved exactly.
-- Example:     CALL dv.BQ_Load_SAT_CF(123, 'Fastway')
-- History:
--  25/10/2018  P. Waldron      Routine Written
--  28/07/2021  B. Woods        Added column [CourierGroup]
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE dv.BQ_Load_SAT_CF(
    IN ProcessID    INT64,
    IN RecordSource STRING
)
BEGIN

    DECLARE DefaultValidFrom DATETIME DEFAULT DATETIME '1900-01-01 00:00:00';
    DECLARE DefaultValidTo   DATETIME DEFAULT DATETIME '9999-12-31 00:00:00';
    DECLARE Loaded           DATETIME DEFAULT CURRENT_DATETIME();

    BEGIN

        -- -----------------------------------------------------------------------
        -- STEP 1: Expire changed current rows (IsCurrent=0, ValidTo=Loaded)
        -- Replicates MERGE WHEN MATCHED AND EXISTS(... EXCEPT ...) THEN UPDATE
        -- -----------------------------------------------------------------------
        MERGE dv.SAT_CF AS Tgt
        USING (
            SELECT DISTINCT
                Sat.Courier_HSK,
                Stg.RFCode,
                Stg.CourierNumber,
                TRIM(Stg.Name)                   AS Name,
                TRIM(Stg.ShortName)              AS ShortName,
                TRIM(Stg.CFName)                 AS CFName,
                -- dbo.FormatAddress replaced with inline CONCAT (null-safe)
                -- Original: [dbo].[FormatAddress](Address1,Address2,Address3,Address4)
                TRIM(CONCAT_WS(', ',
                    NULLIF(TRIM(Stg.Address1), ''),
                    NULLIF(TRIM(Stg.Address2), ''),
                    NULLIF(TRIM(Stg.Address3), ''),
                    NULLIF(TRIM(Stg.Address4), '')
                ))                               AS Address,
                TRIM(Stg.EmailAddress)           AS EmailAddress,
                TRIM(Stg.PhoneNumber)            AS PhoneNumber,
                TRIM(Stg.Mobile)                 AS MobileNumber,
                Stg.BlackbayRouteId,
                TRIM(Stg.CourierGroup)           AS CourierGroup,
                TRIM(Stg.CFOwnershipModel)       AS CFOwnershipModel,
                Stg.Inactive,
                TRIM(Stg.ParcelConnectCFTerritory) AS ParcelConnectCFTerritory
            FROM Staging.Courier_Stg Stg
            LEFT JOIN dv.SAT_CF Sat
                ON  Sat.RFCode        = Stg.RFCode
                AND Sat.CourierNumber = Stg.CourierNumber
        ) AS Src
        ON  Tgt.Courier_HSK = Src.Courier_HSK
        AND Tgt.IsCurrent   = 1
        WHEN MATCHED AND (
            -- Replicate EXCEPT change detection
            IFNULL(Tgt.RFCode,                      '') <> IFNULL(Src.RFCode,                      '')
         OR IFNULL(Tgt.CourierNumber,               '') <> IFNULL(Src.CourierNumber,               '')
         OR IFNULL(Tgt.Name,                        '') <> IFNULL(Src.Name,                        '')
         OR IFNULL(Tgt.ShortName,                   '') <> IFNULL(Src.ShortName,                   '')
         OR IFNULL(Tgt.CFName,                      '') <> IFNULL(Src.CFName,                      '')
         OR IFNULL(Tgt.Address,                     '') <> IFNULL(Src.Address,                     '')
         OR IFNULL(Tgt.EmailAddress,                '') <> IFNULL(Src.EmailAddress,                '')
         OR IFNULL(Tgt.PhoneNumber,                 '') <> IFNULL(Src.PhoneNumber,                 '')
         OR IFNULL(Tgt.MobileNumber,                '') <> IFNULL(Src.MobileNumber,                '')
         OR IFNULL(CAST(Tgt.BlackbayRouteId AS STRING),'') <> IFNULL(CAST(Src.BlackbayRouteId AS STRING),'')
         OR IFNULL(Tgt.CourierGroup,                '') <> IFNULL(Src.CourierGroup,                '')
         OR IFNULL(Tgt.CFOwnershipModel,            '') <> IFNULL(Src.CFOwnershipModel,            '')
         OR IFNULL(CAST(Tgt.Inactive AS STRING),    '') <> IFNULL(CAST(Src.Inactive AS STRING),    '')
         OR IFNULL(Tgt.ParcelConnectCFTerritory,    '') <> IFNULL(Src.ParcelConnectCFTerritory,    '')
        )
        THEN UPDATE SET
            IsCurrent = 0,
            ValidTo   = Loaded;

        -- -----------------------------------------------------------------------
        -- STEP 2: Insert new rows (WHEN NOT MATCHED BY TARGET)
        -- -----------------------------------------------------------------------
        INSERT INTO dv.SAT_CF
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
        SELECT DISTINCT
            IFNULL(
                Sat.Courier_HSK,
                TO_HEX(MD5(Stg.RFCode || '^' || Stg.CourierNumber))
            )                                    AS Courier_HSK,
            Stg.RFCode,
            Stg.CourierNumber,
            TRIM(Stg.Name)                       AS Name,
            TRIM(Stg.ShortName)                  AS ShortName,
            TRIM(Stg.CFName)                     AS CFName,
            TRIM(CONCAT_WS(', ',
                NULLIF(TRIM(Stg.Address1), ''),
                NULLIF(TRIM(Stg.Address2), ''),
                NULLIF(TRIM(Stg.Address3), ''),
                NULLIF(TRIM(Stg.Address4), '')
            ))                                   AS Address,
            TRIM(Stg.EmailAddress)               AS EmailAddress,
            TRIM(Stg.PhoneNumber)                AS PhoneNumber,
            TRIM(Stg.Mobile)                     AS MobileNumber,
            Stg.BlackbayRouteId,
            TRIM(Stg.CourierGroup)               AS CourierGroup,
            TRIM(Stg.CFOwnershipModel)           AS CFOwnershipModel,
            TRIM(Stg.ParcelConnectCFTerritory)   AS ParcelConnectCFTerritory,
            Stg.Inactive,
            CURRENT_DATETIME()                   AS Loaded,
            ProcessID                            AS ProcessId,
            RecordSource,
            DefaultValidFrom                     AS ValidFrom,
            DefaultValidTo                       AS ValidTo,
            1                                    AS IsCurrent
        FROM Staging.Courier_Stg Stg
        LEFT JOIN dv.SAT_CF Sat
            ON  Sat.RFCode        = Stg.RFCode
            AND Sat.CourierNumber = Stg.CourierNumber
        WHERE NOT EXISTS (
            SELECT 1
            FROM dv.SAT_CF Tgt
            WHERE Tgt.Courier_HSK = IFNULL(
                    Sat.Courier_HSK,
                    TO_HEX(MD5(Stg.RFCode || '^' || Stg.CourierNumber))
                )
              AND Tgt.IsCurrent = 1
        );

    EXCEPTION WHEN ERROR THEN
        -- Surface the error; caller handles logging
        RAISE USING MESSAGE = @@error.message;

    END;

END;
