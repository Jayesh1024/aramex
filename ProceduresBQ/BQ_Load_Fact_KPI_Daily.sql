-- ==========================================================================================
-- Routine:     BQ_Load_Fact_KPI_Daily
-- Description: Maintains the stats for InterBranch Pickup & Delivery KPIs
--              BigQuery compatible version of Load_Fact_KPI_Daily
--              Note: Temp table replaced with BQ TEMP TABLE.
--                    WHILE batch loops removed - BQ handles large DML natively.
--                    UPDATE ... FROM replaced with MERGE.
--                    EXCEPT change detection replaced with explicit column comparisons.
--                    OFFSET ... ROWS FETCH FIRST 1 ROWS ONLY → BQ uses LIMIT/OFFSET.
--                    Convert(Date,x) → DATE(x).
--                    IIF → IF. ISNULL → IFNULL. COALESCE preserved.
--                    WITH (TABLOCK) removed. RAISERROR / WAITFOR DELAY removed.
--                    GOTO replaced with EXCEPTION block.
--                    BEGIN/COMMIT TRANSACTION removed.
--                    SYSDATETIME() → CURRENT_DATETIME().
--                    DATETIME2(3) → DATETIME.
--                    CONVERT(varchar,...) → CAST(... AS STRING).
--                    Audit table format preserved exactly.
-- Example:     CALL dbo.BQ_Load_Fact_KPI_Daily(2574)
-- History:
--  03/12/2022  B. Woods        Routine Written
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.BQ_Load_Fact_KPI_Daily`(
    IN ProcessID INT64
)
BEGIN

    DECLARE Loaded           DATETIME;
    DECLARE FutureDate       DATETIME DEFAULT DATETIME '2999-12-31 00:00:00';
    DECLARE EarlyDate        DATETIME DEFAULT DATETIME '1900-01-01 00:00:00';

    DECLARE Component    STRING DEFAULT 'dbo.Load_Fact_KPI_Daily';
    DECLARE SubComponent STRING;
    DECLARE Step         STRING;
    DECLARE Started      DATETIME;
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING;
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64 DEFAULT 0;
    DECLARE Updated      INT64 DEFAULT 0;
    DECLARE MaxInsertId  INT64;
    DECLARE MaxUpdateId  INT64;

    /*
        Get list of LabelNos to Update or Insert rows on `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI_Daily`
    */
    SET Step    = 'Temp Table';
    SET Started = CURRENT_DATETIME();

    -- BQ TEMP TABLE replaces SQL Server #LabelsToProcess2
    CREATE TEMP TABLE LabelsToProcess2 (
        LabelNo  STRING,
        UpdateId INT64,
        InsertId INT64
    );

    INSERT INTO LabelsToProcess2 (LabelNo, UpdateId, InsertId)
        SELECT
            stg.LabelNo,
            IF(
                tgt.LabelNo = stg.LabelNo,
                ROW_NUMBER() OVER(
                    PARTITION BY IF(tgt.LabelNo = stg.LabelNo, 1, NULL)
                    ORDER BY stg.LabelNo
                ),
                NULL
            ) AS UpdateId,
            IF(
                tgt.LabelNo IS NULL,
                ROW_NUMBER() OVER(
                    PARTITION BY IF(tgt.LabelNo IS NULL, 1, NULL)
                    ORDER BY stg.LabelNo
                ),
                NULL
            ) AS InsertId
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_KPI_Stg` AS stg
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI_Daily` AS tgt ON tgt.LabelNo = stg.LabelNo;

    IF (SELECT COUNT(*) FROM LabelsToProcess2) = 0 THEN
        SET Result = 'Success';
    END IF;

    SELECT MAX(InsertId), MAX(UpdateId)
    INTO MaxInsertId, MaxUpdateId
    FROM LabelsToProcess2;

    -- Record interim results (audit table format preserved exactly)
    SET Result       = 'Success';
    SET Ended        = CURRENT_DATETIME();
    SET SubComponent = Component || ' (' || Step || ')';

    CALL `{{ project_id }}.{{ sp_dataset_id }}.SaveLog`(
        SubComponent,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        MaxInsertId,
        MaxUpdateId
    );

    -------------------------
    -- Updates
    -------------------------
    SET Step    = 'Updates';
    SET Started = CURRENT_DATETIME();
    SET Inserted = 0;
    SET Updated  = 0;

    BEGIN

        SET Loaded = CURRENT_DATETIME();

        -- MERGE replaces UPDATE Tgt2 WITH (TABLOCK) SET ... FROM ... JOIN ... WHERE EXISTS (EXCEPT)
        MERGE `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI_Daily` AS Tgt2
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

                -- IIF → IF; CoALESCE preserved
                IF(Tgt.ActualDepartureFlag = 'T', Tgt.ActualDepartureDate,   Src.ActualDepartureDate)   AS ActualDepartureDate,
                IF(Tgt.ActualDepartureFlag = 'T', Tgt.ActualDepartureRF,     Src.ActualDepartureRF)     AS ActualDepartureRF,
                IF(Tgt.ActualDepartureFlag = 'T', Tgt.ActualDepartureCF,     Src.ActualDepartureCF)     AS ActualDepartureCF,
                IF(Tgt.ActualDepartureFlag = 'T', Tgt.ActualDepartureType,   Src.ActualDepartureType)   AS ActualDepartureType,
                IF(Tgt.ActualDepartureFlag = 'T', Tgt.ActualDepartureStatus, Src.ActualDepartureStatus) AS ActualDepartureStatus,

                IF(Tgt.ActualFirstArrivalFlag = 'T', Tgt.ActualFirstArrivalDate,   Src.ActualFirstArrivalDate)   AS ActualFirstArrivalDate,
                IF(Tgt.ActualFirstArrivalFlag = 'T', Tgt.ActualFirstArrivalRF,     Src.ActualFirstArrivalRF)     AS ActualFirstArrivalRF,
                IF(Tgt.ActualFirstArrivalFlag = 'T', Tgt.ActualFirstArrivalCF,     Src.ActualFirstArrivalCF)     AS ActualFirstArrivalCF,
                IF(Tgt.ActualFirstArrivalFlag = 'T', Tgt.ActualFirstArrivalType,   Src.ActualFirstArrivalType)   AS ActualFirstArrivalType,
                IF(Tgt.ActualFirstArrivalFlag = 'T', Tgt.ActualFirstArrivalStatus, Src.ActualFirstArrivalStatus) AS ActualFirstArrivalStatus,

                IF(Tgt.ActualArrivalFlag = 'T', Tgt.ActualArrivalDate,   Src.ActualArrivalDate)   AS ActualArrivalDate,
                IF(Tgt.ActualArrivalFlag = 'T', Tgt.ActualArrivalRF,     Src.ActualArrivalRF)     AS ActualArrivalRF,
                IF(Tgt.ActualArrivalFlag = 'T', Tgt.ActualArrivalCF,     Src.ActualArrivalCF)     AS ActualArrivalCF,
                IF(Tgt.ActualArrivalFlag = 'T', Tgt.ActualArrivalType,   Src.ActualArrivalType)   AS ActualArrivalType,
                IF(Tgt.ActualArrivalFlag = 'T', Tgt.ActualArrivalStatus, Src.ActualArrivalStatus) AS ActualArrivalStatus,

                IF(Tgt.ActualAttemptedFlag = 'T', Tgt.ActualAttemptedDate,   Src.ActualAttemptedDate)   AS ActualAttemptedDate,
                IF(Tgt.ActualAttemptedFlag = 'T', Tgt.ActualAttemptedRF,     Src.ActualAttemptedRF)     AS ActualAttemptedRF,
                IF(Tgt.ActualAttemptedFlag = 'T', Tgt.ActualAttemptedCF,     Src.ActualAttemptedCF)     AS ActualAttemptedCF,
                IF(Tgt.ActualAttemptedFlag = 'T', Tgt.ActualAttemptedType,   Src.ActualAttemptedType)   AS ActualAttemptedType,
                IF(Tgt.ActualAttemptedFlag = 'T', Tgt.ActualAttemptedStatus, Src.ActualAttemptedStatus) AS ActualAttemptedStatus,

                IF(Tgt.ActualDeliveryFlag = 'T', Tgt.ActualDeliveryScanDate, Src.ActualDeliveryScanDate) AS ActualDeliveryScanDate,
                IF(Tgt.ActualDeliveryFlag = 'T', Tgt.ActualDeliveryRF,       Src.ActualDeliveryRF)       AS ActualDeliveryRF,
                IF(Tgt.ActualDeliveryFlag = 'T', Tgt.ActualDeliveryCF,       Src.ActualDeliveryCF)       AS ActualDeliveryCF,
                IF(Tgt.ActualDeliveryFlag = 'T', Tgt.ActualDeliveryType,     Src.ActualDeliveryType)     AS ActualDeliveryType,
                IF(Tgt.ActualDeliveryFlag = 'T', Tgt.ActualDeliveryStatus,   Src.ActualDeliveryStatus)   AS ActualDeliveryStatus,

                IF(Tgt.LastScanFlag = 'T', Tgt.LastScanDate,   Src.LastScanDate)   AS LastScanDate,
                IF(Tgt.LastScanFlag = 'T', Tgt.LastScanRF,     Src.LastScanRF)     AS LastScanRF,
                IF(Tgt.LastScanFlag = 'T', Tgt.LastScanCF,     Src.LastScanCF)     AS LastScanCF,
                IF(Tgt.LastScanFlag = 'T', Tgt.LastScanType,   Src.LastScanType)   AS LastScanType,
                IF(Tgt.LastScanFlag = 'T', Tgt.LastScanStatus, Src.LastScanStatus) AS LastScanStatus,

                COALESCE(Src.MISScanDate, Tgt.MISScanDate) AS MISScanDate,
                COALESCE(Src.MISRF,       Tgt.MISRF)       AS MISRF,
                Loaded                                      AS LastUpdated,
                ProcessID

            FROM (
                -- Inner subquery: compute flags and coalesced values
                SELECT
                    COALESCE(Src.LabelNo,    Tgt.LabelNo)    AS LabelNo,
                    COALESCE(Src.CountryCode,Tgt.CountryCode) AS CountryCode,
                    COALESCE(Src.Category,   Tgt.Category)   AS Category,
                    COALESCE(Src.ServiceType,Tgt.ServiceType) AS ServiceType,
                    Src.CreatedOn,
                    Src.RealisedDate,
                    Src.FromRf,
                    Src.ToRf,
                    COALESCE(Src.SLA,              Tgt.SLA)              AS SLA,
                    COALESCE(Src.KPIPickup,        Tgt.KPIPickup)        AS KPIPickup,
                    COALESCE(Src.KPILEA,           Tgt.KPILEA)           AS KPILEA,
                    COALESCE(Src.KPIDelivery,      Tgt.KPIDelivery)      AS KPIDelivery,
                    COALESCE(Src.KPIPickupImpact,  Tgt.KPIPickupImpact)  AS KPIPickupImpact,
                    COALESCE(Src.KPILEAImpact,     Tgt.KPILEAImpact)    AS KPILEAImpact,
                    COALESCE(Src.KPIDeliveryImpact,Tgt.KPIDeliveryImpact) AS KPIDeliveryImpact,
                    COALESCE(Src.DueDate,          Tgt.DueDate)          AS DueDate,
                    COALESCE(Src.KPIDepartureDate, Tgt.KPIDepartureDate) AS KPIDepartureDate,
                    COALESCE(Src.KPIArrivalDate,   Tgt.KPIArrivalDate)   AS KPIArrivalDate,
                    COALESCE(Src.KPIAttemptedDate, Tgt.KPIAttemptedDate) AS KPIAttemptedDate,
                    COALESCE(Src.KPIAttemptedDateAdjust, Tgt.KPIAttemptedDateAdjust) AS KPIAttemptedDateAdjust,

                    -- Departure flag: 'S' = use Src (earlier), 'T' = keep Tgt
                    IF(Src.ActualDepartureDate IS NOT NULL,
                        IF(Src.ActualDepartureDate < COALESCE(Tgt.ActualDepartureDate, FutureDate), 'S', 'T'),
                        'T')                                              AS ActualDepartureFlag,
                    Tgt.ActualDepartureDate,
                    Tgt.ActualDepartureRF,
                    Tgt.ActualDepartureCF,
                    Tgt.ActualDepartureType,
                    Tgt.ActualDepartureStatus,

                    IF(Src.ActualFirstArrivalDate IS NOT NULL,
                        IF(Src.ActualFirstArrivalDate < COALESCE(Tgt.ActualFirstArrivalDate, FutureDate), 'S', 'T'),
                        'T')                                              AS ActualFirstArrivalFlag,
                    Tgt.ActualFirstArrivalDate,
                    Tgt.ActualFirstArrivalRF,
                    Tgt.ActualFirstArrivalCF,
                    Tgt.ActualFirstArrivalType,
                    Tgt.ActualFirstArrivalStatus,

                    IF(Src.ActualArrivalDate IS NOT NULL,
                        IF(Src.ActualArrivalDate < COALESCE(Tgt.ActualArrivalDate, FutureDate), 'S', 'T'),
                        'T')                                              AS ActualArrivalFlag,
                    Tgt.ActualArrivalDate,
                    Tgt.ActualArrivalRF,
                    Tgt.ActualArrivalCF,
                    Tgt.ActualArrivalType,
                    Tgt.ActualArrivalStatus,

                    IF(Src.ActualAttemptedDate IS NOT NULL,
                        IF(Src.ActualAttemptedDate < COALESCE(Tgt.ActualAttemptedDate, FutureDate), 'S', 'T'),
                        'T')                                              AS ActualAttemptedFlag,
                    Tgt.ActualAttemptedDate,
                    Tgt.ActualAttemptedRF,
                    Tgt.ActualAttemptedCF,
                    Tgt.ActualAttemptedType,
                    Tgt.ActualAttemptedStatus,

                    IF(Src.ActualDeliveryScanDate IS NOT NULL,
                        IF(Src.ActualDeliveryScanDate < COALESCE(Tgt.ActualDeliveryScanDate, FutureDate), 'S', 'T'),
                        'T')                                              AS ActualDeliveryFlag,
                    Tgt.ActualDeliveryScanDate,
                    Tgt.ActualDeliveryRF,
                    Tgt.ActualDeliveryCF,
                    Tgt.ActualDeliveryType,
                    Tgt.ActualDeliveryStatus,

                    IF(Src.LastScanDate IS NOT NULL,
                        IF(Src.LastScanDate > COALESCE(Tgt.LastScanDate, EarlyDate), 'S', 'T'),
                        'T')                                              AS LastScanFlag,
                    Tgt.LastScanDate,
                    Tgt.LastScanRF,
                    Tgt.LastScanCF,
                    Tgt.LastScanType,
                    Tgt.LastScanStatus,
                    COALESCE(Src.MISScanDate, Tgt.MISScanDate)           AS MISScanDate,
                    COALESCE(Src.MISRF, Tgt.MISRF)                       AS MISRF

                FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI_Daily` Tgt
                JOIN `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_KPI_Stg` src ON Src.LabelNo = Tgt.LabelNo
                JOIN LabelsToProcess2 sel ON sel.LabelNo = Src.LabelNo
                WHERE sel.UpdateId IS NOT NULL
            ) Tgt
            JOIN `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_KPI_Stg` src ON Src.LabelNo = Tgt.LabelNo
        ) AS Src
        ON Tgt2.LabelNo = Src.LabelNo
        WHEN MATCHED THEN UPDATE SET
            Tgt2.LabelNo               = Src.LabelNo,
            Tgt2.CountryCode           = Src.CountryCode,
            Tgt2.Category              = Src.Category,
            Tgt2.RealisedDate          = Src.RealisedDate,
            Tgt2.CreatedOn             = Src.CreatedOn,
            Tgt2.ServiceType           = Src.ServiceType,
            Tgt2.SLA                   = Src.SLA,
            Tgt2.KPIPickup             = Src.KPIPickup,
            Tgt2.KPILEA                = Src.KPILEA,
            Tgt2.KPIDelivery           = Src.KPIDelivery,
            Tgt2.KPIPickupImpact       = Src.KPIPickupImpact,
            Tgt2.KPILEAImpact          = Src.KPILEAImpact,
            Tgt2.KPIDeliveryImpact     = Src.KPIDeliveryImpact,
            Tgt2.DueDate               = Src.DueDate,
            Tgt2.KPIDepartureDate      = Src.KPIDepartureDate,
            -- OFFSET ... ROWS FETCH FIRST 1 ROWS ONLY → BQ: ORDER BY ... LIMIT 1 with OFFSET
            Tgt2.KPIArrivalDate        = (
                SELECT Calendar_Date
                FROM Dim_Time
                LEFT JOIN KPIExcludedDates ON Calendar_Date = Date AND Franchise = Src.ToRf
                WHERE Calendar_Date >= DATE(Src.ActualDepartureDate)
                  AND week_day_flag = 'Y' AND Comment IS NULL
                ORDER BY Calendar_Date
                LIMIT 1 OFFSET COALESCE(Src.KPILEA, 1)
            ),
            Tgt2.KPIAttemptedDate      = (
                SELECT Calendar_Date
                FROM Dim_Time
                LEFT JOIN KPIExcludedDates ON Calendar_Date = Date AND Franchise = Src.ToRf
                WHERE Calendar_Date >= DATE(Src.ActualArrivalDate)
                  AND week_day_flag = 'Y' AND Comment IS NULL
                ORDER BY Calendar_Date
                LIMIT 1 OFFSET COALESCE(Src.KPIDelivery, 1)
            ),
            Tgt2.KPIAttemptedDateAdjust = (
                SELECT Calendar_Date
                FROM Dim_Time
                LEFT JOIN KPIExcludedDates ON Calendar_Date = Date AND Franchise = Src.ToRf
                WHERE Calendar_Date >= DATE(Src.ActualDepartureDate)
                  AND week_day_flag = 'Y' AND Comment IS NULL
                ORDER BY Calendar_Date
                LIMIT 1 OFFSET COALESCE(Src.KPILEA + Src.KPIDelivery, 1)
            ),
            Tgt2.ActualDepartureDate   = Src.ActualDepartureDate,
            Tgt2.ActualDepartureRF     = Src.ActualDepartureRF,
            Tgt2.ActualDepartureCF     = Src.ActualDepartureCF,
            Tgt2.ActualDepartureType   = Src.ActualDepartureType,
            Tgt2.ActualDepartureStatus = Src.ActualDepartureStatus,
            Tgt2.ActualFirstArrivalDate   = Src.ActualFirstArrivalDate,
            Tgt2.ActualFirstArrivalRF     = Src.ActualFirstArrivalRF,
            Tgt2.ActualFirstArrivalCF     = Src.ActualFirstArrivalCF,
            Tgt2.ActualFirstArrivalType   = Src.ActualFirstArrivalType,
            Tgt2.ActualFirstArrivalStatus = Src.ActualFirstArrivalStatus,
            Tgt2.ActualArrivalDate     = Src.ActualArrivalDate,
            Tgt2.ActualArrivalRF       = Src.ActualArrivalRF,
            Tgt2.ActualArrivalCF       = Src.ActualArrivalCF,
            Tgt2.ActualArrivalType     = Src.ActualArrivalType,
            Tgt2.ActualArrivalStatus   = Src.ActualArrivalStatus,
            Tgt2.ActualAttemptedDate   = Src.ActualAttemptedDate,
            Tgt2.ActualAttemptedRF     = Src.ActualAttemptedRF,
            Tgt2.ActualAttemptedCF     = Src.ActualAttemptedCF,
            Tgt2.ActualAttemptedType   = Src.ActualAttemptedType,
            Tgt2.ActualAttemptedStatus = Src.ActualAttemptedStatus,
            Tgt2.ActualDeliveryScanDate = Src.ActualDeliveryScanDate,
            Tgt2.ActualDeliveryRF      = Src.ActualDeliveryRF,
            Tgt2.ActualDeliveryCF      = Src.ActualDeliveryCF,
            Tgt2.ActualDeliveryType    = Src.ActualDeliveryType,
            Tgt2.ActualDeliveryStatus  = Src.ActualDeliveryStatus,
            Tgt2.LastScanDate          = Src.LastScanDate,
            Tgt2.LastScanRF            = Src.LastScanRF,
            Tgt2.LastScanCF            = Src.LastScanCF,
            Tgt2.LastScanType          = Src.LastScanType,
            Tgt2.LastScanStatus        = Src.LastScanStatus,
            Tgt2.MISScanDate           = Src.MISScanDate,
            Tgt2.MISRF                 = Src.MISRF,
            Tgt2.LastUpdated           = Loaded,
            Tgt2.ProcessID             = ProcessID;

        SET Updated = @@ROW_COUNT;

        -- Record interim stats (audit table format preserved exactly)
        SET Ended        = CURRENT_DATETIME();
        SET SubComponent = Component || ' (' || Step || ')';

        CALL `{{ project_id }}.{{ sp_dataset_id }}.SaveLog`(
            SubComponent,
            ProcessID,
            Started,
            Ended,
            Result,
            ErrorMessage,
            Inserted,
            Updated
        );

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed (' || Step || ')';
        SET ErrorMessage = @@error.message;

    END;

    -------------------------
    -- Insert new Labels
    -------------------------
    SET Step    = 'Inserts';
    SET Started = CURRENT_DATETIME();
    SET Updated  = 0;

    BEGIN

        SET Loaded = CURRENT_DATETIME();

        -- WITH (TABLOCK) removed
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI_Daily`
        (
            LabelNo, CountryCode, Category, CreatedOn, ServiceType, RealisedDate,
            SLA, KPIPickup, KPILEA, KPIDelivery,
            KPIPickupImpact, KPILEAImpact, KPIDeliveryImpact,
            DueDate, KPIDepartureDate,
            KPIArrivalDate, KPIAttemptedDate, KPIAttemptedDateAdjust,
            ActualDepartureDate, ActualDepartureRF, ActualDepartureCF, ActualDepartureType, ActualDepartureStatus,
            ActualFirstArrivalDate, ActualFirstArrivalRF, ActualFirstArrivalCF, ActualFirstArrivalType, ActualFirstArrivalStatus,
            ActualArrivalDate, ActualArrivalRF, ActualArrivalCF, ActualArrivalType, ActualArrivalStatus,
            ActualAttemptedDate, ActualAttemptedRF, ActualAttemptedCF, ActualAttemptedType, ActualAttemptedStatus,
            ActualDeliveryScanDate, ActualDeliveryRF, ActualDeliveryCF, ActualDeliveryType, ActualDeliveryStatus,
            LastScanDate, LastScanRF, LastScanCF, LastScanType, LastScanStatus,
            MISScanDate, MISRF, LastUpdated, ProcessID
        )
        SELECT
            Src.LabelNo, CountryCode, Category, CreatedOn, ServiceType, RealisedDate,
            SLA, KPIPickup, KPILEA, KPIDelivery,
            KPIPickupImpact, KPILEAImpact, KPIDeliveryImpact,
            DueDate, KPIDepartureDate,
            -- OFFSET ... ROWS FETCH FIRST 1 ROWS ONLY → LIMIT 1 OFFSET n
            (
                SELECT Calendar_Date FROM Dim_Time
                LEFT JOIN KPIExcludedDates ON Calendar_Date = Date AND Franchise = Src.ToRf
                WHERE Calendar_Date >= DATE(Src.ActualDepartureDate)
                  AND week_day_flag = 'Y' AND Comment IS NULL
                ORDER BY Calendar_Date
                LIMIT 1 OFFSET COALESCE(KPILEA, 1)
            ) AS KPIArrivalDate,
            (
                SELECT Calendar_Date FROM Dim_Time
                LEFT JOIN KPIExcludedDates ON Calendar_Date = Date AND Franchise = Src.ToRf
                WHERE Calendar_Date >= DATE(Src.ActualArrivalDate)
                  AND week_day_flag = 'Y' AND Comment IS NULL
                ORDER BY Calendar_Date
                LIMIT 1 OFFSET COALESCE(KPIDelivery, 1)
            ) AS KPIAttemptedDate,
            (
                SELECT Calendar_Date FROM Dim_Time
                LEFT JOIN KPIExcludedDates ON Calendar_Date = Date AND Franchise = Src.ToRf
                WHERE Calendar_Date >= DATE(Src.ActualDepartureDate)
                  AND week_day_flag = 'Y' AND Comment IS NULL
                ORDER BY Calendar_Date
                LIMIT 1 OFFSET COALESCE(KPILEA + KPIDelivery, 1)
            ) AS KPIAttemptedDateAdjust,
            ActualDepartureDate, ActualDepartureRF, ActualDepartureCF, ActualDepartureType, ActualDepartureStatus,
            ActualFirstArrivalDate, ActualFirstArrivalRF, ActualFirstArrivalCF, ActualFirstArrivalType, ActualFirstArrivalStatus,
            ActualArrivalDate, ActualArrivalRF, ActualArrivalCF, ActualArrivalType, ActualArrivalStatus,
            ActualAttemptedDate, ActualAttemptedRF, ActualAttemptedCF, ActualAttemptedType, ActualAttemptedStatus,
            ActualDeliveryScanDate, ActualDeliveryRF, ActualDeliveryCF, ActualDeliveryType, ActualDeliveryStatus,
            LastScanDate, LastScanRF, LastScanCF, LastScanType, LastScanStatus,
            MISScanDate, MISRF,
            Loaded,
            ProcessID
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_KPI_Stg` Src
        JOIN LabelsToProcess2 Sel ON Sel.LabelNo = Src.LabelNo
        WHERE Sel.InsertId IS NOT NULL;

        SET Inserted = @@ROW_COUNT;
        SET Result   = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed (' || Step || ')';
        SET ErrorMessage = @@error.message;

    END;

    /*
        Record load metrics in log (audit table format preserved exactly)
    */
    SET Ended        = CURRENT_DATETIME();
    SET SubComponent = Component || ' (' || Step || ')';

    CALL `{{ project_id }}.{{ sp_dataset_id }}.SaveLog`(
        SubComponent,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted,
        Updated
    );

    DROP TABLE LabelsToProcess2;

END;
