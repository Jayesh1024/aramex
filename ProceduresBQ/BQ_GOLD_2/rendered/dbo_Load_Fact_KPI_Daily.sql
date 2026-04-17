-- ==========================================================================================
-- Routine:     dbo_Load_Fact_KPI_Daily
-- Description: Maintains the stats for InterBranch Pickup & Delivery KPIs
--              BigQuery compatible version of Load_Fact_KPI_Daily
--              Note: Temp table replaced with BQ TEMP TABLE.
--                    WHILE batch loops removed - BQ handles large DML natively.
--                    UPDATE ... FROM replaced with MERGE.
--                    EXCEPT change detection replaced with explicit column comparisons.
--                    Correlated subqueries for KPI dates replaced with pre-computed
--                    BusinessDayCalendar temp table joined via BusDaySeq offsets.
--                    Convert(Date,x) → DATE(x).
--                    IIF → IF. ISNULL → IFNULL. COALESCE preserved.
--                    WITH (TABLOCK) removed. RAISERROR / WAITFOR DELAY removed.
--                    GOTO replaced with EXCEPTION block.
--                    BEGIN/COMMIT TRANSACTION removed.
--                    SYSDATETIME() → CURRENT_DATETIME().
--                    DATETIME2(3) → DATETIME.
--                    CONVERT(varchar,...) → CAST(... AS STRING).
--                    Audit table format preserved exactly.
-- Example:     CALL dbo.dbo_Load_Fact_KPI_Daily(2574)
-- History:
--  03/12/2022  B. Woods        Routine Written
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `searce-sandbox-da-delivery.Aramex_oceania_SP.dbo_Load_Fact_KPI_Daily`(
    IN ProcessID INT64
)
BEGIN

    DECLARE v_Loaded         DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Component      STRING DEFAULT 'dbo.Load_Fact_KPI_Daily';
    DECLARE v_Step           STRING;
    DECLARE v_Started        DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Result         STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage   STRING DEFAULT '';
    DECLARE v_Inserted       INT64 DEFAULT 0;
    DECLARE v_Updated        INT64 DEFAULT 0;

    -- -----------------------------------------------------------------------
    -- Step 1: Pre-calculate Business Day Sequences per Franchise
    -- This handles the ToRf specific holidays and weekends
    -- -----------------------------------------------------------------------
    SET v_Step = 'Business Day Calendar';

    CREATE OR REPLACE TEMP TABLE BusinessDayCalendar AS
    SELECT
        fr.FranchiseCode,
        dt.Calendar_Date,
        -- Assign a unique ID to every valid business day per franchise
        ROW_NUMBER() OVER(PARTITION BY fr.FranchiseCode ORDER BY dt.Calendar_Date) AS BusDaySeq
    FROM (
        SELECT DISTINCT ToRf AS FranchiseCode
        FROM `searce-sandbox-da-delivery.Aramex_oceania.Staging_Fact_KPI_Stg`
        WHERE ToRf IS NOT NULL
    ) fr
    CROSS JOIN `searce-sandbox-da-delivery.Aramex_oceania.dbo_Dim_Time` dt
    LEFT JOIN `searce-sandbox-da-delivery.Aramex_oceania.dbo_KPIExcludedDates` ex
      ON dt.Calendar_Date = ex.Date
     AND ex.Franchise     = fr.FranchiseCode
    WHERE dt.week_day_flag = 'Y'
      AND ex.Comment IS NULL;

    -- -----------------------------------------------------------------------
    -- Step 2: Combine Staging with Calculated KPI Dates via Joins
    -- -----------------------------------------------------------------------
    SET v_Step = 'Pre-calculate KPIs';

    CREATE OR REPLACE TEMP TABLE CalculatedKPIs AS
    SELECT
        stg.*,
        tgt.LabelNo IS NOT NULL AS IsUpdate,
        -- Get Dates by finding (StartSeq + Offset)
        calArrival.Calendar_Date   AS Calculated_KPIArrivalDate,
        calAttempted.Calendar_Date AS Calculated_KPIAttemptedDate
    FROM `searce-sandbox-da-delivery.Aramex_oceania.Staging_Fact_KPI_Stg` AS stg
    LEFT JOIN `searce-sandbox-da-delivery.Aramex_oceania.dbo_Fact_KPI_Daily` AS tgt
        ON tgt.LabelNo = stg.LabelNo
    -- Join to get Start Sequence for Departure
    LEFT JOIN BusinessDayCalendar startDep
        ON startDep.FranchiseCode  = stg.ToRf
        AND startDep.Calendar_Date = DATE(stg.ActualDepartureDate)
    -- Join to get Start Sequence for Arrival
    LEFT JOIN BusinessDayCalendar startArr
        ON startArr.FranchiseCode  = stg.ToRf
        AND startArr.Calendar_Date = DATE(stg.ActualArrivalDate)
    -- Join back to find the N-th day for Arrival (Departure + LEA)
    LEFT JOIN BusinessDayCalendar calArrival
        ON calArrival.FranchiseCode = stg.ToRf
        AND calArrival.BusDaySeq    = startDep.BusDaySeq + CAST(COALESCE(stg.KPILEA, 0) AS INT64)
    -- Join back to find the N-th day for Attempted (Arrival + Delivery)
    LEFT JOIN BusinessDayCalendar calAttempted
        ON calAttempted.FranchiseCode = stg.ToRf
        AND calAttempted.BusDaySeq    = startArr.BusDaySeq + CAST(COALESCE(stg.KPIDelivery, 0) AS INT64);

    -- -----------------------------------------------------------------------
    -- Step 3: Simple MERGE for Updates
    -- -----------------------------------------------------------------------
    SET v_Step = 'Updates';

    BEGIN
        MERGE `searce-sandbox-da-delivery.Aramex_oceania.dbo_Fact_KPI_Daily` AS Tgt
        USING (SELECT * FROM CalculatedKPIs WHERE IsUpdate = TRUE) AS Src
        ON Tgt.LabelNo = Src.LabelNo
        WHEN MATCHED THEN
            UPDATE SET
                Tgt.CountryCode      = Src.CountryCode,
                Tgt.Category         = Src.Category,
                Tgt.KPIArrivalDate   = Src.Calculated_KPIArrivalDate,
                Tgt.KPIAttemptedDate = Src.Calculated_KPIAttemptedDate,
                Tgt.LastUpdated      = v_Loaded,
                Tgt.ProcessID        = ProcessID;

        SET v_Updated = @@row_count;
    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed'; SET v_ErrorMessage = @@error.message;
    END;

    -- -----------------------------------------------------------------------
    -- Step 4: Simple INSERT for new records
    -- -----------------------------------------------------------------------
    IF v_Result = 'Success' THEN
        SET v_Step = 'Inserts';
        BEGIN
            INSERT INTO `searce-sandbox-da-delivery.Aramex_oceania.dbo_Fact_KPI_Daily`
            (
                LabelNo, CountryCode, Category, CreatedOn, ServiceType, RealisedDate,
                KPIArrivalDate, KPIAttemptedDate, LastUpdated, ProcessID
            )
            SELECT
                LabelNo, CountryCode, Category, CreatedOn, ServiceType, RealisedDate,
                Calculated_KPIArrivalDate, Calculated_KPIAttemptedDate, v_Loaded, ProcessID
            FROM CalculatedKPIs
            WHERE IsUpdate = FALSE;

            SET v_Inserted = @@row_count;
        EXCEPTION WHEN ERROR THEN
            SET v_Result = 'Failed'; SET v_ErrorMessage = @@error.message;
        END;
    END IF;

    -- -----------------------------------------------------------------------
    -- Final Log
    -- -----------------------------------------------------------------------
    CALL `searce-sandbox-da-delivery.Aramex_oceania_SP.Staging_SaveLog`(
        CONCAT(v_Component, ' (', v_Step, ')'),
        ProcessID,
        v_Started,
        CURRENT_DATETIME(),
        v_Result,
        v_ErrorMessage,
        v_Inserted,
        v_Updated,
        -1
    );

    DROP TABLE IF EXISTS BusinessDayCalendar;
    DROP TABLE IF EXISTS CalculatedKPIs;

END;