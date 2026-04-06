-- ==========================================================================================
-- Routine:     BQ_Load_Fact_KPI_Daily
-- Description: Maintains the stats for InterBranch Pickup & Delivery KPIs
--              BigQuery compatible version of dbo.Load_Fact_KPI_Daily
--              Note:
--                - #LabelsToProcess2 temp table → BQ session temp table
--                - WHILE batch loops for both UPDATES and INSERTS removed
--                - UPDATE...FROM replaced with MERGE (BQ requires MERGE for UPDATE with JOIN)
--                - EXIST(...EXCEPT...) change detection preserved using EXCEPT DISTINCT
--                - OFFSET...FETCH FIRST...ROWS ONLY (correlated subqueries for KPI dates)
--                  preserved — BQ supports this syntax
--                - Convert(Date, x) → DATE(x)
--                - IIF → IF; ISNULL → IFNULL; COALESCE preserved
--                - WAITFOR DELAY removed
--                - RAISERROR removed
--                - GOTO RESULT → EXCEPTION block
--                - DATETIME2(3)/DATETIME → DATETIME
--                - Audit table format preserved exactly.
-- Example:     CALL dbo.BQ_Load_Fact_KPI_Daily(2574)
-- History:
--  03/12/2022  B. Woods        Routine Written
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE dbo.BQ_Load_Fact_KPI_Daily(
    IN ProcessID INT64
)
BEGIN

    DECLARE Loaded          DATETIME DEFAULT CURRENT_DATETIME();
    -- Sentinel date values preserved
    DECLARE FutureDate      DATETIME DEFAULT DATETIME '2999-12-31 00:00:00';
    DECLARE EarlyDate       DATETIME DEFAULT DATETIME '1900-01-01 00:00:00';

    DECLARE Component    STRING DEFAULT 'Load_Fact_KPI_Daily';
    DECLARE SubComponent STRING;
    DECLARE Step         STRING;
    DECLARE Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING;
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64 DEFAULT 0;
    DECLARE Updated      INT64 DEFAULT 0;

    /*
        Get list of LabelNos to Update or Insert rows on dbo.Fact_KPI_Daily
    */
    SET Step    = 'Temp Table';
    SET Started = CURRENT_DATETIME();

    BEGIN

        -- #LabelsToProcess2 → BQ session temp table; IF replaces IIF
        CREATE TEMP TABLE LabelsToProcess2 AS
        SELECT
            stg.LabelNo,
            IF(tgt.LabelNo = stg.LabelNo,
               ROW_NUMBER() OVER(PARTITION BY IF(tgt.LabelNo = stg.LabelNo, 1, NULL) ORDER BY stg.LabelNo),
               NULL) AS UpdateId,
            IF(tgt.LabelNo IS NULL,
               ROW_NUMBER() OVER(PARTITION BY IF(tgt.LabelNo IS NULL, 1, NULL) ORDER BY stg.LabelNo),
               NULL) AS InsertId
        FROM Staging.Fact_KPI_Stg AS stg
        LEFT JOIN dbo.Fact_KPI_Daily AS tgt ON tgt.LabelNo = stg.LabelNo;

        -- Record interim results
        SET Ended        = CURRENT_DATETIME();
        SET SubComponent = Component || ' (' || Step || ')';

        CALL Staging.SaveLog(
            SubComponent,
            ProcessID,
            Started,
            Ended,
            'Success',
            ErrorMessage,
            (SELECT IFNULL(MAX(InsertId), 0) FROM LabelsToProcess2),
            (SELECT IFNULL(MAX(UpdateId), 0) FROM LabelsToProcess2)
        );

        /*
            Update existing Labels
            WHILE batch loop removed. UPDATE...FROM replaced with MERGE.
            EXIST(...EXCEPT...) change detection preserved using EXCEPT DISTINCT.
            OFFSET...FETCH for KPI date lookups preserved (BQ supports it).
        */
        SET Step    = 'Updates';
        SET Started = CURRENT_DATETIME();
        SET Loaded  = CURRENT_DATETIME();

        MERGE dbo.Fact_KPI_Daily AS Tgt2
        USING (
            SELECT
                Tgt.LabelNo,
                Tgt.CountryCode,
                Tgt.Category,
                Tgt.CreatedOn,
                Tgt.ServiceType,
                Tgt.RealisedDate,
                Tgt.FromRf,
                Tgt.ToRf,
                Tgt.SLA,
                Tgt.KPIPickup,
                Tgt.KPILEA,
                Tgt.KPIDelivery,
                Tgt.KPIPickupImpact,
                Tgt.KPILEAImpact,
                Tgt.KPIDeliveryImpact,
                Tgt.DueDate,
                Tgt.KPIDepartureDate,
                Tgt.KPIArrivalDate,
                Tgt.KPIAttemptedDate,
                Tgt.KPIAttemptedDateAdjust,
                -- IIF → IF; Convert(Date,x) → DATE(x)
                IF(ActualDepartureFlag = 'T', Tgt.ActualDepartureDate,   Src.ActualDepartureDate)   AS ActualDepartureDate,
                IF(ActualDepartureFlag = 'T', Tgt.ActualDepartureRF,     Src.ActualDepartureRF)     AS ActualDepartureRF,
                IF(ActualDepartureFlag = 'T', Tgt.ActualDepartureCF,     Src.ActualDepartureCF)     AS ActualDepartureCF,
                IF(ActualDepartureFlag = 'T', Tgt.ActualDepartureType,   Src.ActualDepartureType)   AS ActualDepartureType,
                IF(ActualDepartureFlag = 'T', Tgt.ActualDepartureStatus, Src.ActualDepartureStatus) AS ActualDepartureStatus,
                IF(ActualFirstArrivalFlag = 'T', Tgt.ActualFirstArrivalDate,   Src.ActualFirstArrivalDate)   AS ActualFirstArrivalDate,
                IF(ActualFirstArrivalFlag = 'T', Tgt.ActualFirstArrivalRF,     Src.ActualFirstArrivalRF)     AS ActualFirstArrivalRF,
                IF(ActualFirstArrivalFlag = 'T', Tgt.ActualFirstArrivalCF,     Src.ActualFirstArrivalCF)     AS ActualFirstArrivalCF,
                IF(ActualFirstArrivalFlag = 'T', Tgt.ActualFirstArrivalType,   Src.ActualFirstArrivalType)   AS ActualFirstArrivalType,
                IF(ActualFirstArrivalFlag = 'T', Tgt.ActualFirstArrivalStatus, Src.ActualFirstArrivalStatus) AS ActualFirstArrivalStatus,
                IF(ActualArrivalFlag = 'T', Tgt.ActualArrivalDate,   Src.ActualArrivalDate)   AS ActualArrivalDate,
                IF(ActualArrivalFlag = 'T', Tgt.ActualArrivalRF,     Src.ActualArrivalRF)     AS ActualArrivalRF,
                IF(ActualArrivalFlag = 'T', Tgt.ActualArrivalCF,     Src.ActualArrivalCF)     AS ActualArrivalCF,
                IF(ActualArrivalFlag = 'T', Tgt.ActualArrivalType,   Src.ActualArrivalType)   AS ActualArrivalType,
                IF(ActualArrivalFlag = 'T', Tgt.ActualArrivalStatus, Src.ActualArrivalStatus) AS ActualArrivalStatus,
                IF(ActualAttemptedFlag = 'T', Tgt.ActualAttemptedDate,   Src.ActualAttemptedDate)   AS ActualAttemptedDate,
                IF(ActualAttemptedFlag = 'T', Tgt.ActualAttemptedRF,     Src.ActualAttemptedRF)     AS ActualAttemptedRF,
                IF(ActualAttemptedFlag = 'T', Tgt.ActualAttemptedCF,     Src.ActualAttemptedCF)     AS ActualAttemptedCF,
                IF(ActualAttemptedFlag = 'T', Tgt.ActualAttemptedType,   Src.ActualAttemptedType)   AS ActualAttemptedType,
                IF(ActualAttemptedFlag = 'T', Tgt.ActualAttemptedStatus, Src.ActualAttemptedStatus) AS ActualAttemptedStatus,
                IF(ActualDeliveryFlag = 'T', Tgt.ActualDeliveryScanDate, Src.ActualDeliveryScanDate) AS ActualDeliveryScanDate,
                IF(ActualDeliveryFlag = 'T', Tgt.ActualDeliveryRF,       Src.ActualDeliveryRF)       AS ActualDeliveryRF,
                IF(ActualDeliveryFlag = 'T', Tgt.ActualDeliveryCF,       Src.ActualDeliveryCF)       AS ActualDeliveryCF,
                IF(ActualDeliveryFlag = 'T', Tgt.ActualDeliveryType,     Src.ActualDeliveryType)     AS ActualDeliveryType,
                IF(ActualDeliveryFlag = 'T', Tgt.ActualDeliveryStatus,   Src.ActualDeliveryStatus)   AS ActualDeliveryStatus,
                IF(LastScanFlag = 'T', Tgt.LastScanDate,   Src.LastScanDate)   AS LastScanDate,
                IF(LastScanFlag = 'T', Tgt.LastScanRF,     Src.LastScanRF)     AS LastScanRF,
                IF(LastScanFlag = 'T', Tgt.LastScanCF,     Src.LastScanCF)     AS LastScanCF,
                IF(LastScanFlag = 'T', Tgt.LastScanType,   Src.LastScanType)   AS LastScanType,
                IF(LastScanFlag = 'T', Tgt.LastScanStatus, Src.LastScanStatus) AS LastScanStatus,
                COALESCE(Src.MISScanDate, Tgt.MISScanDate) AS MISScanDate,
                COALESCE(Src.MISRF,       Tgt.MISRF)       AS MISRF
            FROM (
                SELECT
                    COALESCE(Src.LabelNo,      Tgt.LabelNo)      AS LabelNo,
                    COALESCE(Src.CountryCode,  Tgt.CountryCode)  AS CountryCode,
                    COALESCE(Src.Category,     Tgt.Category)     AS Category,
                    COALESCE(Src.ServiceType,  Tgt.ServiceType)  AS ServiceType,
                    Src.CreatedOn,
                    Src.RealisedDate,
                    Src.FromRf,
                    Src.ToRf,
                    COALESCE(Src.SLA,                    Tgt.SLA)                    AS SLA,
                    COALESCE(Src.KPIPickup,              Tgt.KPIPickup)              AS KPIPickup,
                    COALESCE(Src.KPILEA,                 Tgt.KPILEA)                 AS KPILEA,
                    COALESCE(Src.KPIDelivery,            Tgt.KPIDelivery)            AS KPIDelivery,
                    COALESCE(Src.KPIPickupImpact,        Tgt.KPIPickupImpact)        AS KPIPickupImpact,
                    COALESCE(Src.KPILEAImpact,           Tgt.KPILEAImpact)           AS KPILEAImpact,
                    COALESCE(Src.KPIDeliveryImpact,      Tgt.KPIDeliveryImpact)      AS KPIDeliveryImpact,
                    COALESCE(Src.DueDate,                Tgt.DueDate)                AS DueDate,
                    COALESCE(Src.KPIDepartureDate,       Tgt.KPIDepartureDate)       AS KPIDepartureDate,
                    COALESCE(Src.KPIArrivalDate,         Tgt.KPIArrivalDate)         AS KPIArrivalDate,
                    COALESCE(Src.KPIAttemptedDate,       Tgt.KPIAttemptedDate)       AS KPIAttemptedDate,
                    COALESCE(Src.KPIAttemptedDateAdjust, Tgt.KPIAttemptedDateAdjust) AS KPIAttemptedDateAdjust,
                    -- Departure flag: prefer earlier date from Src; 'S'=use Src, 'T'=keep Tgt
                    IF(COALESCE(Src.ActualDepartureDate, NULL) IS NOT NULL,
                        IF(Src.ActualDepartureDate < COALESCE(Tgt.ActualDepartureDate, FutureDate), 'S', 'T'),
                        'T')                                                        AS ActualDepartureFlag,
                    Tgt.ActualDepartureDate,
                    Tgt.ActualDepartureRF,
                    Tgt.ActualDepartureCF,
                    Tgt.ActualDepartureType,
                    Tgt.ActualDepartureStatus,
                    IF(COALESCE(Src.ActualFirstArrivalDate, NULL) IS NOT NULL,
                        IF(Src.ActualFirstArrivalDate < COALESCE(Tgt.ActualFirstArrivalDate, FutureDate), 'S', 'T'),
                        'T')                                                        AS ActualFirstArrivalFlag,
                    Tgt.ActualFirstArrivalDate,
                    Tgt.ActualFirstArrivalRF,
                    Tgt.ActualFirstArrivalCF,
                    Tgt.ActualFirstArrivalType,
                    Tgt.ActualFirstArrivalStatus,
                    IF(COALESCE(Src.ActualArrivalDate, NULL) IS NOT NULL,
                        IF(Src.ActualArrivalDate < COALESCE(Tgt.ActualArrivalDate, FutureDate), 'S', 'T'),
                        'T')                                                        AS ActualArrivalFlag,
                    Tgt.ActualArrivalDate,
                    Tgt.ActualArrivalRF,
                    Tgt.ActualArrivalCF,
                    Tgt.ActualArrivalType,
                    Tgt.ActualArrivalStatus,
                    IF(COALESCE(Src.ActualAttemptedDate, NULL) IS NOT NULL,
                        IF(Src.ActualAttemptedDate < COALESCE(Tgt.ActualAttemptedDate, FutureDate), 'S', 'T'),
                        'T')                                                        AS ActualAttemptedFlag,
                    Tgt.ActualAttemptedDate,
                    Tgt.ActualAttemptedRF,
                    Tgt.ActualAttemptedCF,
                    Tgt.ActualAttemptedType,
                    Tgt.ActualAttemptedStatus,
                    IF(COALESCE(Src.ActualDeliveryScanDate, NULL) IS NOT NULL,
                        IF(Src.ActualDeliveryScanDate < COALESCE(Tgt.ActualDeliveryScanDate, FutureDate), 'S', 'T'),
                        'T')                                                        AS ActualDeliveryFlag,
                    Tgt.ActualDeliveryScanDate,
                    Tgt.ActualDeliveryRF,
                    Tgt.ActualDeliveryCF,
                    Tgt.ActualDeliveryType,
                    Tgt.ActualDeliveryStatus,
                    IF(COALESCE(Src.LastScanDate, NULL) IS NOT NULL,
                        IF(Src.LastScanDate > COALESCE(Tgt.LastScanDate, EarlyDate), 'S', 'T'),
                        'T')                                                        AS LastScanFlag,
                    Tgt.LastScanDate,
                    Tgt.LastScanRF,
                    Tgt.LastScanCF,
                    Tgt.LastScanType,
                    Tgt.LastScanStatus,
                    COALESCE(Src.MISScanDate, Tgt.MISScanDate)                      AS MISScanDate,
                    COALESCE(Src.MISRF,       Tgt.MISRF)                            AS MISRF
                FROM dbo.Fact_KPI_Daily Tgt
                JOIN Staging.Fact_KPI_Stg src   ON Src.LabelNo = Tgt.LabelNo
                JOIN LabelsToProcess2 sel        ON sel.LabelNo = Src.LabelNo
                WHERE sel.UpdateId IS NOT NULL
                  AND EXISTS (
                    SELECT
                        Src.Category,         Src.ServiceType,      Src.CreatedOn,
                        Src.RealisedDate,     Src.SLA,              Src.KPIPickup,
                        Src.KPILEA,           Src.KPIDelivery,      Src.KPIPickupImpact,
                        Src.KPILEAImpact,     Src.KPIDeliveryImpact,Src.DueDate,
                        Src.KPIDepartureDate, Src.KPIArrivalDate,   Src.KPIAttemptedDate,
                        Src.KPIAttemptedDateAdjust,
                        Src.ActualDepartureDate,    Src.ActualDepartureRF,    Src.ActualDepartureCF,
                        Src.ActualDepartureType,    Src.ActualDepartureStatus,
                        Src.ActualFirstArrivalDate, Src.ActualFirstArrivalRF, Src.ActualFirstArrivalCF,
                        Src.ActualFirstArrivalType, Src.ActualFirstArrivalStatus,
                        Src.ActualArrivalDate,      Src.ActualArrivalRF,      Src.ActualArrivalCF,
                        Src.ActualArrivalType,      Src.ActualArrivalStatus,
                        Src.ActualAttemptedDate,    Src.ActualAttemptedRF,    Src.ActualAttemptedCF,
                        Src.ActualAttemptedType,    Src.ActualAttemptedStatus,
                        Src.ActualDeliveryScanDate, Src.ActualDeliveryRF,     Src.ActualDeliveryCF,
                        Src.ActualDeliveryType,     Src.ActualDeliveryStatus,
                        Src.LastScanDate,  Src.LastScanRF,  Src.LastScanCF,
                        Src.LastScanType,  Src.LastScanStatus,
                        Src.MISScanDate,   Src.MISRF
                    EXCEPT DISTINCT
                    SELECT
                        Tgt.Category,         Tgt.ServiceType,      Tgt.CreatedOn,
                        Tgt.RealisedDate,     Tgt.SLA,              Tgt.KPIPickup,
                        Tgt.KPILEA,           Tgt.KPIDelivery,      Tgt.KPIPickupImpact,
                        Tgt.KPILEAImpact,     Tgt.KPIDeliveryImpact,Tgt.DueDate,
                        Tgt.KPIDepartureDate, Tgt.KPIArrivalDate,   Tgt.KPIAttemptedDate,
                        Tgt.KPIAttemptedDateAdjust,
                        Tgt.ActualDepartureDate,    Tgt.ActualDepartureRF,    Tgt.ActualDepartureCF,
                        Tgt.ActualDepartureType,    Tgt.ActualDepartureStatus,
                        Tgt.ActualFirstArrivalDate, Tgt.ActualFirstArrivalRF, Tgt.ActualFirstArrivalCF,
                        Tgt.ActualFirstArrivalType, Tgt.ActualFirstArrivalStatus,
                        Tgt.ActualArrivalDate,      Tgt.ActualArrivalRF,      Tgt.ActualArrivalCF,
                        Tgt.ActualArrivalType,      Tgt.ActualArrivalStatus,
                        Tgt.ActualAttemptedDate,    Tgt.ActualAttemptedRF,    Tgt.ActualAttemptedCF,
                        Tgt.ActualAttemptedType,    Tgt.ActualAttemptedStatus,
                        Tgt.ActualDeliveryScanDate, Tgt.ActualDeliveryRF,     Tgt.ActualDeliveryCF,
                        Tgt.ActualDeliveryType,     Tgt.ActualDeliveryStatus,
                        Tgt.LastScanDate,  Tgt.LastScanRF,  Tgt.LastScanCF,
                        Tgt.LastScanType,  Tgt.LastScanStatus,
                        Tgt.MISScanDate,   Tgt.MISRF
                )
            ) Tgt
            JOIN Staging.Fact_KPI_Stg src ON Src.LabelNo = Tgt.LabelNo
        ) AS Src_Final
        ON Tgt2.LabelNo = Src_Final.LabelNo
        WHEN MATCHED THEN UPDATE SET
            LabelNo                 = Src_Final.LabelNo,
            CountryCode             = Src_Final.CountryCode,
            Category                = Src_Final.Category,
            RealisedDate            = Src_Final.RealisedDate,
            CreatedOn               = Src_Final.CreatedOn,
            ServiceType             = Src_Final.ServiceType,
            SLA                     = Src_Final.SLA,
            KPIPickup               = Src_Final.KPIPickup,
            KPILEA                  = Src_Final.KPILEA,
            KPIDelivery             = Src_Final.KPIDelivery,
            KPIPickupImpact         = Src_Final.KPIPickupImpact,
            KPILEAImpact            = Src_Final.KPILEAImpact,
            KPIDeliveryImpact       = Src_Final.KPIDeliveryImpact,
            DueDate                 = Src_Final.DueDate,
            KPIDepartureDate        = Src_Final.KPIDepartureDate,
            -- OFFSET...FETCH FIRST 1 ROWS ONLY preserved for KPI date lookups (BQ supports this)
            -- Convert(Date,x) → DATE(x)
            KPIArrivalDate          = (SELECT Calendar_Date
                FROM Dim_Time
                LEFT JOIN KPIExcludedDates ON Calendar_Date = Date AND Franchise = Src_Final.ToRf
                WHERE Calendar_Date >= DATE(Src_Final.ActualDepartureDate)
                  AND week_day_flag = 'Y' AND Comment IS NULL
                ORDER BY Calendar_Date
                OFFSET COALESCE(Src_Final.KPILEA, 1) ROWS FETCH FIRST 1 ROWS ONLY),
            KPIAttemptedDate        = (SELECT Calendar_Date
                FROM Dim_Time
                LEFT JOIN KPIExcludedDates ON Calendar_Date = Date AND Franchise = Src_Final.ToRf
                WHERE Calendar_Date >= DATE(Src_Final.ActualArrivalDate)
                  AND week_day_flag = 'Y' AND Comment IS NULL
                ORDER BY Calendar_Date
                OFFSET COALESCE(Src_Final.KPIDelivery, 1) ROWS FETCH FIRST 1 ROWS ONLY),
            KPIAttemptedDateAdjust  = (SELECT Calendar_Date
                FROM Dim_Time
                LEFT JOIN KPIExcludedDates ON Calendar_Date = Date AND Franchise = Src_Final.ToRf
                WHERE Calendar_Date >= DATE(Src_Final.ActualDepartureDate)
                  AND week_day_flag = 'Y' AND Comment IS NULL
                ORDER BY Calendar_Date
                OFFSET COALESCE(Src_Final.KPILEA + Src_Final.KPIDelivery, 1) ROWS FETCH FIRST 1 ROWS ONLY),
            ActualDepartureDate     = Src_Final.ActualDepartureDate,
            ActualDepartureRF       = Src_Final.ActualDepartureRF,
            ActualDepartureCF       = Src_Final.ActualDepartureCF,
            ActualDepartureType     = Src_Final.ActualDepartureType,
            ActualDepartureStatus   = Src_Final.ActualDepartureStatus,
            ActualFirstArrivalDate  = Src_Final.ActualFirstArrivalDate,
            ActualFirstArrivalRF    = Src_Final.ActualFirstArrivalRF,
            ActualFirstArrivalCF    = Src_Final.ActualFirstArrivalCF,
            ActualFirstArrivalType  = Src_Final.ActualFirstArrivalType,
            ActualFirstArrivalStatus = Src_Final.ActualFirstArrivalStatus,
            ActualArrivalDate       = Src_Final.ActualArrivalDate,
            ActualArrivalRF         = Src_Final.ActualArrivalRF,
            ActualArrivalCF         = Src_Final.ActualArrivalCF,
            ActualArrivalType       = Src_Final.ActualArrivalType,
            ActualArrivalStatus     = Src_Final.ActualArrivalStatus,
            ActualAttemptedDate     = Src_Final.ActualAttemptedDate,
            ActualAttemptedRF       = Src_Final.ActualAttemptedRF,
            ActualAttemptedCF       = Src_Final.ActualAttemptedCF,
            ActualAttemptedType     = Src_Final.ActualAttemptedType,
            ActualAttemptedStatus   = Src_Final.ActualAttemptedStatus,
            ActualDeliveryScanDate  = Src_Final.ActualDeliveryScanDate,
            ActualDeliveryRF        = Src_Final.ActualDeliveryRF,
            ActualDeliveryCF        = Src_Final.ActualDeliveryCF,
            ActualDeliveryType      = Src_Final.ActualDeliveryType,
            ActualDeliveryStatus    = Src_Final.ActualDeliveryStatus,
            LastScanDate            = Src_Final.LastScanDate,
            LastScanRF              = Src_Final.LastScanRF,
            LastScanCF              = Src_Final.LastScanCF,
            LastScanType            = Src_Final.LastScanType,
            LastScanStatus          = Src_Final.LastScanStatus,
            MISScanDate             = Src_Final.MISScanDate,
            MISRF                   = Src_Final.MISRF,
            LastUpdated             = Loaded,
            ProcessID               = ProcessID;

        SET Updated = @@ROW_COUNT;

        -- Interim SaveLog for Updates step
        SET Ended        = CURRENT_DATETIME();
        SET SubComponent = Component || ' (Updates)';
        CALL Staging.SaveLog(SubComponent, ProcessID, Started, Ended, 'Success', ErrorMessage, Inserted, Updated);

        /*
            Insert new Labels
            WHILE batch loop removed. WITH (TABLOCK) removed.
            OFFSET...FETCH FIRST for KPI date lookups preserved.
            Convert(Date,x) → DATE(x)
        */
        SET Step    = 'Inserts';
        SET Started = CURRENT_DATETIME();
        SET Loaded  = CURRENT_DATETIME();

        INSERT INTO dbo.Fact_KPI_Daily
        (
            LabelNo, CountryCode, Category, CreatedOn, ServiceType, RealisedDate,
            SLA, KPIPickup, KPILEA, KPIDelivery, KPIPickupImpact, KPILEAImpact, KPIDeliveryImpact,
            DueDate, KPIDepartureDate, KPIArrivalDate, KPIAttemptedDate, KPIAttemptedDateAdjust,
            ActualDepartureDate, ActualDepartureRF, ActualDepartureCF, ActualDepartureType, ActualDepartureStatus,
            ActualFirstArrivalDate, ActualFirstArrivalRF, ActualFirstArrivalCF, ActualFirstArrivalType, ActualFirstArrivalStatus,
            ActualArrivalDate, ActualArrivalRF, ActualArrivalCF, ActualArrivalType, ActualArrivalStatus,
            ActualAttemptedDate, ActualAttemptedRF, ActualAttemptedCF, ActualAttemptedType, ActualAttemptedStatus,
            ActualDeliveryScanDate, ActualDeliveryRF, ActualDeliveryCF, ActualDeliveryType, ActualDeliveryStatus,
            LastScanDate, LastScanRF, LastScanCF, LastScanType, LastScanStatus,
            MISScanDate, MISRF, LastUpdated, ProcessID
        )
        SELECT
            Src.LabelNo, Src.CountryCode, Src.Category, Src.CreatedOn, Src.ServiceType, Src.RealisedDate,
            Src.SLA, Src.KPIPickup, Src.KPILEA, Src.KPIDelivery, Src.KPIPickupImpact, Src.KPILEAImpact, Src.KPIDeliveryImpact,
            Src.DueDate, Src.KPIDepartureDate,
            -- OFFSET...FETCH preserved; Convert(Date,x) → DATE(x)
            (SELECT Calendar_Date FROM Dim_Time
             LEFT JOIN KPIExcludedDates ON Calendar_Date = Date AND Franchise = Src.ToRf
             WHERE Calendar_Date >= DATE(Src.ActualDepartureDate) AND week_day_flag = 'Y' AND Comment IS NULL
             ORDER BY Calendar_Date OFFSET COALESCE(Src.KPILEA, 1) ROWS FETCH FIRST 1 ROWS ONLY)   AS KPIArrivalDate,
            (SELECT Calendar_Date FROM Dim_Time
             LEFT JOIN KPIExcludedDates ON Calendar_Date = Date AND Franchise = Src.ToRf
             WHERE Calendar_Date >= DATE(Src.ActualArrivalDate)   AND week_day_flag = 'Y' AND Comment IS NULL
             ORDER BY Calendar_Date OFFSET COALESCE(Src.KPIDelivery, 1) ROWS FETCH FIRST 1 ROWS ONLY) AS KPIAttemptedDate,
            (SELECT Calendar_Date FROM Dim_Time
             LEFT JOIN KPIExcludedDates ON Calendar_Date = Date AND Franchise = Src.ToRf
             WHERE Calendar_Date >= DATE(Src.ActualDepartureDate) AND week_day_flag = 'Y' AND Comment IS NULL
             ORDER BY Calendar_Date OFFSET COALESCE(Src.KPILEA + Src.KPIDelivery, 1) ROWS FETCH FIRST 1 ROWS ONLY) AS KPIAttemptedDateAdjust,
            Src.ActualDepartureDate, Src.ActualDepartureRF, Src.ActualDepartureCF, Src.ActualDepartureType, Src.ActualDepartureStatus,
            Src.ActualFirstArrivalDate, Src.ActualFirstArrivalRF, Src.ActualFirstArrivalCF, Src.ActualFirstArrivalType, Src.ActualFirstArrivalStatus,
            Src.ActualArrivalDate, Src.ActualArrivalRF, Src.ActualArrivalCF, Src.ActualArrivalType, Src.ActualArrivalStatus,
            Src.ActualAttemptedDate, Src.ActualAttemptedRF, Src.ActualAttemptedCF, Src.ActualAttemptedType, Src.ActualAttemptedStatus,
            Src.ActualDeliveryScanDate, Src.ActualDeliveryRF, Src.ActualDeliveryCF, Src.ActualDeliveryType, Src.ActualDeliveryStatus,
            Src.LastScanDate, Src.LastScanRF, Src.LastScanCF, Src.LastScanType, Src.LastScanStatus,
            Src.MISScanDate, Src.MISRF,
            Loaded,
            ProcessID
        FROM Staging.Fact_KPI_Stg Src
        JOIN LabelsToProcess2 Sel ON Sel.LabelNo = Src.LabelNo
        WHERE Sel.InsertId IS NOT NULL;

        SET Inserted = @@ROW_COUNT;
        SET Result   = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed (' || Step || ')';
        SET ErrorMessage = @@error.message;

    END;

    /*
        Record load metrics in log — audit table format preserved exactly
    */
    SET Ended        = CURRENT_DATETIME();
    SET SubComponent = Component || ' (' || Step || ')';

    CALL Staging.SaveLog(
        SubComponent,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted,
        Updated
    );

    DROP TABLE IF EXISTS LabelsToProcess2;

END;
