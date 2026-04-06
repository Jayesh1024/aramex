-- ==========================================================================================
-- Routine:     BQ_Load_Fact_KPI
-- Description: Maintains the stats for Pickup & Delivery KPIs
--              BigQuery compatible version of dbo.Load_Fact_KPI
--              Note:
--                - #LabelsToProcess temp table → BQ session temp table
--                - WHILE batch loop for INSERTs removed (BQ handles volume natively)
--                - WITH (TABLOCK) / INDEX hints removed
--                - WAITFOR DELAY removed (not supported in BQ)
--                - RAISERROR removed
--                - FORMAT(n,'N0') removed (logging only)
--                - GOTO RESULT → EXCEPTION block
--                - IIF → IF; ISNULL → IFNULL
--                - OBJECT_SCHEMA_NAME(@@PROCID) → hardcoded string
--                - SYSDATETIME() → CURRENT_DATETIME()
--                - DATETIME2(3) → DATETIME
--                - Interim SaveLog calls per batch consolidated to final call
--                - Audit table format preserved exactly.
-- Example:     CALL dbo.BQ_Load_Fact_KPI(-82)
-- History:
--  11/04/2019  B. Woods        Routine Written
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE dbo.BQ_Load_Fact_KPI(
    IN ProcessID INT64
)
BEGIN

    DECLARE Loaded   DATETIME DEFAULT CURRENT_DATETIME();

    DECLARE Component    STRING DEFAULT 'Load_Fact_KPI';
    DECLARE SubComponent STRING;
    DECLARE Step         STRING;
    DECLARE Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING;
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64 DEFAULT 0;
    DECLARE Updated      INT64 DEFAULT 0;

    /*
        Get list of LabelNos to Update or Insert rows on dbo.Fact_KPI
    */
    SET Step    = 'Temp Table';
    SET Started = CURRENT_DATETIME();

    BEGIN

        -- #LabelsToProcess → BQ session temp table
        -- IIF → IF; index hint removed
        CREATE TEMP TABLE LabelsToProcess AS
        SELECT
            stg.LabelNo,
            -- IF replaces IIF; window functions preserved (BQ supports them)
            IF(tgt.LabelNo = stg.LabelNo,
               ROW_NUMBER() OVER(PARTITION BY IF(tgt.LabelNo = stg.LabelNo, 1, NULL) ORDER BY stg.LabelNo),
               NULL) AS UpdateId,
            IF(tgt.LabelNo IS NULL,
               ROW_NUMBER() OVER(PARTITION BY IF(tgt.LabelNo IS NULL, 1, NULL) ORDER BY stg.LabelNo),
               NULL) AS InsertId
        FROM Staging.Fact_KPI_Stg AS stg
        LEFT JOIN dbo.Fact_KPI AS tgt
            -- WITH (INDEX(PK_Fact_KPI)) removed
            ON tgt.LabelNo = stg.LabelNo;

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
            (SELECT IFNULL(MAX(InsertId), 0) FROM LabelsToProcess),
            (SELECT IFNULL(MAX(UpdateId), 0) FROM LabelsToProcess)
        );

        /*
            Insert new Labels
            WHILE batch loop removed — single INSERT handles full volume in BQ.
            WAITFOR DELAY removed (not applicable in BQ).
        */
        SET Step    = 'Inserts';
        SET Started = CURRENT_DATETIME();
        SET Loaded  = CURRENT_DATETIME();

        -- WITH (TABLOCK) removed
        INSERT INTO dbo.Fact_KPI
        (
            LabelNo,
            CountryCode,
            Category,
            SLA,
            KPIPickup,
            KPILEA,
            KPIDelivery,
            KPIPickupImpact,
            KPILEAImpact,
            KPIDeliveryImpact,
            DueDate,
            KPIDepartureDate,
            KPIArrivalDate,
            KPIAttemptedDate,
            KPIAttemptedDateAdjust,
            ActualDepartureDate,
            ActualDepartureRF,
            ActualDepartureCF,
            ActualDepartureType,
            ActualDepartureStatus,
            ActualFirstArrivalDate,
            ActualFirstArrivalRF,
            ActualFirstArrivalCF,
            ActualFirstArrivalType,
            ActualFirstArrivalStatus,
            ActualArrivalDate,
            ActualArrivalRF,
            ActualArrivalCF,
            ActualArrivalType,
            ActualArrivalStatus,
            ActualAttemptedDate,
            ActualAttemptedRF,
            ActualAttemptedCF,
            ActualAttemptedType,
            ActualAttemptedStatus,
            ActualDeliveryScanDate,
            ActualDeliveryRF,
            ActualDeliveryCF,
            ActualDeliveryType,
            ActualDeliveryStatus,
            LastScanDate,
            LastScanRF,
            LastScanCF,
            LastScanType,
            LastScanStatus,
            -- MISScanDate, MISRF commented out in original; preserved
            LastUpdated,
            ProcessID
        )
        SELECT
            Src.LabelNo,
            CountryCode,
            Category,
            SLA,
            KPIPickup,
            KPILEA,
            KPIDelivery,
            KPIPickupImpact,
            KPILEAImpact,
            KPIDeliveryImpact,
            DueDate,
            KPIDepartureDate,
            KPIArrivalDate,
            KPIAttemptedDate,
            KPIAttemptedDateAdjust,
            ActualDepartureDate,
            ActualDepartureRF,
            ActualDepartureCF,
            ActualDepartureType,
            ActualDepartureStatus,
            ActualFirstArrivalDate,
            ActualFirstArrivalRF,
            ActualFirstArrivalCF,
            ActualFirstArrivalType,
            ActualFirstArrivalStatus,
            ActualArrivalDate,
            ActualArrivalRF,
            ActualArrivalCF,
            ActualArrivalType,
            ActualArrivalStatus,
            ActualAttemptedDate,
            ActualAttemptedRF,
            ActualAttemptedCF,
            ActualAttemptedType,
            ActualAttemptedStatus,
            ActualDeliveryScanDate,
            ActualDeliveryRF,
            ActualDeliveryCF,
            ActualDeliveryType,
            ActualDeliveryStatus,
            LastScanDate,
            LastScanRF,
            LastScanCF,
            LastScanType,
            LastScanStatus,
            Loaded,
            ProcessID
        FROM Staging.Fact_KPI_Stg Src
        JOIN LabelsToProcess Sel ON Sel.LabelNo = Src.LabelNo
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

    DROP TABLE IF EXISTS LabelsToProcess;

END;
