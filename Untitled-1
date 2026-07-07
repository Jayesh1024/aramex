-- ==========================================================================================
-- Routine:     dbo_Load_Fact_KPI_Daily
-- Description: Maintains the stats for InterBranch Pickup & Delivery KPIs
--              BigQuery compatible version of [dbo].[Load_Fact_KPI_Daily]
--              Note: #LabelsToProcess2 → TEMP TABLE LabelsToProcess
--                    WHILE batch loops removed — BQ handles large DML natively
--                    UPDATE ... FROM → MERGE
--                    EXCEPT change detection → explicit column comparisons
--                    Correlated KPI date subqueries → WorkingDays temp table
--                    IIF → IF, ISNULL → IFNULL, Convert(Date,x) → DATE(x)
--                    WITH (TABLOCK) / RAISERROR / WAITFOR DELAY / GOTO removed
--                    SYSDATETIME() → CURRENT_DATETIME(), @@ROWCOUNT → @@row_count
-- Example:     CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_Load_Fact_KPI_Daily`(2574);
-- History:
--  03/12/2022  B. Woods        Routine Written
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_Load_Fact_KPI_Daily`(
    IN p_ProcessID INT64
)
BEGIN

    DECLARE v_Loaded         DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_FutureDate     DATETIME DEFAULT DATETIME '2999-12-31 00:00:00';
    DECLARE v_EarlyDate      DATETIME DEFAULT DATETIME '1900-01-01 00:00:00';
    DECLARE v_Component      STRING DEFAULT 'dbo_Load_Fact_KPI_Daily';
    DECLARE v_SubComponent   STRING;
    DECLARE v_Step           STRING;
    DECLARE v_Started        DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Ended          DATETIME;
    DECLARE v_Result         STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage   STRING DEFAULT '';
    DECLARE v_Inserted       INT64 DEFAULT 0;
    DECLARE v_Updated        INT64 DEFAULT 0;
    DECLARE v_MaxInsertId    INT64;
    DECLARE v_MaxUpdateId    INT64;

    -- -----------------------------------------------------------------------
    -- Step 1: Labels to process (updates vs inserts)
    -- -----------------------------------------------------------------------
    SET v_Step = 'Temp Table';

    CREATE OR REPLACE TEMP TABLE LabelsToProcess AS
    SELECT
        stg.LabelNo,
        IF(tgt.LabelNo IS NOT NULL,
           ROW_NUMBER() OVER (PARTITION BY IF(tgt.LabelNo IS NOT NULL, 1, NULL) ORDER BY stg.LabelNo),
           NULL) AS UpdateId,
        IF(tgt.LabelNo IS NULL,
           ROW_NUMBER() OVER (PARTITION BY IF(tgt.LabelNo IS NULL, 1, NULL) ORDER BY stg.LabelNo),
           NULL) AS InsertId
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_KPI_Stg` AS stg
    LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI_Daily` AS tgt
        ON tgt.LabelNo = stg.LabelNo;

    SET (v_MaxInsertId, v_MaxUpdateId) = (
        SELECT AS STRUCT IFNULL(MAX(InsertId), 0), IFNULL(MAX(UpdateId), 0)
        FROM LabelsToProcess
    );

    IF v_MaxInsertId = 0 AND v_MaxUpdateId = 0 THEN
        SET v_Ended = CURRENT_DATETIME();
        CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
            CONCAT(v_Component, ' (', v_Step, ')'),
            p_ProcessID, v_Started, v_Ended, v_Result, v_ErrorMessage,
            v_MaxInsertId, v_MaxUpdateId, -1
        );
        RETURN;
    END IF;

    SET v_Ended = CURRENT_DATETIME();
    CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
        CONCAT(v_Component, ' (', v_Step, ')'),
        p_ProcessID, v_Started, v_Ended, v_Result, v_ErrorMessage,
        v_MaxInsertId, v_MaxUpdateId, -1
    );

    -- -----------------------------------------------------------------------
    -- Step 2: Business-day calendar for KPI date offsets
    -- -----------------------------------------------------------------------
    SET v_Step = 'Business Day Calendar';
    SET v_Started = CURRENT_DATETIME();

    CREATE OR REPLACE TEMP TABLE WorkingDays AS
    SELECT
        t.Calendar_Date,
        e.Franchise,
        e.RefDate,
        e.RefType,
        ROW_NUMBER() OVER (
            PARTITION BY e.RefDate, e.Franchise, e.RefType
            ORDER BY t.Calendar_Date
        ) - 1 AS OffsetIndex
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Time` AS t
    CROSS JOIN (
        SELECT ToRf AS Franchise, DATE(ActualDepartureDate) AS RefDate, 'DEP' AS RefType
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_KPI_Stg`
        WHERE ActualDepartureDate IS NOT NULL
        UNION DISTINCT
        SELECT ToRf, DATE(ActualArrivalDate), 'ARR'
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_KPI_Stg`
        WHERE ActualArrivalDate IS NOT NULL
    ) AS e
    LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIExcludedDates` AS ex
        ON t.Calendar_Date = ex.Date
       AND ex.Franchise = e.Franchise
    WHERE t.Calendar_Date >= e.RefDate
      AND UPPER(t.week_day_flag) = 'Y'
      AND ex.Comment IS NULL;

    SET v_Ended = CURRENT_DATETIME();
    CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
        CONCAT(v_Component, ' (', v_Step, ')'),
        p_ProcessID, v_Started, v_Ended, v_Result, v_ErrorMessage,
        v_MaxInsertId, v_MaxUpdateId, -1
    );

    -- -----------------------------------------------------------------------
    -- Step 3: Updates
    -- -----------------------------------------------------------------------
    SET v_Step = 'Updates';
    SET v_Started = CURRENT_DATETIME();
    SET v_Loaded = CURRENT_DATETIME();

    BEGIN
        MERGE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI_Daily` AS Tgt
        USING (
            SELECT
                m.*,
                wd_arr.Calendar_Date AS KPIArrivalDate,
                wd_att.Calendar_Date AS KPIAttemptedDate,
                wd_adj.Calendar_Date AS KPIAttemptedDateAdjust
            FROM (
                SELECT
                    COALESCE(Src.LabelNo, Tgt.LabelNo) AS LabelNo,
                    COALESCE(Src.CountryCode, Tgt.CountryCode) AS CountryCode,
                    COALESCE(Src.Category, Tgt.Category) AS Category,
                    Src.CreatedOn,
                    COALESCE(Src.ServiceType, Tgt.ServiceType) AS ServiceType,
                    Src.RealisedDate,
                    Src.FromRf,
                    Src.ToRf,
                    COALESCE(Src.SLA, Tgt.SLA) AS SLA,
                    COALESCE(Src.KPIPickup, Tgt.KPIPickup) AS KPIPickup,
                    COALESCE(Src.KPILEA, Tgt.KPILEA) AS KPILEA,
                    COALESCE(Src.KPIDelivery, Tgt.KPIDelivery) AS KPIDelivery,
                    COALESCE(Src.KPIPickupImpact, Tgt.KPIPickupImpact) AS KPIPickupImpact,
                    COALESCE(Src.KPILEAImpact, Tgt.KPILEAImpact) AS KPILEAImpact,
                    COALESCE(Src.KPIDeliveryImpact, Tgt.KPIDeliveryImpact) AS KPIDeliveryImpact,
                    COALESCE(Src.DueDate, Tgt.DueDate) AS DueDate,
                    COALESCE(Src.KPIDepartureDate, Tgt.KPIDepartureDate) AS KPIDepartureDate,

                    IF(Src.ActualDepartureDate IS NOT NULL
                       AND Src.ActualDepartureDate < COALESCE(Tgt.ActualDepartureDate, v_FutureDate),
                       Src.ActualDepartureDate, Tgt.ActualDepartureDate) AS ActualDepartureDate,
                    IF(Src.ActualDepartureDate IS NOT NULL
                       AND Src.ActualDepartureDate < COALESCE(Tgt.ActualDepartureDate, v_FutureDate),
                       Src.ActualDepartureRF, Tgt.ActualDepartureRF) AS ActualDepartureRF,
                    IF(Src.ActualDepartureDate IS NOT NULL
                       AND Src.ActualDepartureDate < COALESCE(Tgt.ActualDepartureDate, v_FutureDate),
                       Src.ActualDepartureCF, Tgt.ActualDepartureCF) AS ActualDepartureCF,
                    IF(Src.ActualDepartureDate IS NOT NULL
                       AND Src.ActualDepartureDate < COALESCE(Tgt.ActualDepartureDate, v_FutureDate),
                       Src.ActualDepartureType, Tgt.ActualDepartureType) AS ActualDepartureType,
                    IF(Src.ActualDepartureDate IS NOT NULL
                       AND Src.ActualDepartureDate < COALESCE(Tgt.ActualDepartureDate, v_FutureDate),
                       Src.ActualDepartureStatus, Tgt.ActualDepartureStatus) AS ActualDepartureStatus,

                    IF(Src.ActualFirstArrivalDate IS NOT NULL
                       AND Src.ActualFirstArrivalDate < COALESCE(Tgt.ActualFirstArrivalDate, v_FutureDate),
                       Src.ActualFirstArrivalDate, Tgt.ActualFirstArrivalDate) AS ActualFirstArrivalDate,
                    IF(Src.ActualFirstArrivalDate IS NOT NULL
                       AND Src.ActualFirstArrivalDate < COALESCE(Tgt.ActualFirstArrivalDate, v_FutureDate),
                       Src.ActualFirstArrivalRF, Tgt.ActualFirstArrivalRF) AS ActualFirstArrivalRF,
                    IF(Src.ActualFirstArrivalDate IS NOT NULL
                       AND Src.ActualFirstArrivalDate < COALESCE(Tgt.ActualFirstArrivalDate, v_FutureDate),
                       Src.ActualFirstArrivalCF, Tgt.ActualFirstArrivalCF) AS ActualFirstArrivalCF,
                    IF(Src.ActualFirstArrivalDate IS NOT NULL
                       AND Src.ActualFirstArrivalDate < COALESCE(Tgt.ActualFirstArrivalDate, v_FutureDate),
                       Src.ActualFirstArrivalType, Tgt.ActualFirstArrivalType) AS ActualFirstArrivalType,
                    IF(Src.ActualFirstArrivalDate IS NOT NULL
                       AND Src.ActualFirstArrivalDate < COALESCE(Tgt.ActualFirstArrivalDate, v_FutureDate),
                       Src.ActualFirstArrivalStatus, Tgt.ActualFirstArrivalStatus) AS ActualFirstArrivalStatus,

                    IF(Src.ActualArrivalDate IS NOT NULL
                       AND Src.ActualArrivalDate < COALESCE(Tgt.ActualArrivalDate, v_FutureDate),
                       Src.ActualArrivalDate, Tgt.ActualArrivalDate) AS ActualArrivalDate,
                    IF(Src.ActualArrivalDate IS NOT NULL
                       AND Src.ActualArrivalDate < COALESCE(Tgt.ActualArrivalDate, v_FutureDate),
                       Src.ActualArrivalRF, Tgt.ActualArrivalRF) AS ActualArrivalRF,
                    IF(Src.ActualArrivalDate IS NOT NULL
                       AND Src.ActualArrivalDate < COALESCE(Tgt.ActualArrivalDate, v_FutureDate),
                       Src.ActualArrivalCF, Tgt.ActualArrivalCF) AS ActualArrivalCF,
                    IF(Src.ActualArrivalDate IS NOT NULL
                       AND Src.ActualArrivalDate < COALESCE(Tgt.ActualArrivalDate, v_FutureDate),
                       Src.ActualArrivalType, Tgt.ActualArrivalType) AS ActualArrivalType,
                    IF(Src.ActualArrivalDate IS NOT NULL
                       AND Src.ActualArrivalDate < COALESCE(Tgt.ActualArrivalDate, v_FutureDate),
                       Src.ActualArrivalStatus, Tgt.ActualArrivalStatus) AS ActualArrivalStatus,

                    IF(Src.ActualAttemptedDate IS NOT NULL
                       AND Src.ActualAttemptedDate < COALESCE(Tgt.ActualAttemptedDate, v_FutureDate),
                       Src.ActualAttemptedDate, Tgt.ActualAttemptedDate) AS ActualAttemptedDate,
                    IF(Src.ActualAttemptedDate IS NOT NULL
                       AND Src.ActualAttemptedDate < COALESCE(Tgt.ActualAttemptedDate, v_FutureDate),
                       Src.ActualAttemptedRF, Tgt.ActualAttemptedRF) AS ActualAttemptedRF,
                    IF(Src.ActualAttemptedDate IS NOT NULL
                       AND Src.ActualAttemptedDate < COALESCE(Tgt.ActualAttemptedDate, v_FutureDate),
                       Src.ActualAttemptedCF, Tgt.ActualAttemptedCF) AS ActualAttemptedCF,
                    IF(Src.ActualAttemptedDate IS NOT NULL
                       AND Src.ActualAttemptedDate < COALESCE(Tgt.ActualAttemptedDate, v_FutureDate),
                       Src.ActualAttemptedType, Tgt.ActualAttemptedType) AS ActualAttemptedType,
                    IF(Src.ActualAttemptedDate IS NOT NULL
                       AND Src.ActualAttemptedDate < COALESCE(Tgt.ActualAttemptedDate, v_FutureDate),
                       Src.ActualAttemptedStatus, Tgt.ActualAttemptedStatus) AS ActualAttemptedStatus,

                    IF(Src.ActualDeliveryScanDate IS NOT NULL
                       AND Src.ActualDeliveryScanDate < COALESCE(Tgt.ActualDeliveryScanDate, v_FutureDate),
                       Src.ActualDeliveryScanDate, Tgt.ActualDeliveryScanDate) AS ActualDeliveryScanDate,
                    IF(Src.ActualDeliveryScanDate IS NOT NULL
                       AND Src.ActualDeliveryScanDate < COALESCE(Tgt.ActualDeliveryScanDate, v_FutureDate),
                       Src.ActualDeliveryRF, Tgt.ActualDeliveryRF) AS ActualDeliveryRF,
                    IF(Src.ActualDeliveryScanDate IS NOT NULL
                       AND Src.ActualDeliveryScanDate < COALESCE(Tgt.ActualDeliveryScanDate, v_FutureDate),
                       Src.ActualDeliveryCF, Tgt.ActualDeliveryCF) AS ActualDeliveryCF,
                    IF(Src.ActualDeliveryScanDate IS NOT NULL
                       AND Src.ActualDeliveryScanDate < COALESCE(Tgt.ActualDeliveryScanDate, v_FutureDate),
                       Src.ActualDeliveryType, Tgt.ActualDeliveryType) AS ActualDeliveryType,
                    IF(Src.ActualDeliveryScanDate IS NOT NULL
                       AND Src.ActualDeliveryScanDate < COALESCE(Tgt.ActualDeliveryScanDate, v_FutureDate),
                       Src.ActualDeliveryStatus, Tgt.ActualDeliveryStatus) AS ActualDeliveryStatus,

                    IF(Src.LastScanDate IS NOT NULL
                       AND Src.LastScanDate > COALESCE(Tgt.LastScanDate, v_EarlyDate),
                       Src.LastScanDate, Tgt.LastScanDate) AS LastScanDate,
                    IF(Src.LastScanDate IS NOT NULL
                       AND Src.LastScanDate > COALESCE(Tgt.LastScanDate, v_EarlyDate),
                       Src.LastScanRF, Tgt.LastScanRF) AS LastScanRF,
                    IF(Src.LastScanDate IS NOT NULL
                       AND Src.LastScanDate > COALESCE(Tgt.LastScanDate, v_EarlyDate),
                       Src.LastScanCF, Tgt.LastScanCF) AS LastScanCF,
                    IF(Src.LastScanDate IS NOT NULL
                       AND Src.LastScanDate > COALESCE(Tgt.LastScanDate, v_EarlyDate),
                       Src.LastScanType, Tgt.LastScanType) AS LastScanType,
                    IF(Src.LastScanDate IS NOT NULL
                       AND Src.LastScanDate > COALESCE(Tgt.LastScanDate, v_EarlyDate),
                       Src.LastScanStatus, Tgt.LastScanStatus) AS LastScanStatus,

                    COALESCE(Src.MISScanDate, Tgt.MISScanDate) AS MISScanDate,
                    COALESCE(Src.MISRF, Tgt.MISRF) AS MISRF,

                    -- Raw staging columns for EXCEPT-style change detection (Src vs Tgt, not merged)
                    Src.Category                AS StgCategory,
                    Src.ServiceType             AS StgServiceType,
                    Src.CreatedOn               AS StgCreatedOn,
                    Src.RealisedDate            AS StgRealisedDate,
                    Src.SLA                     AS StgSLA,
                    Src.KPIPickup               AS StgKPIPickup,
                    Src.KPILEA                  AS StgKPILEA,
                    Src.KPIDelivery             AS StgKPIDelivery,
                    Src.KPIPickupImpact         AS StgKPIPickupImpact,
                    Src.KPILEAImpact            AS StgKPILEAImpact,
                    Src.KPIDeliveryImpact       AS StgKPIDeliveryImpact,
                    Src.DueDate                 AS StgDueDate,
                    Src.KPIDepartureDate        AS StgKPIDepartureDate,
                    Src.KPIArrivalDate          AS StgKPIArrivalDate,
                    Src.KPIAttemptedDate        AS StgKPIAttemptedDate,
                    Src.KPIAttemptedDateAdjust  AS StgKPIAttemptedDateAdjust,
                    Src.ActualDepartureDate     AS StgActualDepartureDate,
                    Src.ActualDepartureRF       AS StgActualDepartureRF,
                    Src.ActualDepartureCF       AS StgActualDepartureCF,
                    Src.ActualDepartureType     AS StgActualDepartureType,
                    Src.ActualDepartureStatus   AS StgActualDepartureStatus,
                    Src.ActualFirstArrivalDate  AS StgActualFirstArrivalDate,
                    Src.ActualFirstArrivalRF    AS StgActualFirstArrivalRF,
                    Src.ActualFirstArrivalCF    AS StgActualFirstArrivalCF,
                    Src.ActualFirstArrivalType  AS StgActualFirstArrivalType,
                    Src.ActualFirstArrivalStatus AS StgActualFirstArrivalStatus,
                    Src.ActualArrivalDate       AS StgActualArrivalDate,
                    Src.ActualArrivalRF         AS StgActualArrivalRF,
                    Src.ActualArrivalCF         AS StgActualArrivalCF,
                    Src.ActualArrivalType       AS StgActualArrivalType,
                    Src.ActualArrivalStatus     AS StgActualArrivalStatus,
                    Src.ActualAttemptedDate     AS StgActualAttemptedDate,
                    Src.ActualAttemptedRF       AS StgActualAttemptedRF,
                    Src.ActualAttemptedCF       AS StgActualAttemptedCF,
                    Src.ActualAttemptedType     AS StgActualAttemptedType,
                    Src.ActualAttemptedStatus   AS StgActualAttemptedStatus,
                    Src.ActualDeliveryScanDate  AS StgActualDeliveryScanDate,
                    Src.ActualDeliveryRF        AS StgActualDeliveryRF,
                    Src.ActualDeliveryCF        AS StgActualDeliveryCF,
                    Src.ActualDeliveryType      AS StgActualDeliveryType,
                    Src.ActualDeliveryStatus    AS StgActualDeliveryStatus,
                    Src.LastScanDate            AS StgLastScanDate,
                    Src.LastScanRF              AS StgLastScanRF,
                    Src.LastScanCF              AS StgLastScanCF,
                    Src.LastScanType            AS StgLastScanType,
                    Src.LastScanStatus          AS StgLastScanStatus,
                    Src.MISScanDate             AS StgMISScanDate,
                    Src.MISRF                   AS StgMISRF
                FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI_Daily` AS Tgt
                JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_KPI_Stg` AS Src
                    ON Src.LabelNo = Tgt.LabelNo
                JOIN LabelsToProcess AS sel
                    ON sel.LabelNo = Src.LabelNo
                WHERE sel.UpdateId IS NOT NULL
            ) AS m
            LEFT JOIN WorkingDays AS wd_arr
                ON wd_arr.Franchise = m.ToRf
               AND wd_arr.RefDate = DATE(m.ActualDepartureDate)
               AND wd_arr.RefType = 'DEP'
               AND wd_arr.OffsetIndex = COALESCE(m.KPILEA, 1)
            LEFT JOIN WorkingDays AS wd_att
                ON wd_att.Franchise = m.ToRf
               AND wd_att.RefDate = DATE(m.ActualArrivalDate)
               AND wd_att.RefType = 'ARR'
               AND wd_att.OffsetIndex = COALESCE(m.KPIDelivery, 1)
            LEFT JOIN WorkingDays AS wd_adj
                ON wd_adj.Franchise = m.ToRf
               AND wd_adj.RefDate = DATE(m.ActualDepartureDate)
               AND wd_adj.RefType = 'DEP'
               AND wd_adj.OffsetIndex = COALESCE(m.KPILEA + m.KPIDelivery, 1)
        ) AS Src
        ON Tgt.LabelNo = Src.LabelNo
        WHEN MATCHED AND (
            -- EXCEPT parity: compare raw staging (Stg*) vs existing target — only update when data changed
            IFNULL(Tgt.Category, '') != IFNULL(Src.StgCategory, '') OR
            IFNULL(Tgt.ServiceType, '') != IFNULL(Src.StgServiceType, '') OR
            IFNULL(CAST(Tgt.CreatedOn AS STRING), '') != IFNULL(CAST(Src.StgCreatedOn AS STRING), '') OR
            IFNULL(CAST(Tgt.RealisedDate AS STRING), '') != IFNULL(CAST(Src.StgRealisedDate AS STRING), '') OR
            IFNULL(CAST(Tgt.SLA AS STRING), '') != IFNULL(CAST(Src.StgSLA AS STRING), '') OR
            IFNULL(CAST(Tgt.KPIPickup AS STRING), '') != IFNULL(CAST(Src.StgKPIPickup AS STRING), '') OR
            IFNULL(CAST(Tgt.KPILEA AS STRING), '') != IFNULL(CAST(Src.StgKPILEA AS STRING), '') OR
            IFNULL(CAST(Tgt.KPIDelivery AS STRING), '') != IFNULL(CAST(Src.StgKPIDelivery AS STRING), '') OR
            IFNULL(CAST(Tgt.KPIPickupImpact AS STRING), '') != IFNULL(CAST(Src.StgKPIPickupImpact AS STRING), '') OR
            IFNULL(CAST(Tgt.KPILEAImpact AS STRING), '') != IFNULL(CAST(Src.StgKPILEAImpact AS STRING), '') OR
            IFNULL(CAST(Tgt.KPIDeliveryImpact AS STRING), '') != IFNULL(CAST(Src.StgKPIDeliveryImpact AS STRING), '') OR
            IFNULL(CAST(Tgt.DueDate AS STRING), '') != IFNULL(CAST(Src.StgDueDate AS STRING), '') OR
            IFNULL(CAST(Tgt.KPIDepartureDate AS STRING), '') != IFNULL(CAST(Src.StgKPIDepartureDate AS STRING), '') OR
            IFNULL(CAST(Tgt.KPIArrivalDate AS STRING), '') != IFNULL(CAST(Src.StgKPIArrivalDate AS STRING), '') OR
            IFNULL(CAST(Tgt.KPIAttemptedDate AS STRING), '') != IFNULL(CAST(Src.StgKPIAttemptedDate AS STRING), '') OR
            IFNULL(CAST(Tgt.KPIAttemptedDateAdjust AS STRING), '') != IFNULL(CAST(Src.StgKPIAttemptedDateAdjust AS STRING), '') OR
            IFNULL(CAST(Tgt.ActualDepartureDate AS STRING), '') != IFNULL(CAST(Src.StgActualDepartureDate AS STRING), '') OR
            IFNULL(Tgt.ActualDepartureRF, '') != IFNULL(Src.StgActualDepartureRF, '') OR
            IFNULL(Tgt.ActualDepartureCF, '') != IFNULL(Src.StgActualDepartureCF, '') OR
            IFNULL(Tgt.ActualDepartureType, '') != IFNULL(Src.StgActualDepartureType, '') OR
            IFNULL(Tgt.ActualDepartureStatus, '') != IFNULL(Src.StgActualDepartureStatus, '') OR
            IFNULL(CAST(Tgt.ActualFirstArrivalDate AS STRING), '') != IFNULL(CAST(Src.StgActualFirstArrivalDate AS STRING), '') OR
            IFNULL(Tgt.ActualFirstArrivalRF, '') != IFNULL(Src.StgActualFirstArrivalRF, '') OR
            IFNULL(Tgt.ActualFirstArrivalCF, '') != IFNULL(Src.StgActualFirstArrivalCF, '') OR
            IFNULL(Tgt.ActualFirstArrivalType, '') != IFNULL(Src.StgActualFirstArrivalType, '') OR
            IFNULL(Tgt.ActualFirstArrivalStatus, '') != IFNULL(Src.StgActualFirstArrivalStatus, '') OR
            IFNULL(CAST(Tgt.ActualArrivalDate AS STRING), '') != IFNULL(CAST(Src.StgActualArrivalDate AS STRING), '') OR
            IFNULL(Tgt.ActualArrivalRF, '') != IFNULL(Src.StgActualArrivalRF, '') OR
            IFNULL(Tgt.ActualArrivalCF, '') != IFNULL(Src.StgActualArrivalCF, '') OR
            IFNULL(Tgt.ActualArrivalType, '') != IFNULL(Src.StgActualArrivalType, '') OR
            IFNULL(Tgt.ActualArrivalStatus, '') != IFNULL(Src.StgActualArrivalStatus, '') OR
            IFNULL(CAST(Tgt.ActualAttemptedDate AS STRING), '') != IFNULL(CAST(Src.StgActualAttemptedDate AS STRING), '') OR
            IFNULL(Tgt.ActualAttemptedRF, '') != IFNULL(Src.StgActualAttemptedRF, '') OR
            IFNULL(Tgt.ActualAttemptedCF, '') != IFNULL(Src.StgActualAttemptedCF, '') OR
            IFNULL(Tgt.ActualAttemptedType, '') != IFNULL(Src.StgActualAttemptedType, '') OR
            IFNULL(Tgt.ActualAttemptedStatus, '') != IFNULL(Src.StgActualAttemptedStatus, '') OR
            IFNULL(CAST(Tgt.ActualDeliveryScanDate AS STRING), '') != IFNULL(CAST(Src.StgActualDeliveryScanDate AS STRING), '') OR
            IFNULL(Tgt.ActualDeliveryRF, '') != IFNULL(Src.StgActualDeliveryRF, '') OR
            IFNULL(Tgt.ActualDeliveryCF, '') != IFNULL(Src.StgActualDeliveryCF, '') OR
            IFNULL(Tgt.ActualDeliveryType, '') != IFNULL(Src.StgActualDeliveryType, '') OR
            IFNULL(Tgt.ActualDeliveryStatus, '') != IFNULL(Src.StgActualDeliveryStatus, '') OR
            IFNULL(CAST(Tgt.LastScanDate AS STRING), '') != IFNULL(CAST(Src.StgLastScanDate AS STRING), '') OR
            IFNULL(Tgt.LastScanRF, '') != IFNULL(Src.StgLastScanRF, '') OR
            IFNULL(Tgt.LastScanCF, '') != IFNULL(Src.StgLastScanCF, '') OR
            IFNULL(Tgt.LastScanType, '') != IFNULL(Src.StgLastScanType, '') OR
            IFNULL(Tgt.LastScanStatus, '') != IFNULL(Src.StgLastScanStatus, '') OR
            IFNULL(CAST(Tgt.MISScanDate AS STRING), '') != IFNULL(CAST(Src.StgMISScanDate AS STRING), '') OR
            IFNULL(Tgt.MISRF, '') != IFNULL(Src.StgMISRF, '')
        )
        THEN UPDATE SET
            CountryCode             = Src.CountryCode,
            Category                = Src.Category,
            CreatedOn               = Src.CreatedOn,
            ServiceType             = Src.ServiceType,
            RealisedDate            = Src.RealisedDate,
            SLA                     = Src.SLA,
            KPIPickup               = Src.KPIPickup,
            KPILEA                  = Src.KPILEA,
            KPIDelivery             = Src.KPIDelivery,
            KPIPickupImpact         = Src.KPIPickupImpact,
            KPILEAImpact            = Src.KPILEAImpact,
            KPIDeliveryImpact       = Src.KPIDeliveryImpact,
            DueDate                 = Src.DueDate,
            KPIDepartureDate        = Src.KPIDepartureDate,
            KPIArrivalDate          = Src.KPIArrivalDate,
            KPIAttemptedDate        = Src.KPIAttemptedDate,
            KPIAttemptedDateAdjust  = Src.KPIAttemptedDateAdjust,
            ActualDepartureDate     = Src.ActualDepartureDate,
            ActualDepartureRF       = Src.ActualDepartureRF,
            ActualDepartureCF       = Src.ActualDepartureCF,
            ActualDepartureType     = Src.ActualDepartureType,
            ActualDepartureStatus   = Src.ActualDepartureStatus,
            ActualFirstArrivalDate  = Src.ActualFirstArrivalDate,
            ActualFirstArrivalRF    = Src.ActualFirstArrivalRF,
            ActualFirstArrivalCF    = Src.ActualFirstArrivalCF,
            ActualFirstArrivalType  = Src.ActualFirstArrivalType,
            ActualFirstArrivalStatus = Src.ActualFirstArrivalStatus,
            ActualArrivalDate       = Src.ActualArrivalDate,
            ActualArrivalRF         = Src.ActualArrivalRF,
            ActualArrivalCF         = Src.ActualArrivalCF,
            ActualArrivalType       = Src.ActualArrivalType,
            ActualArrivalStatus     = Src.ActualArrivalStatus,
            ActualAttemptedDate     = Src.ActualAttemptedDate,
            ActualAttemptedRF       = Src.ActualAttemptedRF,
            ActualAttemptedCF       = Src.ActualAttemptedCF,
            ActualAttemptedType     = Src.ActualAttemptedType,
            ActualAttemptedStatus   = Src.ActualAttemptedStatus,
            ActualDeliveryScanDate  = Src.ActualDeliveryScanDate,
            ActualDeliveryRF        = Src.ActualDeliveryRF,
            ActualDeliveryCF        = Src.ActualDeliveryCF,
            ActualDeliveryType      = Src.ActualDeliveryType,
            ActualDeliveryStatus    = Src.ActualDeliveryStatus,
            LastScanDate            = Src.LastScanDate,
            LastScanRF              = Src.LastScanRF,
            LastScanCF              = Src.LastScanCF,
            LastScanType            = Src.LastScanType,
            LastScanStatus          = Src.LastScanStatus,
            MISScanDate             = Src.MISScanDate,
            MISRF                   = Src.MISRF,
            LastUpdated             = v_Loaded,
            ProcessID               = p_ProcessID;

        SET v_Updated = @@row_count;

        SET v_Ended = CURRENT_DATETIME();
        CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
            CONCAT(v_Component, ' (', v_Step, ')'),
            p_ProcessID, v_Started, v_Ended, v_Result, v_ErrorMessage,
            v_Inserted, v_Updated, -1
        );

    EXCEPTION WHEN ERROR THEN
        SET v_Result = CONCAT('Failed (', v_Step, ')');
        SET v_ErrorMessage = @@error.message;
        SET v_Ended = CURRENT_DATETIME();
        CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
            CONCAT(v_Component, ' (', v_Step, ')'),
            p_ProcessID, v_Started, v_Ended, v_Result, v_ErrorMessage,
            v_Inserted, v_Updated, -1
        );
        RETURN;
    END;

    -- -----------------------------------------------------------------------
    -- Step 4: Inserts (skipped if updates failed)
    -- -----------------------------------------------------------------------
    IF v_Result != 'Success' THEN
        RETURN;
    END IF;

    SET v_Step = 'Inserts';
    SET v_Started = CURRENT_DATETIME();
    SET v_Loaded = CURRENT_DATETIME();

    BEGIN
        INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI_Daily`
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
            Src.LabelNo,
            Src.CountryCode,
            Src.Category,
            Src.CreatedOn,
            Src.ServiceType,
            Src.RealisedDate,
            Src.SLA,
            Src.KPIPickup,
            Src.KPILEA,
            Src.KPIDelivery,
            Src.KPIPickupImpact,
            Src.KPILEAImpact,
            Src.KPIDeliveryImpact,
            Src.DueDate,
            Src.KPIDepartureDate,
            wd_arr.Calendar_Date,
            wd_att.Calendar_Date,
            wd_adj.Calendar_Date,
            Src.ActualDepartureDate,
            Src.ActualDepartureRF,
            Src.ActualDepartureCF,
            Src.ActualDepartureType,
            Src.ActualDepartureStatus,
            Src.ActualFirstArrivalDate,
            Src.ActualFirstArrivalRF,
            Src.ActualFirstArrivalCF,
            Src.ActualFirstArrivalType,
            Src.ActualFirstArrivalStatus,
            Src.ActualArrivalDate,
            Src.ActualArrivalRF,
            Src.ActualArrivalCF,
            Src.ActualArrivalType,
            Src.ActualArrivalStatus,
            Src.ActualAttemptedDate,
            Src.ActualAttemptedRF,
            Src.ActualAttemptedCF,
            Src.ActualAttemptedType,
            Src.ActualAttemptedStatus,
            Src.ActualDeliveryScanDate,
            Src.ActualDeliveryRF,
            Src.ActualDeliveryCF,
            Src.ActualDeliveryType,
            Src.ActualDeliveryStatus,
            Src.LastScanDate,
            Src.LastScanRF,
            Src.LastScanCF,
            Src.LastScanType,
            Src.LastScanStatus,
            Src.MISScanDate,
            Src.MISRF,
            v_Loaded,
            p_ProcessID
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_KPI_Stg` AS Src
        JOIN LabelsToProcess AS Sel
            ON Sel.LabelNo = Src.LabelNo
        LEFT JOIN WorkingDays AS wd_arr
            ON wd_arr.Franchise = Src.ToRf
           AND wd_arr.RefDate = DATE(Src.ActualDepartureDate)
           AND wd_arr.RefType = 'DEP'
           AND wd_arr.OffsetIndex = COALESCE(Src.KPILEA, 1)
        LEFT JOIN WorkingDays AS wd_att
            ON wd_att.Franchise = Src.ToRf
           AND wd_att.RefDate = DATE(Src.ActualArrivalDate)
           AND wd_att.RefType = 'ARR'
           AND wd_att.OffsetIndex = COALESCE(Src.KPIDelivery, 1)
        LEFT JOIN WorkingDays AS wd_adj
            ON wd_adj.Franchise = Src.ToRf
           AND wd_adj.RefDate = DATE(Src.ActualDepartureDate)
           AND wd_adj.RefType = 'DEP'
           AND wd_adj.OffsetIndex = COALESCE(Src.KPILEA + Src.KPIDelivery, 1)
        WHERE Sel.InsertId IS NOT NULL;

        SET v_Inserted = @@row_count;

        SET v_Ended = CURRENT_DATETIME();
        CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
            CONCAT(v_Component, ' (', v_Step, ')'),
            p_ProcessID, v_Started, v_Ended, v_Result, v_ErrorMessage,
            v_Inserted, v_Updated, -1
        );

    EXCEPTION WHEN ERROR THEN
        SET v_Result = CONCAT('Failed (', v_Step, ')');
        SET v_ErrorMessage = @@error.message;
        SET v_Ended = CURRENT_DATETIME();
        CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
            CONCAT(v_Component, ' (', v_Step, ')'),
            p_ProcessID, v_Started, v_Ended, v_Result, v_ErrorMessage,
            v_Inserted, v_Updated, -1
        );
        RETURN;
    END;

    DROP TABLE IF EXISTS LabelsToProcess;
    DROP TABLE IF EXISTS WorkingDays;

END;
