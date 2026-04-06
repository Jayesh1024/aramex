-- ==========================================================================================
-- Routine:     BQ_Load_SAT_ScanStatus
-- Description: Loads attributes into SAT_ScanStatus
--              BigQuery compatible version of Load_SAT_ScanStatus
--              Note: MERGE with OUTPUT $action not supported in BQ.
--                    Replaced with:
--                      1. MERGE to expire changed current rows (IsCurrent=0, ValidTo=Loaded)
--                      2. INSERT new rows (IsCurrent=1)
--                    Audit table format preserved exactly.
--                    PIVOT replaced with conditional aggregation against SAT_Product
--                      (matches original which queries SAT_Product, not SAT_ScanStatus).
--                    dbo.GetHashKey replaced with TO_HEX(MD5(...)).
-- Example:     CALL dv.BQ_Load_SAT_ScanStatus(190, 'Fastway')
-- History:
--  15/10/2018  P. Waldron      Routine Written
--  29/07/2021  B. Woods        Added column Active
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE dv.BQ_Load_SAT_ScanStatus(
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
        -- -----------------------------------------------------------------------
        MERGE dv.SAT_ScanStatus AS Tgt
        USING (
            SELECT DISTINCT
                Sat.ScanStatus_HSK,
                IF(Stg.CountryName IS NULL, 'Unknown', TRIM(Stg.CountryName)) AS CountryName,
                Stg.StatusCode          AS ScanStatus,
                TRIM(Stg.Description)   AS Description,
                TRIM(Stg.ExtendedDescription) AS ExtendedDescription,
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
                Stg.ReadyToCollect
            FROM Staging.ScanStatus_Stg Stg
            LEFT JOIN dv.SAT_ScanStatus Sat
                ON  Sat.CountryName = Stg.CountryName
                AND Sat.ScanStatus  = Stg.StatusCode
        ) AS Src
        ON  Tgt.ScanStatus_HSK = Src.ScanStatus_HSK
        AND Tgt.IsCurrent      = 1
        WHEN MATCHED AND (
            -- Replicate EXCEPT change detection
            IFNULL(Tgt.CountryName,                     '') <> IFNULL(Src.CountryName,                     '')
         OR IFNULL(Tgt.ScanStatus,                      '') <> IFNULL(Src.ScanStatus,                      '')
         OR IFNULL(Tgt.Description,                     '') <> IFNULL(Src.Description,                     '')
         OR IFNULL(Tgt.ExtendedDescription,             '') <> IFNULL(Src.ExtendedDescription,             '')
         OR IFNULL(CAST(Tgt.ShowToCustomer AS STRING),   '') <> IFNULL(CAST(Src.ShowToCustomer AS STRING),   '')
         OR IFNULL(CAST(Tgt.Misdirected AS STRING),      '') <> IFNULL(CAST(Src.Misdirected AS STRING),      '')
         OR IFNULL(CAST(Tgt.LeftByCF AS STRING),         '') <> IFNULL(CAST(Src.LeftByCF AS STRING),         '')
         OR IFNULL(CAST(Tgt.Undeliverable AS STRING),    '') <> IFNULL(CAST(Src.Undeliverable AS STRING),    '')
         OR IFNULL(CAST(Tgt.CageScan AS STRING),         '') <> IFNULL(CAST(Src.CageScan AS STRING),         '')
         OR IFNULL(CAST(Tgt.BBForceToTScan AS STRING),   '') <> IFNULL(CAST(Src.BBForceToTScan AS STRING),   '')
         OR IFNULL(CAST(Tgt.DontSendToBB AS STRING),     '') <> IFNULL(CAST(Src.DontSendToBB AS STRING),     '')
         OR IFNULL(CAST(Tgt.CanSelectInRunsheetScanning AS STRING), '') <> IFNULL(CAST(Src.CanSelectInRunsheetScanning AS STRING), '')
         OR IFNULL(Tgt.HeaderGroup,                     '') <> IFNULL(Src.HeaderGroup,                     '')
         OR IFNULL(CAST(Tgt.CFBayScan AS STRING),        '') <> IFNULL(CAST(Src.CFBayScan AS STRING),        '')
         OR IFNULL(CAST(Tgt.ContainerScan AS STRING),    '') <> IFNULL(CAST(Src.ContainerScan AS STRING),    '')
         OR IFNULL(CAST(Tgt.Active AS STRING),           '') <> IFNULL(CAST(Src.Active AS STRING),           '')
         OR IFNULL(Tgt.ForcedScanType,                  '') <> IFNULL(Src.ForcedScanType,                  '')
         OR IFNULL(CAST(Tgt.ExcludeFromMFYBilling AS STRING), '') <> IFNULL(CAST(Src.ExcludeFromMFYBilling AS STRING), '')
         OR IFNULL(Tgt.ImpactStatus,                    '') <> IFNULL(Src.ImpactStatus,                    '')
         OR IFNULL(CAST(Tgt.Pickup AS STRING),           '') <> IFNULL(CAST(Src.Pickup AS STRING),           '')
         OR IFNULL(CAST(Tgt.PickupRF AS STRING),         '') <> IFNULL(CAST(Src.PickupRF AS STRING),         '')
         OR IFNULL(CAST(Tgt.DeliveryRF AS STRING),       '') <> IFNULL(CAST(Src.DeliveryRF AS STRING),       '')
         OR IFNULL(CAST(Tgt.Delivered AS STRING),        '') <> IFNULL(CAST(Src.Delivered AS STRING),        '')
         OR IFNULL(CAST(Tgt.PrePickup AS STRING),        '') <> IFNULL(CAST(Src.PrePickup AS STRING),        '')
         OR IFNULL(CAST(Tgt.Problem AS STRING),          '') <> IFNULL(CAST(Src.Problem AS STRING),          '')
         OR IFNULL(CAST(Tgt.AttemptedDelivery AS STRING),'') <> IFNULL(CAST(Src.AttemptedDelivery AS STRING),'')
         OR IFNULL(CAST(Tgt.CollectionRequired AS STRING),'') <> IFNULL(CAST(Src.CollectionRequired AS STRING),'')
         OR IFNULL(CAST(Tgt.Onforward AS STRING),        '') <> IFNULL(CAST(Src.Onforward AS STRING),        '')
         OR IFNULL(CAST(Tgt.Delayed AS STRING),          '') <> IFNULL(CAST(Src.Delayed AS STRING),          '')
         OR IFNULL(CAST(Tgt.ReadyToCollect AS STRING),   '') <> IFNULL(CAST(Src.ReadyToCollect AS STRING),   '')
        )
        THEN UPDATE SET
            IsCurrent = 0,
            ValidTo   = Loaded;

        SET Updated = @@ROW_COUNT;

        -- -----------------------------------------------------------------------
        -- STEP 2: Insert new rows for unmatched source records
        -- -----------------------------------------------------------------------
        INSERT INTO dv.SAT_ScanStatus
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
        SELECT DISTINCT
            IFNULL(
                Sat.ScanStatus_HSK,
                TO_HEX(MD5(IF(Stg.CountryName IS NULL, 'Unknown', TRIM(Stg.CountryName)) || '^' || Stg.StatusCode))
            )                           AS ScanStatus_HSK,
            IF(Stg.CountryName IS NULL, 'Unknown', TRIM(Stg.CountryName)) AS CountryName,
            Stg.StatusCode              AS ScanStatus,
            TRIM(Stg.Description)       AS Description,
            TRIM(Stg.ExtendedDescription) AS ExtendedDescription,
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
            Loaded          AS Loaded,
            ProcessID       AS ProcessId,
            RecordSource,
            DefaultValidFrom AS ValidFrom,
            DefaultValidTo  AS ValidTo,
            1               AS IsCurrent
        FROM Staging.ScanStatus_Stg Stg
        LEFT JOIN dv.SAT_ScanStatus Sat
            ON  Sat.CountryName = Stg.CountryName
            AND Sat.ScanStatus  = Stg.StatusCode
        WHERE NOT EXISTS (
            SELECT 1
            FROM dv.SAT_ScanStatus AS Tgt
            WHERE Tgt.ScanStatus_HSK = IFNULL(
                    Sat.ScanStatus_HSK,
                    TO_HEX(MD5(IF(Stg.CountryName IS NULL, 'Unknown', TRIM(Stg.CountryName)) || '^' || Stg.StatusCode))
                )
              AND Tgt.IsCurrent = 1
        );

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
        FROM dv.SAT_Product
        WHERE ProcessId = ProcessID
    );
    SET Inserted = (
        SELECT IFNULL(COUNTIF(IsCurrent = 1), 0)
        FROM dv.SAT_Product
        WHERE ProcessId = ProcessID
    );

    SET Ended = CURRENT_DATETIME();
    CALL Staging.SaveLog(
        Component,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted,
        Updated
    );

END;
