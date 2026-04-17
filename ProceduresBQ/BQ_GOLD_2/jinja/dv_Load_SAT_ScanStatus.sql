-- ==========================================================================================
-- Routine:     dv_Load_SAT_ScanStatus
-- Description: Loads attributes into SAT_ScanStatus
--              BigQuery compatible version of Load_SAT_ScanStatus
--              Note: MERGE with OUTPUT $action not supported in BQ.
--                    Replaced with:
--                      1. MERGE to expire changed current rows (IsCurrent=0, ValidTo=Loaded)
--                      2. INSERT new rows (IsCurrent=1)
--                    Audit table format preserved exactly.
--                    PIVOT replaced with conditional aggregation against SAT_Product
--                      (matches original which queries SAT_Product, not SAT_ScanStatus).
--                    dbo.GetHashKey replaced with MD5(...) (BYTES).
-- Example:     CALL dv.dv_Load_SAT_ScanStatus(190, 'Fastway')
-- History:
--  15/10/2018  P. Waldron      Routine Written
--  29/07/2021  B. Woods        Added column Active
--  [BQ Port]   Converted from SQL Server to BigQuery
--  [BQ Fix]    Cast ALL columns to STRING in USING subquery to resolve
--              IFNULL(T1,T1) type mismatch in WHEN MATCHED clause.
--  [BQ Fix]    TO_HEX(MD5(...)) → MD5(...) for ScanStatus_HSK (target column is BYTES).
--  [BQ Fix]    Loaded variable → CURRENT_DATETIME() in INSERT SELECT to avoid NULL.
--  [BQ Fix]    ProcessID, RecordSource → CAST(...) to force variable resolution.
--  [BQ Fix]    DefaultValidFrom/To → inlined DATETIME literals to avoid NULL.
--  [BQ Fix]    SELECT DISTINCT replaced with ROW_NUMBER() dedup subquery
--              (DISTINCT cannot deduplicate BYTES columns in BigQuery).
--  [BQ Fix]    SaveLog → Staging_SaveLog with additional -1 argument.
--  [BQ Fix]    StatusCode cast to STRING in JOIN and MD5 hash.
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_SAT_ScanStatus`(
    IN ProcessID    INT64,
    IN RecordSource STRING
)
BEGIN

    DECLARE DefaultValidFrom DATETIME DEFAULT DATETIME '1900-01-01 00:00:00';
    DECLARE DefaultValidTo   DATETIME DEFAULT DATETIME '9999-12-31 00:00:00';
    DECLARE Loaded           DATETIME DEFAULT CURRENT_DATETIME();

    DECLARE Component    STRING DEFAULT 'dv.Load_SAT_ScanStatus';
    DECLARE Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING;
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64 DEFAULT 0;
    DECLARE Updated      INT64 DEFAULT 0;

    BEGIN

        -- -----------------------------------------------------------------------
        -- STEP 1: Expire changed current rows (IsCurrent=0, ValidTo=Loaded)
        -- ALL columns cast to STRING in USING subquery so every IFNULL(...,'')
        -- comparison in WHEN MATCHED is guaranteed STRING vs STRING.
        -- -----------------------------------------------------------------------
        MERGE `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_ScanStatus` AS Tgt
        USING (
            SELECT DISTINCT
                Sat.ScanStatus_HSK,
                IF(Stg.CountryName IS NULL, 'Unknown', TRIM(Stg.CountryName))  AS CountryName,
                CAST(Stg.StatusCode AS STRING)                                  AS ScanStatus,
                TRIM(Stg.Description)                                           AS Description,
                TRIM(Stg.ExtendedDescription)                                   AS ExtendedDescription,
                CAST(Stg.ShowToCustomer AS STRING)                              AS ShowToCustomer,
                CAST(Stg.Misdirected AS STRING)                                 AS Misdirected,
                CAST(Stg.LeftByCF AS STRING)                                    AS LeftByCF,
                CAST(Stg.Undeliverable AS STRING)                               AS Undeliverable,
                CAST(Stg.CageScan AS STRING)                                    AS CageScan,
                CAST(Stg.BBForceToTScan AS STRING)                              AS BBForceToTScan,
                CAST(Stg.DontSendToBB AS STRING)                                AS DontSendToBB,
                CAST(Stg.CanSelectInRunsheetScanning AS STRING)                 AS CanSelectInRunsheetScanning,
                CAST(Stg.HeaderGroup AS STRING)                                 AS HeaderGroup,
                CAST(Stg.CFBayScan AS STRING)                                   AS CFBayScan,
                CAST(Stg.ContainerScan AS STRING)                               AS ContainerScan,
                CAST(Stg.Active AS STRING)                                      AS Active,
                CAST(Stg.ForcedScanType AS STRING)                              AS ForcedScanType,
                CAST(Stg.ExcludeFromMFYBilling AS STRING)                       AS ExcludeFromMFYBilling,
                CAST(Stg.ImpactStatus AS STRING)                                AS ImpactStatus,
                CAST(Stg.Pickup AS STRING)                                      AS Pickup,
                CAST(Stg.PickupRF AS STRING)                                    AS PickupRF,
                CAST(Stg.DeliveryRF AS STRING)                                  AS DeliveryRF,
                CAST(Stg.Delivered AS STRING)                                   AS Delivered,
                CAST(Stg.PrePickup AS STRING)                                   AS PrePickup,
                CAST(Stg.Problem AS STRING)                                     AS Problem,
                CAST(Stg.AttemptedDelivery AS STRING)                           AS AttemptedDelivery,
                CAST(Stg.CollectionRequired AS STRING)                          AS CollectionRequired,
                CAST(Stg.Onforward AS STRING)                                   AS Onforward,
                CAST(Stg.Delayed AS STRING)                                     AS Delayed,
                CAST(Stg.ReadyToCollect AS STRING)                              AS ReadyToCollect
            FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_ScanStatus_Stg` Stg
            LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_ScanStatus` Sat
                ON  Sat.CountryName = Stg.CountryName
                AND Sat.ScanStatus  = CAST(Stg.StatusCode AS STRING)
        ) AS Src
        ON  Tgt.ScanStatus_HSK = Src.ScanStatus_HSK
        AND Tgt.IsCurrent      = 1
        WHEN MATCHED AND (
            IFNULL(Tgt.CountryName,                               '') <> IFNULL(Src.CountryName,              '')
         OR IFNULL(CAST(Tgt.ScanStatus AS STRING),                '') <> IFNULL(Src.ScanStatus,              '')
         OR IFNULL(Tgt.Description,                               '') <> IFNULL(Src.Description,              '')
         OR IFNULL(Tgt.ExtendedDescription,                       '') <> IFNULL(Src.ExtendedDescription,     '')
         OR IFNULL(CAST(Tgt.ShowToCustomer AS STRING),            '') <> IFNULL(Src.ShowToCustomer,          '')
         OR IFNULL(CAST(Tgt.Misdirected AS STRING),               '') <> IFNULL(Src.Misdirected,             '')
         OR IFNULL(CAST(Tgt.LeftByCF AS STRING),                  '') <> IFNULL(Src.LeftByCF,                '')
         OR IFNULL(CAST(Tgt.Undeliverable AS STRING),             '') <> IFNULL(Src.Undeliverable,           '')
         OR IFNULL(CAST(Tgt.CageScan AS STRING),                  '') <> IFNULL(Src.CageScan,                '')
         OR IFNULL(CAST(Tgt.BBForceToTScan AS STRING),            '') <> IFNULL(Src.BBForceToTScan,          '')
         OR IFNULL(CAST(Tgt.DontSendToBB AS STRING),              '') <> IFNULL(Src.DontSendToBB,            '')
         OR IFNULL(CAST(Tgt.CanSelectInRunsheetScanning AS STRING),'') <> IFNULL(Src.CanSelectInRunsheetScanning,'')
         OR IFNULL(CAST(Tgt.HeaderGroup AS STRING),               '') <> IFNULL(Src.HeaderGroup,             '')
         OR IFNULL(CAST(Tgt.CFBayScan AS STRING),                 '') <> IFNULL(Src.CFBayScan,               '')
         OR IFNULL(CAST(Tgt.ContainerScan AS STRING),             '') <> IFNULL(Src.ContainerScan,           '')
         OR IFNULL(CAST(Tgt.Active AS STRING),                    '') <> IFNULL(Src.Active,                  '')
         OR IFNULL(CAST(Tgt.ForcedScanType AS STRING),            '') <> IFNULL(Src.ForcedScanType,          '')
         OR IFNULL(CAST(Tgt.ExcludeFromMFYBilling AS STRING),     '') <> IFNULL(Src.ExcludeFromMFYBilling,   '')
         OR IFNULL(CAST(Tgt.ImpactStatus AS STRING),              '') <> IFNULL(Src.ImpactStatus,            '')
         OR IFNULL(CAST(Tgt.Pickup AS STRING),                    '') <> IFNULL(Src.Pickup,                  '')
         OR IFNULL(CAST(Tgt.PickupRF AS STRING),                  '') <> IFNULL(Src.PickupRF,                '')
         OR IFNULL(CAST(Tgt.DeliveryRF AS STRING),                '') <> IFNULL(Src.DeliveryRF,              '')
         OR IFNULL(CAST(Tgt.Delivered AS STRING),                 '') <> IFNULL(Src.Delivered,               '')
         OR IFNULL(CAST(Tgt.PrePickup AS STRING),                 '') <> IFNULL(Src.PrePickup,               '')
         OR IFNULL(CAST(Tgt.Problem AS STRING),                   '') <> IFNULL(Src.Problem,                 '')
         OR IFNULL(CAST(Tgt.AttemptedDelivery AS STRING),         '') <> IFNULL(Src.AttemptedDelivery,       '')
         OR IFNULL(CAST(Tgt.CollectionRequired AS STRING),        '') <> IFNULL(Src.CollectionRequired,      '')
         OR IFNULL(CAST(Tgt.Onforward AS STRING),                 '') <> IFNULL(Src.Onforward,               '')
         OR IFNULL(CAST(Tgt.Delayed AS STRING),                   '') <> IFNULL(Src.Delayed,                 '')
         OR IFNULL(CAST(Tgt.ReadyToCollect AS STRING),            '') <> IFNULL(Src.ReadyToCollect,          '')
        )
        THEN UPDATE SET
            IsCurrent = 0,
            ValidTo   = Loaded;

        SET Updated = @@ROW_COUNT;

        -- -----------------------------------------------------------------------
        -- STEP 2: Insert new rows for unmatched source records.
        -- SELECT DISTINCT replaced with ROW_NUMBER() dedup subquery because
        -- BigQuery cannot use DISTINCT to deduplicate BYTES columns (ScanStatus_HSK).
        -- CURRENT_DATETIME(), CAST(ProcessID), CAST(RecordSource) and inlined
        -- DATETIME literals used to avoid NULL from procedure variable resolution.
        -- -----------------------------------------------------------------------
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_ScanStatus`
        (
            ScanStatus_HSK,
            CountryName,
            ScanStatus,
            Description,
            ExtendedDescription,
            ShowToCustomer,
            Misdirected,
            LeftByCF,
            Undeliverable,
            CageScan,
            BBForceToTScan,
            DontSendToBB,
            CanSelectInRunsheetScanning,
            HeaderGroup,
            CFBayScan,
            ContainerScan,
            Active,
            ForcedScanType,
            ExcludeFromMFYBilling,
            ImpactStatus,
            Pickup,
            PickupRF,
            DeliveryRF,
            Delivered,
            PrePickup,
            Problem,
            AttemptedDelivery,
            CollectionRequired,
            Onforward,
            Delayed,
            ReadyToCollect,
            Loaded,
            ProcessId,
            RecordSource,
            ValidFrom,
            ValidTo,
            IsCurrent
        )
        SELECT
            hsk                             AS ScanStatus_HSK,
            CountryName,
            StatusCode                      AS ScanStatus,
            Description,
            ExtendedDescription,
            ShowToCustomer,
            Misdirected,
            LeftByCF,
            Undeliverable,
            CageScan,
            BBForceToTScan,
            DontSendToBB,
            CanSelectInRunsheetScanning,
            HeaderGroup,
            CFBayScan,
            ContainerScan,
            Active,
            ForcedScanType,
            ExcludeFromMFYBilling,
            ImpactStatus,
            Pickup,
            PickupRF,
            DeliveryRF,
            Delivered,
            PrePickup,
            Problem,
            AttemptedDelivery,
            CollectionRequired,
            Onforward,
            Delayed,
            ReadyToCollect,
            CURRENT_DATETIME()              AS Loaded,
            CAST(ProcessID AS INT64)        AS ProcessId,
            CAST(RecordSource AS STRING)    AS RecordSource,
            DATETIME '1900-01-01 00:00:00'  AS ValidFrom,
            DATETIME '9999-12-31 00:00:00'  AS ValidTo,
            1                               AS IsCurrent
        FROM (
            SELECT
                IFNULL(
                    Sat.ScanStatus_HSK,
                    MD5(IF(Stg.CountryName IS NULL, 'Unknown', TRIM(Stg.CountryName)) || '^' || CAST(Stg.StatusCode AS STRING))
                )                               AS hsk,
                IF(Stg.CountryName IS NULL, 'Unknown', TRIM(Stg.CountryName)) AS CountryName,
                Stg.StatusCode,
                TRIM(Stg.Description)           AS Description,
                TRIM(Stg.ExtendedDescription)   AS ExtendedDescription,
                Stg.ShowToCustomer,
                Stg.Misdirected,
                Stg.LeftByCF,
                Stg.Undeliverable,
                Stg.CageScan,
                Stg.BBForceToTScan,
                Stg.DontSendToBB,
                Stg.CanSelectInRunsheetScanning,
                Stg.HeaderGroup,
                Stg.CFBayScan,
                Stg.ContainerScan,
                Stg.Active,
                Stg.ForcedScanType,
                Stg.ExcludeFromMFYBilling,
                Stg.ImpactStatus,
                Stg.Pickup,
                Stg.PickupRF,
                Stg.DeliveryRF,
                Stg.Delivered,
                Stg.PrePickup,
                Stg.Problem,
                Stg.AttemptedDelivery,
                Stg.CollectionRequired,
                Stg.Onforward,
                Stg.Delayed,
                Stg.ReadyToCollect,
                ROW_NUMBER() OVER (
                    PARTITION BY IFNULL(
                        Sat.ScanStatus_HSK,
                        MD5(IF(Stg.CountryName IS NULL, 'Unknown', TRIM(Stg.CountryName)) || '^' || CAST(Stg.StatusCode AS STRING))
                    )
                    ORDER BY Stg.StatusCode
                ) AS rn
            FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_ScanStatus_Stg` Stg
            LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_ScanStatus` Sat
                ON  Sat.CountryName = Stg.CountryName
                AND Sat.ScanStatus  = CAST(Stg.StatusCode AS STRING)
            WHERE NOT EXISTS (
                SELECT 1
                FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_ScanStatus` AS Tgt
                WHERE Tgt.ScanStatus_HSK = IFNULL(
                        Sat.ScanStatus_HSK,
                        MD5(IF(Stg.CountryName IS NULL, 'Unknown', TRIM(Stg.CountryName)) || '^' || CAST(Stg.StatusCode AS STRING))
                    )
                  AND Tgt.IsCurrent = 1
            )
        )
        WHERE rn = 1;

        SET Inserted = @@ROW_COUNT;
        SET Result   = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed';
        SET ErrorMessage = @@error.message;

    END;

    -- -----------------------------------------------------------------------
    -- Audit counts: original queries SAT_Product (preserved as-is per original)
    -- -----------------------------------------------------------------------
    SET Updated = (
        SELECT IFNULL(COUNTIF(IsCurrent = 0), 0)
        FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Product`
        WHERE ProcessId = ProcessID
    );
    SET Inserted = (
        SELECT IFNULL(COUNTIF(IsCurrent = 1), 0)
        FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Product`
        WHERE ProcessId = ProcessID
    );

    SET Ended = CURRENT_DATETIME();
    CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
        Component,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted,
        Updated,
        -1
    );

END;