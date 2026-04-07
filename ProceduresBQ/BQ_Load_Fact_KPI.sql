-- ==========================================================================================
-- Routine:     BQ_Load_Fact_KPI
-- Description: Maintains the stats for Pickup & Delivery KPIs
--              BigQuery compatible version of Load_Fact_KPI
--              Note: Temp table (#LabelsToProcess) replaced with BQ temp table (CREATE TEMP TABLE).
--                    WHILE batch loop removed - BQ handles large inserts natively.
--                    WITH (TABLOCK) / WITH (INDEX ...) hints removed.
--                    IIF → IF. ISNULL → IFNULL.
--                    FORMAT(n,'N0') removed (logging only).
--                    RAISERROR removed.
--                    WAITFOR DELAY removed (not applicable in BQ).
--                    OBJECT_ID('tempdb...') check removed.
--                    GOTO replaced with EXCEPTION block.
--                    BEGIN/COMMIT TRANSACTION removed.
--                    SYSDATETIME() → CURRENT_DATETIME().
--                    DATETIME2(3) → DATETIME.
--                    CONVERT(varchar,...) → CAST(... AS STRING).
--                    Audit table format preserved exactly.
-- Example:     CALL dbo.BQ_Load_Fact_KPI(-82)
-- History:
--  11/04/2019  B. Woods        Routine Written
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.BQ_Load_Fact_KPI`(
    IN ProcessID INT64
)
BEGIN

    DECLARE Loaded    DATETIME;
    DECLARE Component STRING DEFAULT 'dbo.Load_Fact_KPI';
    DECLARE SubComponent STRING;
    DECLARE Step      STRING;
    DECLARE Started   DATETIME;
    DECLARE Ended     DATETIME;
    DECLARE Result    STRING;
    DECLARE ErrorMessage STRING;
    DECLARE Inserted  INT64 DEFAULT 0;
    DECLARE Updated   INT64 DEFAULT 0;
    DECLARE MaxInsertId INT64;
    DECLARE MaxUpdateId INT64;

    /*
        Get list of LabelNos to Update or Insert rows on `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI`
    */
    SET Step    = 'Temp Table';
    SET Started = CURRENT_DATETIME();

    -- BQ temp table replaces SQL Server #LabelsToProcess
    CREATE TEMP TABLE LabelsToProcess (
        LabelNo   STRING,
        UpdateId  INT64,
        InsertId  INT64
    );

    INSERT INTO LabelsToProcess (LabelNo, UpdateId, InsertId)
        SELECT
            stg.LabelNo,
            -- IIF → IF; row_number() preserved (BQ supports window functions)
            UpdateId = IF(
                Tgt.LabelNo = Stg.LabelNo,
                ROW_NUMBER() OVER(
                    PARTITION BY IF(Tgt.LabelNo = Stg.LabelNo, 1, NULL)
                    ORDER BY Stg.LabelNo
                ),
                NULL
            ),
            InsertId = IF(
                Tgt.LabelNo IS NULL,
                ROW_NUMBER() OVER(
                    PARTITION BY IF(Tgt.LabelNo IS NULL, 1, NULL)
                    ORDER BY Stg.LabelNo
                ),
                NULL
            )
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_KPI_Stg` AS stg
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI` AS tgt
            -- WITH (INDEX (PK_Fact_KPI)) removed
            ON tgt.LabelNo = stg.LabelNo;

    -- @@ROWCOUNT check replicated with COUNT
    IF (SELECT COUNT(*) FROM LabelsToProcess) = 0 THEN
        SET Result = 'Success';
    END IF;

    SELECT MAX(InsertId), MAX(UpdateId)
    INTO MaxInsertId, MaxUpdateId
    FROM LabelsToProcess;

    -- Record interim results
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

    /*
        Update existing Labels  (Step preserved from original - no update logic in original INSERT-only proc)
    */
    SET Step    = 'Updates';
    SET Started = CURRENT_DATETIME();
    SET Inserted = 0;
    SET Updated  = 0;

    /*
        Insert new Labels
        BQ handles large inserts natively; WHILE batch loop removed.
    */
    SET Step    = 'Inserts';
    SET Started = CURRENT_DATETIME();
    SET Updated  = 0;

    BEGIN

        SET Loaded = CURRENT_DATETIME();

        -- WITH (TABLOCK) removed
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI`
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
            --MISScanDate,
            --MISRF,
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
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_KPI_Stg` Src
        JOIN LabelsToProcess Sel ON Sel.LabelNo = Src.LabelNo
        WHERE Sel.InsertId IS NOT NULL;

        SET Inserted = @@ROW_COUNT;
        SET Result   = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed (' || Step || ')';
        SET ErrorMessage = @@error.message;

    END;

    -- Record load metrics in log (audit table format preserved exactly)
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

    DROP TABLE LabelsToProcess;

END;
