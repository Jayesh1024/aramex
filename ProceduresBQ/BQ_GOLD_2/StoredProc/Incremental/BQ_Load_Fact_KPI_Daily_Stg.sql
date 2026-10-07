CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_Load_Fact_KPI_Daily_Stg`(
    IN p_ProcessID INT64, 
    IN p_StartDateOverRide STRING, 
    IN p_EndDateOverRide STRING
)
BEGIN
    -- Variables Setup
    DECLARE v_Component STRING DEFAULT 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Load_Fact_KPI_Daily_Stg';
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;

    BEGIN
        -- Clear staging table
        TRUNCATE TABLE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_KPI_Stg`;

        -- INSERT START
        INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_KPI_Stg` (
            LabelNo, CountryCode, Category, ServiceType, RealisedDate, CreatedOn, FromRf, ToRf, SLA, 
            KPIPickup, KPILEA, KPIDelivery, KPIPickupImpact, KPILEAImpact, KPIDeliveryImpact, DueDate, 
            KPIDepartureDate, KPIArrivalDate, KPIAttemptedDate, KPIAttemptedDateAdjust, ActualDepartureDate, 
            ActualDepartureRF, ActualDepartureCF, ActualDepartureType, ActualDepartureStatus, ActualFirstArrivalDate, 
            ActualFirstArrivalRF, ActualFirstArrivalCF, ActualFirstArrivalType, ActualFirstArrivalStatus, ActualArrivalDate, 
            ActualArrivalRF, ActualArrivalCF, ActualArrivalType, ActualArrivalStatus, ActualAttemptedDate, ActualAttemptedRF, 
            ActualAttemptedCF, ActualAttemptedType, ActualAttemptedStatus, ActualDeliveryScanDate, ActualDeliveryRF, 
            ActualDeliveryCF, ActualDeliveryType, ActualDeliveryStatus, LastScanDate, LastScanRF, LastScanCF, 
            LastScanType, LastScanStatus, MISScanDate, MISRF, CustomerId, FromCF, ToCf, ToPostalCode, ToLocality
        )
        WITH BaseData AS (
            SELECT
                L.LabelNo, L.CountryCode, L.FromRf, L.ToRF, L.CreatedOn, L.RealisedDate,
                DATE(L.RealisedDate) AS RealisedDateAsDateOnly,
                L.FranchiseeCode, L.CourierNumber, L.ScanDate, L.ScanDateTime, L.ScanType, L.ScanStatus,
                G.KPIGroup,
                L.CustomerId, L.FromCF, L.ToCf, L.ToPostalCode, L.ToLocality, L.Zone, L.TrackAndTraceID,
                CASE 
                    WHEN (L.FranchiseeCode IS NULL AND L.Zone NOT IN ('SHU', 'SHT')) OR L.ToRf IN ('LEA', 'TMW') THEN 'Other'
                    WHEN L.FromRf = L.ToRf THEN 'Local'
                    ELSE 'Interbranch' 
                END AS Category,
                CASE WHEN s.Labelno IS NOT NULL THEN 'P' ELSE 'E' END AS ServiceType,
                k.Days as kdays,
                COALESCE(k.EconomyDays, 0) as EconomyDays,
                COALESCE(k.PriorityDays, 0) as PriorityDays,
                COALESCE(t.MaxDays, 0) as MaxDays,
                COALESCE(t.MaxDaysWithExceptionEconomy, 0) as MaxDaysWithExceptionEconomy,
                COALESCE(t.MaxDaysWithExceptionPriority, 0) as MaxDaysWithExceptionPriority
            FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_KPI_Src_Stg` AS L
            LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIScanGroups` G 
                ON G.ScanStatus = L.ScanStatus AND G.CountryCode = L.CountryCode
            LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIMatrix` k 
                ON L.FromRf = k.PickupFranchise AND (CASE WHEN L.ToRf = '' THEN L.Zone ELSE L.ToRf END) = k.DeliveryFranchise
            LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_TSS_PostCodeMaster` t 
                ON lower(L.ToLocality) = lower(t.Suburb) AND L.ToPostalCode = CAST(t.Postcode AS STRING) AND t.CountryCode = 1
            LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Product_ServiceItem` s  
                ON s.ProductCode in ('MYFPRI','MYFPRIORITY') AND s.Labelno = L.LabelNo 
        ),

        RankedScans AS (
            SELECT 
                *,
                ROW_NUMBER() OVER(PARTITION BY LabelNo ORDER BY ScanDateTime DESC, TrackAndTraceID DESC) as ScanReverse,
                ROW_NUMBER() OVER(PARTITION BY LabelNo, KPIGroup ORDER BY IF(CourierNumber != 'API', 1, 0), ScanDateTime, TrackAndTraceID) as KPIDepartureOrder,
                ROW_NUMBER() OVER(PARTITION BY LabelNo, KPIGroup ORDER BY ScanDateTime, TrackAndTraceID) as KPIGroupOrder,
                ROW_NUMBER() OVER(PARTITION BY LabelNo, FranchiseeCode ORDER BY ScanDateTime, TrackAndTraceID) as FranchiseeOrderArrival,
                ROW_NUMBER() OVER(PARTITION BY LabelNo ORDER BY IF(KPIGroup IS NULL, 1, 0), ScanDateTime, TrackAndTraceID) as KPIGroupNotNull
            FROM BaseData
        ),

        AggregatedData AS (
            SELECT 
                LabelNo,
                MIN(CountryCode) as CountryCode,
                MIN(Category) as Category,
                MIN(ServiceType) as ServiceType,
                MIN(RealisedDate) as RealisedDate,
                MIN(CreatedOn) as CreatedOn,
                MIN(FromRf) as FromRf,
                MIN(ToRf) as ToRf,
                -- SLA Logic
                CAST(COALESCE(MIN(CASE WHEN ServiceType = 'P' THEN kdays + PriorityDays + MaxDaysWithExceptionPriority
                                    ELSE kdays + EconomyDays + MaxDaysWithExceptionEconomy END), 1) AS INT64) AS SLA,
                0 as KPIPickup,
                MIN(CASE WHEN FromRf = (CASE WHEN ToRf = '' THEN Zone ELSE ToRf END) THEN 0 ELSE kdays END) as KPILEA,
                MIN(MaxDays + CASE WHEN ServiceType = 'P' THEN PriorityDays ELSE EconomyDays END) as KPIDelivery,
                MIN(RealisedDateAsDateOnly) as RealisedDateAsDateOnly,
                
                -- Actual Departure
                MIN(IF(Category != 'Local' AND KPIGroup='Departure' AND KPIDepartureOrder = 1 AND FranchiseeCode = FromRf AND CourierNumber = 'API', ScanDateTime, NULL)) AS ActualDepartureDate,
                MIN(IF(Category != 'Local' AND KPIGroup='Departure' AND KPIDepartureOrder = 1 AND FranchiseeCode = FromRf AND CourierNumber = 'API', FranchiseeCode, NULL)) AS ActualDepartureRF,
                MIN(IF(Category != 'Local' AND KPIGroup='Departure' AND KPIDepartureOrder = 1 AND FranchiseeCode = FromRf AND CourierNumber = 'API', CourierNumber, NULL)) AS ActualDepartureCF,
                MIN(IF(Category != 'Local' AND KPIGroup='Departure' AND KPIDepartureOrder = 1 AND FranchiseeCode = FromRf AND CourierNumber = 'API', ScanType, NULL)) AS ActualDepartureType,
                MIN(IF(Category != 'Local' AND KPIGroup='Departure' AND KPIDepartureOrder = 1 AND FranchiseeCode = FromRf AND CourierNumber = 'API', ScanStatus, NULL)) AS ActualDepartureStatus,

                -- Actual First Arrival
                MIN(IF(IF(Category = 'Local', IF(KPIGroupNotNull = 1 AND KPIGroup != 'Departure', 1, 0), IF(FranchiseeOrderArrival = 1, 1, 0)) = 1 AND FranchiseeCode = ToRf, ScanDateTime, NULL)) AS ActualFirstArrivalDate,
                MIN(IF(IF(Category = 'Local', IF(KPIGroupNotNull = 1 AND KPIGroup != 'Departure', 1, 0), IF(FranchiseeOrderArrival = 1, 1, 0)) = 1 AND FranchiseeCode = ToRf, FranchiseeCode, NULL)) AS ActualFirstArrivalRF,
                MIN(IF(IF(Category = 'Local', IF(KPIGroupNotNull = 1 AND KPIGroup != 'Departure', 1, 0), IF(FranchiseeOrderArrival = 1, 1, 0)) = 1 AND FranchiseeCode = ToRf, CourierNumber, NULL)) AS ActualFirstArrivalCF,
                MIN(IF(IF(Category = 'Local', IF(KPIGroupNotNull = 1 AND KPIGroup != 'Departure', 1, 0), IF(FranchiseeOrderArrival = 1, 1, 0)) = 1 AND FranchiseeCode = ToRf, ScanType, NULL)) AS ActualFirstArrivalType,
                MIN(IF(IF(Category = 'Local', IF(KPIGroupNotNull = 1 AND KPIGroup != 'Departure', 1, 0), IF(FranchiseeOrderArrival = 1, 1, 0)) = 1 AND FranchiseeCode = ToRf, ScanStatus, NULL)) AS ActualFirstArrivalStatus,

                -- Actual Arrival (RID)
                MIN(IF(Category != 'Local' AND KPIGroup='Arrival' AND ScanStatus = 'RID' AND FranchiseeCode = ToRf AND CourierNumber = 'API', ScanDateTime, NULL)) AS ActualArrivalDate,
                MIN(IF(Category != 'Local' AND KPIGroup='Arrival' AND ScanStatus = 'RID' AND FranchiseeCode = ToRf AND CourierNumber = 'API', FranchiseeCode, NULL)) AS ActualArrivalRF,
                MIN(IF(Category != 'Local' AND KPIGroup='Arrival' AND ScanStatus = 'RID' AND FranchiseeCode = ToRf AND CourierNumber = 'API', CourierNumber, NULL)) AS ActualArrivalCF,
                MIN(IF(Category != 'Local' AND KPIGroup='Arrival' AND ScanStatus = 'RID' AND FranchiseeCode = ToRf AND CourierNumber = 'API', ScanType, NULL)) AS ActualArrivalType,
                MIN(IF(Category != 'Local' AND KPIGroup='Arrival' AND ScanStatus = 'RID' AND FranchiseeCode = ToRf AND CourierNumber = 'API', ScanStatus, NULL)) AS ActualArrivalStatus,

                -- Actual Attempted
                MIN(IF(KPIGroup='Attempted' AND KPIGroupOrder = 1, ScanDateTime, NULL)) AS ActualAttemptedDate,
                MIN(IF(KPIGroup='Attempted' AND KPIGroupOrder = 1, FranchiseeCode, NULL)) AS ActualAttemptedRF,
                MIN(IF(KPIGroup='Attempted' AND KPIGroupOrder = 1, CourierNumber, NULL)) AS ActualAttemptedCF,
                MIN(IF(KPIGroup='Attempted' AND KPIGroupOrder = 1, ScanType, NULL)) AS ActualAttemptedType,
                MIN(IF(KPIGroup='Attempted' AND KPIGroupOrder = 1, ScanStatus, NULL)) AS ActualAttemptedStatus,

                -- Actual Delivery
                MIN(IF(KPIGroup='Delivery' AND KPIGroupOrder = 1, ScanDateTime, NULL)) AS ActualDeliveryScanDate,
                MIN(IF(KPIGroup='Delivery' AND KPIGroupOrder = 1, FranchiseeCode, NULL)) AS ActualDeliveryRF,
                MIN(IF(KPIGroup='Delivery' AND KPIGroupOrder = 1, CourierNumber, NULL)) AS ActualDeliveryCF,
                MIN(IF(KPIGroup='Delivery' AND KPIGroupOrder = 1, ScanType, NULL)) AS ActualDeliveryType,
                MIN(IF(KPIGroup='Delivery' AND KPIGroupOrder = 1, ScanStatus, NULL)) AS ActualDeliveryStatus,

                -- Last Scan
                MIN(IF(ScanReverse = 1, ScanDateTime, NULL)) AS LastScanDate,
                MIN(IF(ScanReverse = 1, FranchiseeCode, NULL)) AS LastScanRF,
                MIN(IF(ScanReverse = 1, CourierNumber, NULL)) AS LastScanCF,
                MIN(IF(ScanReverse = 1, ScanType, NULL)) AS LastScanType,
                MIN(IF(ScanReverse = 1, ScanStatus, NULL)) AS LastScanStatus,

                -- MIS Scan
                MIN(IF(ScanStatus = 'MIS', ScanDateTime, NULL)) AS MISScanDate,
                MIN(IF(ScanStatus = 'MIS', FranchiseeCode, NULL)) AS MISRF,

                MIN(CustomerId) as CustomerId,
                MIN(FromCF) as FromCF,
                MIN(ToCf) as ToCf,
                MIN(ToPostalCode) as ToPostalCode,
                MIN(ToLocality) as ToLocality
            FROM RankedScans
            GROUP BY LabelNo
        ),

        -- Pre-calculate Calendar rankings
        DateRanking AS (
            SELECT 
                src.LabelNo,
                dt.Calendar_Date,
                ROW_NUMBER() OVER(PARTITION BY src.LabelNo ORDER BY dt.Calendar_Date ASC) - 1 AS WorkingDayIndex
            FROM AggregatedData src
            CROSS JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Time` dt
            LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIExcludedDates` ex
                ON dt.Calendar_Date = ex.Date 
                AND ex.CountryCode = src.CountryCode 
                AND ex.Franchise IN (src.FromRf, src.ToRf)
            WHERE dt.Calendar_Date >= src.RealisedDateAsDateOnly 
              AND dt.week_day_flag = 'Y' 
              AND ex.Comment IS NULL
        )

        SELECT 
            src.LabelNo, src.CountryCode, src.Category, src.ServiceType, src.RealisedDate, src.CreatedOn, src.FromRf, src.ToRf, src.SLA, 
            src.KPIPickup, src.KPILEA, src.KPIDelivery, 
            0 as KPIPickupImpact, 0 as KPILEAImpact, 0 as KPIDeliveryImpact,
            
            -- Dates from Ranking
            CAST(due.Calendar_Date AS DATETIME) AS DueDate,
            CAST(dep.Calendar_Date AS DATETIME) AS KPIDepartureDate,
            
            -- Explicitly cast NULLs to DATETIME to avoid INT64 inference error
            CAST(NULL AS DATETIME) as KPIArrivalDate, 
            CAST(NULL AS DATETIME) as KPIAttemptedDate, 
            CAST(NULL AS DATETIME) as KPIAttemptedDateAdjust,
            
            src.ActualDepartureDate, src.ActualDepartureRF, src.ActualDepartureCF, src.ActualDepartureType, src.ActualDepartureStatus,
            src.ActualFirstArrivalDate, src.ActualFirstArrivalRF, src.ActualFirstArrivalCF, src.ActualFirstArrivalType, src.ActualFirstArrivalStatus,
            src.ActualArrivalDate, src.ActualArrivalRF, src.ActualArrivalCF, src.ActualArrivalType, src.ActualArrivalStatus,
            src.ActualAttemptedDate, src.ActualAttemptedRF, src.ActualAttemptedCF, src.ActualAttemptedType, src.ActualAttemptedStatus,
            src.ActualDeliveryScanDate, src.ActualDeliveryRF, src.ActualDeliveryCF, src.ActualDeliveryType, src.ActualDeliveryStatus,
            src.LastScanDate, src.LastScanRF, src.LastScanCF, src.LastScanType, src.LastScanStatus,
            src.MISScanDate, src.MISRF,
            src.CustomerId, src.FromCF, src.ToCf, src.ToPostalCode, src.ToLocality
        FROM AggregatedData src
        LEFT JOIN DateRanking due ON src.LabelNo = due.LabelNo AND due.WorkingDayIndex = src.SLA
        LEFT JOIN DateRanking dep ON src.LabelNo = dep.LabelNo AND dep.WorkingDayIndex = 0;

        SET v_Inserted = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Standardize Call Logging block
    CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
        v_Component, 
        p_ProcessID, 
        v_Started, 
        CURRENT_DATETIME(), 
        v_Result, 
        v_ErrorMessage, 
        v_Inserted, 
        -1, 
        -1
    );
END;