{#-- ==========================================================================================
Routine:     Load_Fact_KPI_Daily_Stg
Description: Maintains the stats for InterBranch Pickup & Delivery KPIs
History:
  01/12/2022  B. Woods        Routine Written
--========================================================================================== --#}

CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id}}.Load_Fact_KPI_Daily_Stg`(
    IN p_ProcessID INT64, 
    IN p_StartDateOverRide STRING, 
    IN p_EndDateOverRide STRING
)
BEGIN
    -- Variables Setup
    DECLARE v_Component STRING DEFAULT '{{ project_id }}.{{ target_dataset_id }}.Load_Fact_KPI_Daily_Stg';
    DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;

    BEGIN
        -- Clear staging table
        TRUNCATE TABLE `{{ project_id }}.{{ target_dataset_id }}.Fact_KPI_Stg`;

        -- Insert newly processed KPI data
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Fact_KPI_Stg` (
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
        SELECT 
            LabelNo,
            MIN(L.CountryCode) AS CountryCode,
            MIN(Category) AS Category,
            MIN(ServiceType) AS ServiceType,
            MIN(RealisedDate) AS RealisedDate,
            MIN(L.CreatedOn) AS CreatedOn,
            MIN(L.FromRf) AS FromRf,
            MIN(L.ToRf) AS ToRf,      
            MIN(L.SLA) AS SLA,
            MIN(KPIPickup) AS KPIPickup,
            MIN(KPILEA) AS KPILEA,
            MIN(KPIDelivery) AS KPIDelivery,
            0 AS KPIPickupImpact,
            0 AS KPILEAImpact,
            0 AS KPIDeliveryImpact,
            MIN(DueDate) AS DueDate,
            MIN(KPIDepartureDate) AS KPIDepartureDate,
            NULL AS KPIArrivalDate,
            NULL AS KPIAttemptedDate,
            NULL AS KPIAttemptedDateAdjust,
            MIN(ActualDepartureDate) AS ActualDepartureDate,
            MIN(ActualDepartureRF) AS ActualDepartureRF,
            MIN(ActualDepartureCF) AS ActualDepartureCF,
            MIN(ActualDepartureType) AS ActualDepartureType,
            MIN(ActualDepartureStatus) AS ActualDepartureStatus,
            MIN(ActualFirstArrivalDate) AS ActualFirstArrivalDate,
            MIN(ActualFirstArrivalRF) AS ActualFirstArrivalRF,
            MIN(ActualFirstArrivalCF) AS ActualFirstArrivalCF,
            MIN(ActualFirstArrivalType) AS ActualFirstArrivalType,
            MIN(ActualFirstArrivalStatus) AS ActualFirstArrivalStatus,
            MIN(ActualArrivalDate) AS ActualArrivalDate,
            MIN(ActualArrivalRF) AS ActualArrivalRF,
            MIN(ActualArrivalCF) AS ActualArrivalCF,
            MIN(ActualArrivalType) AS ActualArrivalType,
            MIN(ActualArrivalStatus) AS ActualArrivalStatus,
            MIN(ActualAttemptedDate) AS ActualAttemptedDate,
            MIN(ActualAttemptedRF) AS ActualAttemptedRF,
            MIN(ActualAttemptedCF) AS ActualAttemptedCF,
            MIN(ActualAttemptedType) AS ActualAttemptedType,
            MIN(ActualAttemptedStatus) AS ActualAttemptedStatus,
            MIN(ActualDeliveryDate) AS ActualDeliveryDate,
            MIN(ActualDeliveryRF) AS ActualDeliveryRF,
            MIN(ActualDeliveryCF) AS ActualDeliveryCF,
            MIN(ActualDeliveryType) AS ActualDeliveryType,
            MIN(ActualDeliveryStatus) AS ActualDeliveryStatus,
            MIN(LastScanDate) AS LastScanDate,
            MIN(LastScanRF) AS LastScanRF,
            MIN(LastScanCF) AS LastScanCF,
            MIN(LastScanType) AS LastScanType,
            MIN(LastScanStatus) AS LastScanStatus,
            MIN(MISScanDate) AS MISScanDate,
            MIN(MISRF) AS MISRF,
            MIN(CustomerId) AS CustomerId,
            MIN(FromCF) AS FromCF,
            MIN(ToCf) AS ToCf,
            MIN(ToPostalCode) AS ToPostalCode,
            MIN(ToLocality) AS ToLocality                    
        FROM (
            SELECT 
                L.LabelNo,
                L.CountryCode,
                CASE 
                    WHEN (L.FranchiseeCode IS NULL AND Zone NOT IN ('SHU', 'SHT')) OR L.ToRf IN ('LEA', 'TMW') THEN 'Other'
                    WHEN L.FromRf = L.ToRf THEN 'Local'
                    ELSE 'Interbranch' 
                END AS Category,
                L.ServiceType,
                L.FranchiseeCode,
                L.FromRf,
                L.ToRF,
                L.CourierNumber,
                L.ScanDate,
                L.ScanDateTime,
                L.ScanType,
                L.ScanStatus,
                L.KPIGroup,
                L.SLA,
                KPIPickup,
                KPIDelivery,
                KPILEA,
                L.Zone,
                L.CreatedOn,
                L.RealisedDate,
                
                (
                    SELECT ARRAY_AGG(Calendar_Date ORDER BY Calendar_Date)[SAFE_OFFSET(COALESCE(CAST(SLA AS INT64), 1))]
                    FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Time`  
                    LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIExcludedDates` 
                        ON Calendar_Date = Date AND Franchise IN (FromRf, ToRf) AND CountryCode = L.CountryCode
                    WHERE Calendar_Date >= RealisedDateAsDateOnly AND week_day_flag = 'Y' AND Comment IS NULL
                ) AS DueDate,

                (
                    SELECT Calendar_Date
                    FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Time`  
                    LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIExcludedDates` 
                        ON Calendar_Date = Date AND Franchise = FromRf AND CountryCode = L.CountryCode
                    WHERE Calendar_Date >= RealisedDateAsDateOnly AND week_day_flag = 'Y' AND Comment IS NULL
                    ORDER BY Calendar_Date
                    LIMIT 1 OFFSET 0
                ) AS KPIDepartureDate,

                NULL AS KPIArrivalDate,
                NULL AS KPIAttemptedDate,
                NULL AS KPIAttemptedDateAdjust,

                ActualDepartureDate, ActualDepartureRF, ActualDepartureCF, ActualDepartureType, ActualDepartureStatus,
                ActualFirstArrivalDate, ActualFirstArrivalRF, ActualFirstArrivalCF, ActualFirstArrivalType, ActualFirstArrivalStatus,
                ActualArrivalDate, ActualArrivalRF, ActualArrivalCF, ActualArrivalType, ActualArrivalStatus,
                ActualAttemptedDate, ActualAttemptedRF, ActualAttemptedCF, ActualAttemptedType, ActualAttemptedStatus,
                ActualDeliveryDate, ActualDeliveryRF, ActualDeliveryCF, ActualDeliveryType, ActualDeliveryStatus,
                LastScanDate, LastScanRF, LastScanCF, LastScanType, LastScanStatus, MISScanDate, MISRF,
                CustomerId, FromCF, ToCf, ToPostalCode, ToLocality                                    
            FROM (
                SELECT 
                    L.LabelNo, L.CountryCode, L.ServiceType, L.FromRf, L.ToRF, L.CreatedOn, L.RealisedDate,
                    DATE(L.RealisedDate) AS RealisedDateAsDateOnly,
                    L.FranchiseeCode, L.CourierNumber, L.ScanDate, L.ScanDateTime, L.ScanType, L.ScanStatus, L.KPIGroup,
                    SLA, KPIPickup, KPIDelivery, KPILEA, L.Zone,

                    IF(Category != 'Local' AND KPIGroup='Departure' AND KPIDepartureOrder = 1 AND FranchiseeCode = L.FromRf AND CourierNumber = 'API', ScanDateTime, NULL) AS ActualDepartureDate,
                    IF(Category != 'Local' AND KPIGroup='Departure' AND KPIDepartureOrder = 1 AND FranchiseeCode = L.FromRf AND CourierNumber = 'API', FranchiseeCode, NULL) AS ActualDepartureRF,
                    IF(Category != 'Local' AND KPIGroup='Departure' AND KPIDepartureOrder = 1 AND FranchiseeCode = L.FromRf AND CourierNumber = 'API', CourierNumber, NULL) AS ActualDepartureCF,
                    IF(Category != 'Local' AND KPIGroup='Departure' AND KPIDepartureOrder = 1 AND FranchiseeCode = L.FromRf AND CourierNumber = 'API', ScanType, NULL) AS ActualDepartureType,
                    IF(Category != 'Local' AND KPIGroup='Departure' AND KPIDepartureOrder = 1 AND FranchiseeCode = L.FromRf AND CourierNumber = 'API', ScanStatus, NULL) AS ActualDepartureStatus,

                    IF(IF(Category = 'Local', IF(KPIGroupNotNull = 1 AND KPIGroup != 'Departure', 1, 0), IF(FranchiseeOrderArrival = 1, 1, 0)) = 1 AND FranchiseeCode = ToRF, ScanDateTime, NULL) AS ActualFirstArrivalDate,
                    IF(IF(Category = 'Local', IF(KPIGroupNotNull = 1 AND KPIGroup != 'Departure', 1, 0), IF(FranchiseeOrderArrival = 1, 1, 0)) = 1 AND FranchiseeCode = ToRF, FranchiseeCode, NULL) AS ActualFirstArrivalRF,
                    IF(IF(Category = 'Local', IF(KPIGroupNotNull = 1 AND KPIGroup != 'Departure', 1, 0), IF(FranchiseeOrderArrival = 1, 1, 0)) = 1 AND FranchiseeCode = ToRF, CourierNumber, NULL) AS ActualFirstArrivalCF,
                    IF(IF(Category = 'Local', IF(KPIGroupNotNull = 1 AND KPIGroup != 'Departure', 1, 0), IF(FranchiseeOrderArrival = 1, 1, 0)) = 1 AND FranchiseeCode = ToRF, ScanType, NULL) AS ActualFirstArrivalType,
                    IF(IF(Category = 'Local', IF(KPIGroupNotNull = 1 AND KPIGroup != 'Departure', 1, 0), IF(FranchiseeOrderArrival = 1, 1, 0)) = 1 AND FranchiseeCode = ToRF, ScanStatus, NULL) AS ActualFirstArrivalStatus,

                    IF(Category != 'Local' AND KPIGroup='Arrival' AND ScanStatus = 'RID' AND FranchiseeCode = L.ToRF AND CourierNumber = 'API', ScanDateTime, NULL) AS ActualArrivalDate,
                    IF(Category != 'Local' AND KPIGroup='Arrival' AND ScanStatus = 'RID' AND FranchiseeCode = L.ToRF AND CourierNumber = 'API', FranchiseeCode, NULL) AS ActualArrivalRF,
                    IF(Category != 'Local' AND KPIGroup='Arrival' AND ScanStatus = 'RID' AND FranchiseeCode = L.ToRF AND CourierNumber = 'API', CourierNumber, NULL) AS ActualArrivalCF,
                    IF(Category != 'Local' AND KPIGroup='Arrival' AND ScanStatus = 'RID' AND FranchiseeCode = L.ToRF AND CourierNumber = 'API', ScanType, NULL) AS ActualArrivalType,
                    IF(Category != 'Local' AND KPIGroup='Arrival' AND ScanStatus = 'RID' AND FranchiseeCode = L.ToRF AND CourierNumber = 'API', ScanStatus, NULL) AS ActualArrivalStatus,

                    IF(KPIGroup='Attempted' AND KPIGroupOrder = 1, ScanDateTime, NULL) AS ActualAttemptedDate,  
                    IF(KPIGroup='Attempted' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS ActualAttemptedRF,  
                    IF(KPIGroup='Attempted' AND KPIGroupOrder = 1, CourierNumber, NULL) AS ActualAttemptedCF,  
                    IF(KPIGroup='Attempted' AND KPIGroupOrder = 1, ScanType, NULL) AS ActualAttemptedType,  
                    IF(KPIGroup='Attempted' AND KPIGroupOrder = 1, ScanStatus, NULL) AS ActualAttemptedStatus,

                    IF(KPIGroup='Delivery' AND KPIGroupOrder = 1, ScanDateTime, NULL) AS ActualDeliveryDate,
                    IF(KPIGroup='Delivery' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS ActualDeliveryRF,
                    IF(KPIGroup='Delivery' AND KPIGroupOrder = 1, CourierNumber, NULL) AS ActualDeliveryCF,
                    IF(KPIGroup='Delivery' AND KPIGroupOrder = 1, ScanType, NULL) AS ActualDeliveryType,
                    IF(KPIGroup='Delivery' AND KPIGroupOrder = 1, ScanStatus, NULL) AS ActualDeliveryStatus,

                    IF(ScanReverse = 1, ScanDateTime, NULL) AS LastScanDate,
                    IF(ScanReverse = 1, FranchiseeCode, NULL) AS LastScanRF,
                    IF(ScanReverse = 1, CourierNumber, NULL) AS LastScanCF,
                    IF(ScanReverse = 1, ScanType, NULL) AS LastScanType,
                    IF(ScanReverse = 1, ScanStatus, NULL) AS LastScanStatus,

                    IF(ScanStatus = 'MIS', ScanDateTime, NULL) AS MISScanDate,
                    IF(ScanStatus = 'MIS', FranchiseeCode, NULL) AS MISRF,
                    CustomerId, FromCF, ToCf, ToPostalCode, ToLocality                                    
                FROM (
                    SELECT
                        L.LabelNo, L.CountryCode, L.Category, L.ServiceType, L.FromRf, L.ToRf, L.CreatedOn, L.RealisedDate,
                        L.FranchiseeCode, L.CourierNumber, L.ScanDate, L.ScanDateTime, L.ScanType, L.ScanStatus, L.KPIGroup,
                        0 AS SLA2,                  
                             
                        CASE 
                            WHEN L.ServiceType = 'P' THEN kdays + COALESCE(PriorityDays,0) + COALESCE(MaxDaysWithExceptionPriority,0)
                            ELSE kdays + COALESCE(EconomyDays,0) + COALESCE(MaxDaysWithExceptionEconomy,0) 
                        END AS SLA,
                        
                        KPIPickup,
                        COALESCE(MaxDays, 0) + CASE WHEN L.ServiceType = 'P' THEN COALESCE(PriorityDays, 0) ELSE COALESCE(EconomyDays, 0) END AS KPIDelivery,
                        KPILEA, L.Zone,                           
                        ROW_NUMBER() OVER(PARTITION BY L.LabelNo ORDER BY L.ScanDateTime DESC) AS ScanReverse,
                        ROW_NUMBER() OVER(PARTITION BY L.LabelNo, KPIGroup ORDER BY IF(L.CourierNumber != 'API', 1, 0), L.ScanDateTime) AS KPIDepartureOrder,
                        ROW_NUMBER() OVER(PARTITION BY L.LabelNo, KPIGroup ORDER BY L.ScanDateTime) AS KPIGroupOrder,
                        ROW_NUMBER() OVER(PARTITION BY L.LabelNo, L.FranchiseeCode ORDER BY L.ScanDateTime) AS FranchiseeOrderArrival,                         
                        ROW_NUMBER() OVER(PARTITION BY L.LabelNo ORDER BY IF(KPIGroup IS NULL, 1, 0), L.ScanDateTime) AS KPIGroupNotNull,
                        
                        L.CustomerId, L.FromCF, L.ToCf, L.ToPostalCode, L.ToLocality                                    
                    FROM (
                        SELECT
                            CASE 
                                WHEN L.FromRf = L.ToRf AND G.KPIGroup = 'Departure' THEN NULL 
                                ELSE G.KPIGroup 
                            END AS KPIGroup,
                            CASE    
                                WHEN (L.FranchiseeCode IS NULL AND Zone NOT IN ('SHU', 'SHT')) OR L.ToRf IN ('LEA', 'TMW') THEN 'Other'
                                WHEN L.FromRf = L.ToRf THEN 'Local'
                                ELSE 'Interbranch' 
                            END AS Category,
                            CASE WHEN S.LabelNo IS NOT NULL THEN 'P' ELSE 'E' END AS ServiceType,
                           
                            t.MaxDays,
                            CASE WHEN L.FromRf = (CASE WHEN L.ToRf = '' THEN Zone ELSE L.ToRf END) THEN 0 ELSE k.Days END AS KPILEA,
                             
                            0 AS KPIPickup,
                            K.Days AS kdays,
                            k.EconomyDays,
                            k.PriorityDays,
                            t.MaxDaysWithExceptionEconomy,
                            t.MaxDaysWithExceptionPriority,
                            L.LabelNo, L.CountryCode, L.FromRf, L.FromCf,
                            CASE WHEN L.ToRf = '' THEN L.Zone ELSE L.ToRF END AS ToRF,
                            L.ToCf, L.ToPostalCode, L.ToLocality, L.CustomerId, L.RealisedDate,
                            L.Zone, L.ScanStatus, L.ScanDate, L.ScanDateTime, L.ScanType, L.FranchiseeCode,
                            L.CourierNumber, L.CreatedOn
                        FROM `{{ project_id }}.{{ target_dataset_id }}.Fact_KPI_Src_Stg` AS L
                        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIScanGroups` G 
                            ON G.ScanStatus = L.ScanStatus AND G.CountryCode = L.CountryCode
                        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIMatrix` k 
                            ON L.FromRf = k.PickupFranchise AND (CASE WHEN L.ToRf = '' THEN Zone ELSE L.ToRf END) = k.DeliveryFranchise
                        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_TSS_PostCodeMaster` t 
                            ON L.ToLocality = t.Suburb AND L.ToPostalCode = CAST(t.Postcode AS STRING) AND t.CountryCode = 1
                        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_LSAT_Label_Product_ServiceItem` s  
                            ON s.ProductCode = 'MYFPRI' AND s.Labelno = L.LabelNo 
                    ) L
                ) L
            ) L
        ) L
        GROUP BY LabelNo;

        SET v_Inserted = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Standardize Call Logging block
    CALL `{{ project_id }}.{{ sp_dataset_id }}.SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,
        CURRENT_TIMESTAMP(),
        v_Result,
        v_ErrorMessage,
        v_Inserted,
        0, 
        IF(v_Result = 'Success', 0, -1)
    );

END;