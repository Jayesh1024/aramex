{#-- ==========================================================================================
Routine:		Staging_Load_Fact_Scan_KPI_Stg
Description: Recalc scan KPI stats for Labels that have just arrived
History:
	11/04/2019  P. Waldron		Routine Written
	01/07/2019  P. Waldron		Add First/Last Scan elements
    20/11/2019  P. Waldron		Change Inner Join on dbo.KPILabels to Left Join
    14/02/2020  P. Waldron      Refactor for new KPI Groups
    29/04/2020  P. Waldron      Use ScanTypeOrder for FirstPscan and FirstDscan calcs
========================================================================================== --#}

CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.Staging_Load_Fact_Scan_KPI_Stg`(
    IN p_ProcessID INT64
)
BEGIN
    -- System and Logging Variables
    DECLARE v_Component STRING DEFAULT '{{ project_id }}.{{ target_dataset_id }}.Staging_Load_Fact_Scan_KPI_Stg';
    
    -- OPTION 2: Use DATETIME and CURRENT_DATETIME()
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Ended DATETIME;
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;

    -- Control Variables
    DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_LastID INT64;
    DECLARE v_MinScanDate DATETIME DEFAULT DATETIME_SUB(CURRENT_DATETIME(), INTERVAL 1 YEAR);

    -- FIX: COALESCE type safety. Ensure ID is cast to INT64 to match the default 0
    SET v_LastID = (
        SELECT COALESCE(MAX(CAST(ID AS INT64)), 0) 
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_KPI_Labels_Stg`
    );

    IF v_LastID = 0 THEN
        RETURN;
    END IF;

    BEGIN
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_Scan_KPI_Stg` (
            LabelNo, FirstScanDate, FirstScanRF, FirstScanCF, FirstScanType, FirstScanStatus,
            LastScanDate, LastScanRF, LastScanCF, LastScanType, LastScanStatus,
            FirstPscanDate, FirstPscanRF, FirstPscanCF, FirstPScanStatus, 
            FirstDscanDate, FirstDscanRF, FirstDscanCF, FirstDScanStatus,
            FirstReceivedDate, FirstReceivedRF, FirstReceivedCF, FirstReceivedScanType, FirstReceivedScanStatus,
            LastReceivedDate, LastReceivedRF, LastReceivedCF, LastReceivedScanType, LastReceivedScanStatus,
            FirstSortedDate, FirstSortedRF, FirstSortedCF, FirstSortedScanType, FirstSortedScanStatus,
            LastSortedDate, LastSortedRF, LastSortedCF, LastSortedScanType, LastSortedScanStatus,
            FirstDepartedDate, FirstDepartedRF, FirstDepartedCF, FirstDepartedScanType, FirstDepartedScanStatus,
            LastDepartedDate, LastDepartedRF, LastDepartedCF, LastDepartedScanType, LastDepartedScanStatus,
            FirstArrivedDate, FirstArrivedRF, FirstArrivedCF, FirstArrivedScanType, FirstArrivedScanStatus,
            LastArrivedDate, LastArrivedRF, LastArrivedCF, LastArrivedScanType, LastArrivedScanStatus,
            FirstOutDate, FirstOutRF, FirstOutCF, FirstOutScanType, FirstOutScanStatus,
            LastOutDate, LastOutRF, LastOutCF, LastOutScanType, LastOutScanStatus,
            FirstStopDate, FirstStopRF, FirstStopCF, FirstStopScanType, FirstStopScanStatus,
            LastStopDate, LastStopRF, LastStopCF, LastStopScanType, LastStopScanStatus,
            FirstDeliveryDate, FirstDeliveryRF, FirstDeliveryCF, FirstDeliveryScanType, FirstDeliveryScanStatus,
            LastDeliveryDate, LastDeliveryRF, LastDeliveryCF, LastDeliveryScanType, LastDeliveryScanStatus,
            FirstImpactedDate, FirstImpactedRF, FirstImpactedCF, FirstImpactedScanType, FirstImpactedScanStatus,
            FirstFutileDate, FirstFutileRF, FirstFutileCF, FirstFutileScanType, FirstFutileScanStatus,
            StopDays, StopHoliday, KPI, SingleCycle, SubDepot, DeliveryDays, DeliveryHoliday, SLA,
            Loaded, ProcessId				
        ) 
        SELECT
            kpi.*,
            -- StopDays
            (DATE_DIFF(DATE(FirstStopDate), DATE(FirstReceivedDate), DAY) 
                - DATE_DIFF(DATE(FirstStopDate), DATE(FirstReceivedDate), WEEK) * 2 
                - IF(EXTRACT(DAYOFWEEK FROM FirstReceivedDate) = 1, 1, 0) 
            ) + IF(EXTRACT(DAYOFWEEK FROM FirstStopDate) = 1, 1, 0) AS StopDays,
            
            -- StopHoliday
            (SELECT COUNT(*) FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIExcludedDates` xd 
             WHERE xd.Franchise = FirstStopRF AND xd.Date BETWEEN DATE(FirstReceivedDate) AND DATE(FirstStopDate)) AS StopHoliday,
            
            -- KPI
            (SELECT MAX(m.Days) FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIMatrix` m 
             WHERE m.PickupFranchise = FirstReceivedRF AND m.DeliveryFranchise = FirstStopRF) AS KPI,
             
            -- SingleCycle (Note: Cast to String for Coalesce Safety)
            (SELECT COUNT(DISTINCT sc.CFCode) FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_SingleCycleCF` sc 
             WHERE sc.RFCode = COALESCE(CAST(FirstStopRF AS STRING), CAST(FirstDeliveryRF AS STRING)) 
               AND sc.CFCode = COALESCE(CAST(FirstStopCF AS STRING), CAST(FirstDeliveryCF AS STRING))) AS SingleCycle,
             
            -- SubDepot
            (SELECT COUNT(DISTINCT sd.SubDepotCode) FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_SubDepot` sd 
             WHERE sd.DeedRF = COALESCE(CAST(FirstStopRF AS STRING), CAST(FirstDeliveryRF AS STRING)) 
               AND sd.CF = COALESCE(CAST(FirstStopCF AS STRING), CAST(FirstDeliveryCF AS STRING))) AS SubDepot,
             
            -- DeliveryDays
            (DATE_DIFF(DATE(FirstDeliveryDate), DATE(FirstReceivedDate), DAY) 
                - DATE_DIFF(DATE(FirstDeliveryDate), DATE(FirstReceivedDate), WEEK) * 2 
                - IF(EXTRACT(DAYOFWEEK FROM FirstReceivedDate) = 1, 1, 0) 
            ) + IF(EXTRACT(DAYOFWEEK FROM FirstDeliveryDate) = 1, 1, 0) AS DeliveryDays,
            
            -- DeliveryHoliday
            (SELECT COUNT(*) FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIExcludedDates` xd 
             WHERE xd.Franchise = FirstDeliveryRF AND xd.Date BETWEEN DATE(FirstReceivedDate) AND DATE(FirstDeliveryDate)) AS DeliveryHoliday,
             
            -- SLA
            (SELECT MAX(m.Days) FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_KPICustomerMatrix` m 
             WHERE m.`Pickup RF` = FirstReceivedRF 
               AND m.`Delivery RF` = FirstDeliveryRF 
               AND DATE(FirstDeliveryDate) BETWEEN m.ValidFrom AND m.ValidTo 
               AND m.isCurrent = 1) AS SLA,
               
            v_Loaded AS Loaded,
            p_ProcessId AS ProcessId
        FROM 
        (
            SELECT 
                LabelNo, MIN(FirstScanDate), MIN(FirstScanRF), MIN(FirstScanCF), MIN(FirstScanType), MIN(FirstScanStatus), 
                MIN(LastScanDate), MIN(LastScanRF), MIN(LastScanCF), MIN(LastScanType), MIN(LastScanStatus), 
                MIN(FirstPScanDate), MIN(FirstPScanRF), MIN(FirstPScanCF), MIN(FirstPScanStatus),
                MIN(FirstDScanDate), MIN(FirstDScanRF), MIN(FirstDScanCF), MIN(FirstDScanStatus),
                MIN(FirstReceivedDate), MIN(FirstReceivedRF), MIN(FirstReceivedCF), MIN(FirstReceivedScanType), MIN(FirstReceivedScanStatus),
                MIN(LastReceivedDate), MIN(LastReceivedRF), MIN(LastReceivedCF), MIN(LastReceivedScanType), MIN(LastReceivedScanStatus),
                MIN(FirstSortedDate), MIN(FirstSortedRF), MIN(FirstSortedCF), MIN(FirstSortedScanType), MIN(FirstSortedScanStatus),
                MIN(LastSortedDate), MIN(LastSortedRF), MIN(LastSortedCF), MIN(LastSortedScanType), MIN(LastSortedScanStatus),
                MIN(FirstDepartedDate), MIN(FirstDepartedRF), MIN(FirstDepartedCF), MIN(FirstDepartedScanType), MIN(FirstDepartedScanStatus),
                MIN(LastDepartedDate), MIN(LastDepartedRF), MIN(LastDepartedCF), MIN(LastDepartedScanType), MIN(LastDepartedScanStatus),
                MIN(FirstArrivedDate), MIN(FirstArrivedRF), MIN(FirstArrivedCF), MIN(FirstArrivedScanType), MIN(FirstArrivedScanStatus),
                MIN(LastArrivedDate), MIN(LastArrivedRF), MIN(LastArrivedCF), MIN(LastArrivedScanType), MIN(LastArrivedScanStatus),
                MIN(FirstOutDate), MIN(FirstOutRF), MIN(FirstOutCF), MIN(FirstOutScanType), MIN(FirstOutScanStatus),
                MIN(LastOutDate), MIN(LastOutRF), MIN(LastOutCF), MIN(LastOutScanType), MIN(LastOutScanStatus),
                MIN(FirstStopDate), MIN(FirstStopRF), MIN(FirstStopCF), MIN(FirstStopScanType), MIN(FirstStopScanStatus),
                MIN(LastStopDate), MIN(LastStopRF), MIN(LastStopCF), MIN(LastStopScanType), MIN(LastStopScanStatus),
                MIN(FirstDeliveryDate), MIN(FirstDeliveryRF), MIN(FirstDeliveryCF), MIN(FirstDeliveryScanType), MIN(FirstDeliveryScanStatus),
                MIN(LastDeliveryDate), MIN(LastDeliveryRF), MIN(LastDeliveryCF), MIN(LastDeliveryScanType), MIN(LastDeliveryScanStatus),
                MIN(FirstImpactedDate), MIN(FirstImpactedRF), MIN(FirstImpactedCF), MIN(FirstImpactedScanType), MIN(FirstImpactedScanStatus),
                MIN(FirstFutileDate), MIN(FirstFutileRF), MIN(FirstFutileCF), MIN(FirstFutileScanType), MIN(FirstFutileScanStatus)
            FROM 
            (
                SELECT  
                    LabelNo,
                    IF(ScanOrder = 1, ScanDate, NULL) AS FirstScanDate,
                    IF(ScanOrder = 1, FranchiseeCode, NULL) AS FirstScanRF,
                    IF(ScanOrder = 1, CourierNumber, NULL) AS FirstScanCF,
                    IF(ScanOrder = 1, ScanType, NULL) AS FirstScanType,
                    IF(ScanOrder = 1, ScanStatus, NULL) AS FirstScanStatus,
                    IF(ScanReverse = 1, ScanDate, NULL) AS LastScanDate,
                    IF(ScanReverse = 1, FranchiseeCode, NULL) AS LastScanRF,
                    IF(ScanReverse = 1, CourierNumber, NULL) AS LastScanCF,
                    IF(ScanReverse = 1, ScanType, NULL) AS LastScanType,
                    IF(ScanReverse = 1, ScanStatus, NULL) AS LastScanStatus,
                    IF(ScanType='P' AND ScanTypeOrder = 1, ScanDate, NULL) AS FirstPscanDate,
                    IF(ScanType='P' AND ScanTypeOrder = 1, FranchiseeCode, NULL) AS FirstPscanRF,
                    IF(ScanType='P' AND ScanTypeOrder = 1, CourierNumber, NULL) AS FirstPscanCF,
                    IF(ScanType='P' AND ScanTypeOrder = 1, ScanStatus, NULL) AS FirstPScanStatus,
                    IF(ScanType='D' AND ScanTypeOrder = 1, ScanDate, NULL) AS FirstDscanDate,
                    IF(ScanType='D' AND ScanTypeOrder = 1, FranchiseeCode, NULL) AS FirstDscanRF,
                    IF(ScanType='D' AND ScanTypeOrder = 1, CourierNumber, NULL) AS FirstDscanCF,
                    IF(ScanType='D' AND ScanTypeOrder = 1, ScanStatus, NULL) AS FirstDScanStatus,
                    IF(KPIGroup='Received' AND KPIGroupOrder = 1, ScanDate, NULL) AS FirstReceivedDate,
                    IF(KPIGroup='Received' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS FirstReceivedRF,
                    IF(KPIGroup='Received' AND KPIGroupOrder = 1, CourierNumber, NULL) AS FirstReceivedCF,
                    IF(KPIGroup='Received' AND KPIGroupOrder = 1, ScanType, NULL) AS FirstReceivedScanType,
                    IF(KPIGroup='Received' AND KPIGroupOrder = 1, ScanStatus, NULL) AS FirstReceivedScanStatus,
                    IF(KPIGroup='Received' AND KPIGroupReverse = 1, ScanDate, NULL) AS LastReceivedDate,
                    IF(KPIGroup='Received' AND KPIGroupReverse = 1, FranchiseeCode, NULL) AS LastReceivedRF,
                    IF(KPIGroup='Received' AND KPIGroupReverse = 1, CourierNumber, NULL) AS LastReceivedCF,
                    IF(KPIGroup='Received' AND KPIGroupReverse = 1, ScanType, NULL) AS LastReceivedScanType,
                    IF(KPIGroup='Received' AND KPIGroupReverse = 1, ScanStatus, NULL) AS LastReceivedScanStatus,
                    IF(KPIGroup='Sorted' AND KPIGroupOrder = 1, ScanDate, NULL) AS FirstSortedDate,
                    IF(KPIGroup='Sorted' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS FirstSortedRF,
                    IF(KPIGroup='Sorted' AND KPIGroupOrder = 1, CourierNumber, NULL) AS FirstSortedCF,
                    IF(KPIGroup='Sorted' AND KPIGroupOrder = 1, ScanType, NULL) AS FirstSortedScanType,
                    IF(KPIGroup='Sorted' AND KPIGroupOrder = 1, ScanStatus, NULL) AS FirstSortedScanStatus,
                    IF(KPIGroup='Sorted' AND KPIGroupReverse = 1, ScanDate, NULL) AS LastSortedDate,
                    IF(KPIGroup='Sorted' AND KPIGroupReverse = 1, FranchiseeCode, NULL) AS LastSortedRF,
                    IF(KPIGroup='Sorted' AND KPIGroupReverse = 1, CourierNumber, NULL) AS LastSortedCF,
                    IF(KPIGroup='Sorted' AND KPIGroupReverse = 1, ScanType, NULL) AS LastSortedScanType,
                    IF(KPIGroup='Sorted' AND KPIGroupReverse = 1, ScanStatus, NULL) AS LastSortedScanStatus,
                    IF(KPIGroup='Departed' AND KPIGroupOrder = 1, ScanDate, NULL) AS FirstDepartedDate,
                    IF(KPIGroup='Departed' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS FirstDepartedRF,
                    IF(KPIGroup='Departed' AND KPIGroupOrder = 1, CourierNumber, NULL) AS FirstDepartedCF,
                    IF(KPIGroup='Departed' AND KPIGroupOrder = 1, ScanType, NULL) AS FirstDepartedScanType,
                    IF(KPIGroup='Departed' AND KPIGroupOrder = 1, ScanStatus, NULL) AS FirstDepartedScanStatus,
                    IF(KPIGroup='Departed' AND KPIGroupReverse = 1, ScanDate, NULL) AS LastDepartedDate,
                    IF(KPIGroup='Departed' AND KPIGroupReverse = 1, FranchiseeCode, NULL) AS LastDepartedRF,
                    IF(KPIGroup='Departed' AND KPIGroupReverse = 1, CourierNumber, NULL) AS LastDepartedCF,
                    IF(KPIGroup='Departed' AND KPIGroupOrder = 1, ScanType, NULL) AS LastDepartedScanType,
                    IF(KPIGroup='Departed' AND KPIGroupReverse = 1, ScanStatus, NULL) AS LastDepartedScanStatus,
                    IF(KPIGroup='Arrived' AND KPIGroupOrder = 1, ScanDate, NULL) AS FirstArrivedDate,
                    IF(KPIGroup='Arrived' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS FirstArrivedRF,
                    IF(KPIGroup='Arrived' AND KPIGroupOrder = 1, CourierNumber, NULL) AS FirstArrivedCF,
                    IF(KPIGroup='Arrived' AND KPIGroupOrder = 1, ScanType, NULL) AS FirstArrivedScanType,
                    IF(KPIGroup='Arrived' AND KPIGroupOrder = 1, ScanStatus, NULL) AS FirstArrivedScanStatus,
                    IF(KPIGroup='Arrived' AND KPIGroupReverse = 1, ScanDate, NULL) AS LastArrivedDate,
                    IF(KPIGroup='Arrived' AND KPIGroupReverse = 1, FranchiseeCode, NULL) AS LastArrivedRF,
                    IF(KPIGroup='Arrived' AND KPIGroupReverse = 1, CourierNumber, NULL) AS LastArrivedCF,
                    IF(KPIGroup='Arrived' AND KPIGroupReverse = 1, ScanType, NULL) AS LastArrivedScanType,
                    IF(KPIGroup='Arrived' AND KPIGroupReverse = 1, ScanStatus, NULL) AS LastArrivedScanStatus,
                    IF(KPIGroup='Out' AND KPIGroupOrder = 1, ScanDate, NULL) AS FirstOutDate,
                    IF(KPIGroup='Out' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS FirstOutRF,
                    IF(KPIGroup='Out' AND KPIGroupOrder = 1, CourierNumber, NULL) AS FirstOutCF,
                    IF(KPIGroup='Out' AND KPIGroupOrder = 1, ScanType, NULL) AS FirstOutScanType,
                    IF(KPIGroup='Out' AND KPIGroupOrder = 1, ScanStatus, NULL) AS FirstOutScanStatus,
                    IF(KPIGroup='Out' AND KPIGroupReverse = 1, ScanDate, NULL) AS LastOutDate,
                    IF(KPIGroup='Out' AND KPIGroupReverse = 1, FranchiseeCode, NULL) AS LastOutRF,
                    IF(KPIGroup='Out' AND KPIGroupReverse = 1, CourierNumber, NULL) AS LastOutCF,
                    IF(KPIGroup='Out' AND KPIGroupReverse = 1, ScanType, NULL) AS LastOutScanType,
                    IF(KPIGroup='Out' AND KPIGroupReverse = 1, ScanStatus, NULL) AS LastOutScanStatus,
                    IF(KPIGroup='Stop' AND KPIGroupOrder = 1, ScanDate, NULL) AS FirstStopDate,
                    IF(KPIGroup='Stop' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS FirstStopRF,
                    IF(KPIGroup='Stop' AND KPIGroupOrder = 1, CourierNumber, NULL) AS FirstStopCF,
                    IF(KPIGroup='Stop' AND KPIGroupOrder = 1, ScanType, NULL) AS FirstStopScanType,
                    IF(KPIGroup='Stop' AND KPIGroupOrder = 1, ScanStatus, NULL) AS FirstStopScanStatus,
                    IF(KPIGroup='Stop' AND KPIGroupReverse = 1, ScanDate, NULL) AS LastStopDate,
                    IF(KPIGroup='Stop' AND IF(ScanReverse = 1, TRUE, FALSE), FranchiseeCode, NULL) AS LastStopRF,
                    IF(KPIGroup='Stop' AND KPIGroupReverse = 1, CourierNumber, NULL) AS LastStopCF,
                    IF(KPIGroup='Stop' AND KPIGroupReverse = 1, ScanType, NULL) AS LastStopScanType,
                    IF(KPIGroup='Stop' AND KPIGroupReverse = 1, ScanStatus, NULL) AS LastStopScanStatus,
                    IF(KPIGroup='Delivery' AND KPIGroupOrder = 1, ScanDate, NULL) AS FirstDeliveryDate,
                    IF(KPIGroup='Delivery' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS FirstDeliveryRF,
                    IF(KPIGroup='Delivery' AND KPIGroupOrder = 1, CourierNumber, NULL) AS FirstDeliveryCF,
                    IF(KPIGroup='Delivery' AND KPIGroupOrder = 1, ScanType, NULL) AS FirstDeliveryScanType,
                    IF(KPIGroup='Delivery' AND KPIGroupOrder = 1, ScanStatus, NULL) AS FirstDeliveryScanStatus,
                    IF(KPIGroup='Delivery' AND KPIGroupReverse = 1, ScanDate, NULL) AS LastDeliveryDate,
                    IF(KPIGroup='Delivery' AND KPIGroupReverse = 1, FranchiseeCode, NULL) AS LastDeliveryRF,
                    IF(KPIGroup='Delivery' AND KPIGroupReverse = 1, CourierNumber, NULL) AS LastDeliveryCF,
                    IF(KPIGroup='Delivery' AND KPIGroupReverse = 1, ScanType, NULL) AS LastDeliveryScanType,
                    IF(KPIGroup='Delivery' AND KPIGroupReverse = 1, ScanStatus, NULL) AS LastDeliveryScanStatus,
                    IF(KPIGroup='Impacted' AND KPIGroupOrder = 1, ScanDate, NULL) AS FirstImpactedDate,
                    IF(KPIGroup='Impacted' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS FirstImpactedRF,
                    IF(KPIGroup='Impacted' AND KPIGroupOrder = 1, CourierNumber, NULL) AS FirstImpactedCF,
                    IF(KPIGroup='Impacted' AND KPIGroupOrder = 1, ScanType, NULL) AS FirstImpactedScanType,
                    IF(KPIGroup='Impacted' AND KPIGroupOrder = 1, ScanStatus, NULL) AS FirstImpactedScanStatus,
                    IF(KPIGroup='Futile' AND KPIGroupOrder = 1, ScanDate, NULL) AS FirstFutileDate,
                    IF(KPIGroup='Futile' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS FirstFutileRF,
                    IF(KPIGroup='Futile' AND KPIGroupOrder = 1, CourierNumber, NULL) AS FirstFutileCF,
                    IF(KPIGroup='Futile' AND KPIGroupOrder = 1, ScanType, NULL) AS FirstFutileScanType,
                    IF(KPIGroup='Futile' AND KPIGroupOrder = 1, ScanStatus, NULL) AS FirstFutileScanStatus
                FROM 
                (
                    SELECT  
                        scan.LabelNo, scan.ScanDate, k.KPIGroup,
                        ROW_NUMBER() OVER(PARTITION BY scan.LabelNo ORDER BY scan.ScanDate) AS ScanOrder,
                        ROW_NUMBER() OVER(PARTITION BY scan.LabelNo ORDER BY scan.ScanDate DESC) AS ScanReverse,
                        ROW_NUMBER() OVER(PARTITION BY scan.LabelNo, k.KPIGroup ORDER BY scan.ScanDate) AS KPIGroupOrder,
                        ROW_NUMBER() OVER(PARTITION BY scan.LabelNo, k.KPIGroup ORDER BY scan.ScanDate DESC) AS KPIGroupReverse,
                        ROW_NUMBER() OVER(PARTITION BY scan.LabelNo, scan.ScanType ORDER BY scan.ScanDate) AS ScanTypeOrder,
                        scan.CountryName, scan.FranchiseeCode, scan.CourierNumber, scan.ScanType, scan.ScanStatus
                    FROM `{{ project_id }}.{{ target_dataset_id }}.dv_LNK_Scan_By_LabelNo` AS scan 
                    JOIN `{{ project_id }}.{{ target_dataset_id }}.Staging_KPI_Labels_Stg` batch 
                        ON batch.LabelNo = scan.LabelNo
                    LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPICodes` AS k 
                        ON scan.ScanStatus = k.ScanStatus 
                    LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` AS dc 
                        ON dc.CountryCode = k.CountryCode AND scan.CountryName = dc.CountryName
                    WHERE scan.ScanDate >= v_MinScanDate
                ) sc
            ) grp
            GROUP BY LabelNo
        ) kpi;

        SET v_Inserted = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- OPTION 2: Logging logic
    SET v_Ended = CURRENT_DATETIME();
    CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,
        v_Ended,
        v_Result,
        v_ErrorMessage,
        v_Inserted,
        -1,
        -1
    );

END;