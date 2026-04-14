-- ==========================================================================================
-- Routine:     dbo_Load_Fact_KPI
-- Description: Maintains the stats for Pickup & Delivery KPIs
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dbo_Load_Fact_KPI`(
    IN ProcessID INT64
)
BEGIN

    DECLARE Loaded           DATETIME;
    DECLARE FutureDate       DATETIME DEFAULT DATETIME '2999-12-31 00:00:00';
    DECLARE EarlyDate        DATETIME DEFAULT DATETIME '1900-01-01 00:00:00';

    DECLARE Component    STRING DEFAULT 'dbo.Load_Fact_KPI';
    DECLARE SubComponent STRING;
    DECLARE Step         STRING;
    DECLARE Started      DATETIME;
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING DEFAULT 'Success';
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64 DEFAULT 0;
    DECLARE Updated      INT64 DEFAULT 0;
    DECLARE MaxInsertId  INT64;
    DECLARE MaxUpdateId  INT64;

    /*
        Step 1: Temp Table Setup
    */
    SET Step    = 'Temp Table';
    SET Started = CURRENT_DATETIME();

    CREATE TEMP TABLE LabelsToProcess (
        LabelNo  STRING,
        UpdateId INT64,
        InsertId INT64
    );

    INSERT INTO LabelsToProcess (LabelNo, UpdateId, InsertId)
    SELECT
        stg.LabelNo,
        IF(tgt.LabelNo = stg.LabelNo, ROW_NUMBER() OVER(PARTITION BY IF(tgt.LabelNo = stg.LabelNo, 1, NULL) ORDER BY stg.LabelNo), NULL) AS UpdateId,
        IF(tgt.LabelNo IS NULL, ROW_NUMBER() OVER(PARTITION BY IF(tgt.LabelNo IS NULL, 1, NULL) ORDER BY stg.LabelNo), NULL) AS InsertId
    FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_KPI_Stg` AS stg
    LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI` AS tgt ON tgt.LabelNo = stg.LabelNo;

    SET (MaxInsertId, MaxUpdateId) = (SELECT AS STRUCT MAX(InsertId), MAX(UpdateId) FROM LabelsToProcess);

    SET Ended = CURRENT_DATETIME();
    CALL `{{ project_id }}.{{ sp_dataset_id }}.SaveLog`(
        Component || ' (' || Step || ')', ProcessID, Started, Ended, Result, ErrorMessage, MaxInsertId, MaxUpdateId
    );

    -------------------------
    -- Updates
    -------------------------
    SET Step    = 'Updates';
    SET Started = CURRENT_DATETIME();
    
    BEGIN
        SET Loaded = CURRENT_DATETIME();

        MERGE `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI` AS Tgt2
        USING (
            WITH ValidDates AS (
                SELECT 
                    t.Calendar_Date,
                    e.Franchise,
                    DepartureDateStart,
                    ROW_NUMBER() OVER (PARTITION BY DepartureDateStart, e.Franchise ORDER BY t.Calendar_Date) - 1 AS OffsetIndex
                FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Time` t
                CROSS JOIN (SELECT DISTINCT ToRf AS Franchise, DATE(ActualDepartureDate) AS DepartureDateStart FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_KPI_Stg`) e
                LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIExcludedDates` ex ON t.Calendar_Date = ex.Date AND ex.Franchise = e.Franchise
                WHERE t.Calendar_Date >= e.DepartureDateStart
                  AND t.week_day_flag = 'Y' AND ex.Comment IS NULL
            )
            SELECT 
                Base.*,
                vd.Calendar_Date AS CalculatedKPIArrivalDate
            FROM (
                SELECT
                    COALESCE(Src.LabelNo, Tgt.LabelNo) AS LabelNo,
                    COALESCE(Src.CountryCode, Tgt.CountryCode) AS CountryCode,
                    COALESCE(Src.Category, Tgt.Category) AS Category,
                    Src.FromRf, Src.ToRf,
                    COALESCE(Src.SLA, Tgt.SLA) AS SLA,
                    COALESCE(Src.KPILEA, Tgt.KPILEA) AS KPILEA,
                    IF(Src.ActualDepartureDate < COALESCE(Tgt.ActualDepartureDate, FutureDate), Src.ActualDepartureDate, Tgt.ActualDepartureDate) AS FinalActualDepartureDate,
                    IF(Src.ActualDepartureDate < COALESCE(Tgt.ActualDepartureDate, FutureDate), Src.ActualDepartureRF, Tgt.ActualDepartureRF) AS FinalActualDepartureRF
                FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI` Tgt
                JOIN `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_KPI_Stg` Src ON Src.LabelNo = Tgt.LabelNo
                JOIN LabelsToProcess sel ON sel.LabelNo = Src.LabelNo
                WHERE sel.UpdateId IS NOT NULL
            ) Base
            LEFT JOIN ValidDates vd ON vd.DepartureDateStart = DATE(Base.FinalActualDepartureDate) 
                AND vd.Franchise = Base.ToRf
                AND vd.OffsetIndex = COALESCE(Base.KPILEA, 1)
        ) AS Src
        ON Tgt2.LabelNo = Src.LabelNo
        WHEN MATCHED THEN UPDATE SET
            Tgt2.CountryCode           = Src.CountryCode,
            Tgt2.Category              = Src.Category,
            Tgt2.SLA                   = Src.SLA,
            Tgt2.KPIArrivalDate        = Src.CalculatedKPIArrivalDate,
            Tgt2.ActualDepartureDate   = Src.FinalActualDepartureDate,
            Tgt2.ActualDepartureRF     = Src.FinalActualDepartureRF,
            Tgt2.LastUpdated           = Loaded,
            Tgt2.ProcessID             = ProcessID;

        SET Updated = @@ROW_COUNT;
    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed (' || Step || ')';
        SET ErrorMessage = @@error.message;
    END;

    -------------------------
    -- Inserts
    -------------------------
    SET Step    = 'Inserts';
    SET Started = CURRENT_DATETIME();
    
    BEGIN
        SET Loaded = CURRENT_DATETIME();

        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI`
        (
            LabelNo, CountryCode, Category, CreatedOn, ServiceType, RealisedDate,
            SLA, KPIPickup, KPILEA, KPIDelivery, DueDate, KPIDepartureDate,
            KPIArrivalDate, KPIAttemptedDate, KPIAttemptedDateAdjust,
            ActualDepartureDate, ActualDepartureRF, ActualArrivalDate, ActualArrivalRF,
            LastUpdated, ProcessID
        )
        WITH WorkingDays AS (
            SELECT 
                t.Calendar_Date,
                e.Franchise,
                e.RefDate,
                e.RefType,
                ROW_NUMBER() OVER (PARTITION BY e.RefDate, e.Franchise, e.RefType ORDER BY t.Calendar_Date) - 1 AS OffsetIndex
            FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Time` t
            CROSS JOIN (
                SELECT ToRf AS Franchise, DATE(ActualDepartureDate) AS RefDate, 'LEA' AS RefType FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_KPI_Stg`
                UNION DISTINCT
                SELECT ToRf AS Franchise, DATE(ActualArrivalDate) AS RefDate, 'DEL' AS RefType FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_KPI_Stg`
            ) e
            LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIExcludedDates` ex ON t.Calendar_Date = ex.Date AND ex.Franchise = e.Franchise
            WHERE t.Calendar_Date >= e.RefDate AND t.week_day_flag = 'Y' AND ex.Comment IS NULL
        )
        SELECT
            Src.LabelNo, Src.CountryCode, Src.Category, Src.CreatedOn, Src.ServiceType, Src.RealisedDate,
            Src.SLA, Src.KPIPickup, Src.KPILEA, Src.KPIDelivery, Src.DueDate, Src.KPIDepartureDate,
            wd_lea.Calendar_Date,  -- KPIArrivalDate
            wd_del.Calendar_Date,  -- KPIAttemptedDate
            wd_adj.Calendar_Date,  -- KPIAttemptedDateAdjust
            Src.ActualDepartureDate, Src.ActualDepartureRF, Src.ActualArrivalDate, Src.ActualArrivalRF,
            Loaded,
            ProcessID
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_KPI_Stg` Src
        JOIN LabelsToProcess Sel ON Sel.LabelNo = Src.LabelNo
        LEFT JOIN WorkingDays wd_lea ON wd_lea.RefDate = DATE(Src.ActualDepartureDate) AND wd_lea.Franchise = Src.ToRf AND wd_lea.RefType = 'LEA' AND wd_lea.OffsetIndex = COALESCE(Src.KPILEA, 1)
        LEFT JOIN WorkingDays wd_del ON wd_del.RefDate = DATE(Src.ActualArrivalDate) AND wd_del.Franchise = Src.ToRf AND wd_del.RefType = 'DEL' AND wd_del.OffsetIndex = COALESCE(Src.KPIDelivery, 1)
        LEFT JOIN WorkingDays wd_adj ON wd_adj.RefDate = DATE(Src.ActualDepartureDate) AND wd_adj.Franchise = Src.ToRf AND wd_adj.RefType = 'LEA' AND wd_adj.OffsetIndex = COALESCE(Src.KPILEA + Src.KPIDelivery, 1)
        WHERE Sel.InsertId IS NOT NULL;

        SET Inserted = @@ROW_COUNT;
    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed (' || Step || ')';
        SET ErrorMessage = @@error.message;
    END;

    -- Final Log
    CALL `{{ project_id }}.{{ sp_dataset_id }}.SaveLog`(
        Component || ' (Final)', ProcessID, Started, CURRENT_DATETIME(), Result, ErrorMessage, Inserted, Updated
    );

    DROP TABLE LabelsToProcess;
END;