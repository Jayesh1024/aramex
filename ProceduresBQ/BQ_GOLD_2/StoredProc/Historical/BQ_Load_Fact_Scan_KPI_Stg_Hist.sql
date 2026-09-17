CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_Load_Fact_Scan_KPI_Stg_Hist`(IN p_ProcessID INT64)
BEGIN
    -- System and Logging Variables
    DECLARE v_Component STRING DEFAULT 'Staging_Load_Fact_Scan_KPI_Stg_Hist';
    
    -- OPTION 2: Use DATETIME and CURRENT_DATETIME()
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Ended DATETIME;
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;

    -- Control Variables
    DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();

    BEGIN
        INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_KPI_Stg` (
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
            (SELECT COUNT(*) FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIExcludedDates` xd 
             WHERE xd.Franchise = FirstStopRF AND xd.Date BETWEEN DATE(FirstReceivedDate) AND DATE(FirstStopDate)) AS StopHoliday,
            
            -- KPI
            (SELECT MAX(m.Days) FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIMatrix` m 
             WHERE m.PickupFranchise = FirstReceivedRF AND m.DeliveryFranchise = FirstStopRF) AS KPI,
             
            -- SingleCycle (Note: SAFE_CAST to String for Coalesce Safety)
            (SELECT COUNT(DISTINCT sc.CFCode) FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_SingleCycleCF` sc 
             WHERE sc.RFCode = COALESCE(SAFE_CAST(FirstStopRF AS STRING), SAFE_CAST(FirstDeliveryRF AS STRING)) 
               AND sc.CFCode = COALESCE(SAFE_CAST(FirstStopCF AS STRING), SAFE_CAST(FirstDeliveryCF AS STRING))) AS SingleCycle,
             
            -- SubDepot
            (SELECT COUNT(DISTINCT sd.SubDepotCode) FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_SubDepot` sd 
             WHERE sd.DeedRF = COALESCE(SAFE_CAST(FirstStopRF AS STRING), SAFE_CAST(FirstDeliveryRF AS STRING)) 
               AND sd.CF = COALESCE(SAFE_CAST(FirstStopCF AS STRING), SAFE_CAST(FirstDeliveryCF AS STRING))) AS SubDepot,
             
            -- DeliveryDays
            (DATE_DIFF(DATE(FirstDeliveryDate), DATE(FirstReceivedDate), DAY) 
                - DATE_DIFF(DATE(FirstDeliveryDate), DATE(FirstReceivedDate), WEEK) * 2 
                - IF(EXTRACT(DAYOFWEEK FROM FirstReceivedDate) = 1, 1, 0) 
            ) + IF(EXTRACT(DAYOFWEEK FROM FirstDeliveryDate) = 1, 1, 0) AS DeliveryDays,
            
            -- DeliveryHoliday
            (SELECT COUNT(*) FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIExcludedDates` xd 
             WHERE xd.Franchise = FirstDeliveryRF AND xd.Date BETWEEN DATE(FirstReceivedDate) AND DATE(FirstDeliveryDate)) AS DeliveryHoliday,
             
            -- SLA
            (SELECT MAX(SAFE_CAST(m.Days AS INT64)) FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPICustomerMatrix` m 
             WHERE m.`Pickup RF` = FirstReceivedRF 
               AND m.`Delivery RF` = FirstDeliveryRF 
               AND DATE(FirstDeliveryDate) BETWEEN m.ValidFrom AND m.ValidTo 
               AND m.isCurrent = 1) AS SLA,
               
            v_Loaded AS Loaded,
            p_ProcessId AS ProcessId
        FROM 
        (
                 SELECT 
                LabelNo, 
                MIN(FirstScanDate) AS FirstScanDate, MIN(FirstScanRF) AS FirstScanRF, MIN(FirstScanCF) AS FirstScanCF, MIN(FirstScanType) AS FirstScanType, MIN(FirstScanStatus) AS FirstScanStatus, 
                MIN(LastScanDate) AS LastScanDate, MIN(LastScanRF) AS LastScanRF, MIN(LastScanCF) AS LastScanCF, MIN(LastScanType) AS LastScanType, MIN(LastScanStatus) AS LastScanStatus, 
                MIN(FirstPScanDate) AS FirstPScanDate, MIN(FirstPScanRF) AS FirstPScanRF, MIN(FirstPScanCF) AS FirstPScanCF, MIN(FirstPScanStatus) AS FirstPScanStatus,
                MIN(FirstDScanDate) AS FirstDScanDate, MIN(FirstDScanRF) AS FirstDScanRF, MIN(FirstDScanCF) AS FirstDScanCF, MIN(FirstDScanStatus) AS FirstDScanStatus,
                MIN(FirstReceivedDate) AS FirstReceivedDate, MIN(FirstReceivedRF) AS FirstReceivedRF, MIN(FirstReceivedCF) AS FirstReceivedCF, MIN(FirstReceivedScanType) AS FirstReceivedScanType, MIN(FirstReceivedScanStatus) AS FirstReceivedScanStatus,
                MIN(LastReceivedDate) AS LastReceivedDate, MIN(LastReceivedRF) AS LastReceivedRF, MIN(LastReceivedCF) AS LastReceivedCF, MIN(LastReceivedScanType) AS LastReceivedScanType, MIN(LastReceivedScanStatus) AS LastReceivedScanStatus,
                MIN(FirstSortedDate) AS FirstSortedDate, MIN(FirstSortedRF) AS FirstSortedRF, MIN(FirstSortedCF) AS FirstSortedCF, MIN(FirstSortedScanType) AS FirstSortedScanType, MIN(FirstSortedScanStatus) AS FirstSortedScanStatus,
                MIN(LastSortedDate) AS LastSortedDate, MIN(LastSortedRF) AS LastSortedRF, MIN(LastSortedCF) AS LastSortedCF, MIN(LastSortedScanType) AS LastSortedScanType, MIN(LastSortedScanStatus) AS LastSortedScanStatus,
                MIN(FirstDepartedDate) AS FirstDepartedDate, MIN(FirstDepartedRF) AS FirstDepartedRF, MIN(FirstDepartedCF) AS FirstDepartedCF, MIN(FirstDepartedScanType) AS FirstDepartedScanType, MIN(FirstDepartedScanStatus) AS FirstDepartedScanStatus,
                MIN(LastDepartedDate) AS LastDepartedDate, MIN(LastDepartedRF) AS LastDepartedRF, MIN(LastDepartedCF) AS LastDepartedCF, MIN(LastDepartedScanType) AS LastDepartedScanType, MIN(LastDepartedScanStatus) AS LastDepartedScanStatus,
                MIN(FirstArrivedDate) AS FirstArrivedDate, MIN(FirstArrivedRF) AS FirstArrivedRF, MIN(FirstArrivedCF) AS FirstArrivedCF, MIN(FirstArrivedScanType) AS FirstArrivedScanType, MIN(FirstArrivedScanStatus) AS FirstArrivedScanStatus,
                MIN(LastArrivedDate) AS LastArrivedDate, MIN(LastArrivedRF) AS LastArrivedRF, MIN(LastArrivedCF) AS LastArrivedCF, MIN(LastArrivedScanType) AS LastArrivedScanType, MIN(LastArrivedScanStatus) AS LastArrivedScanStatus,
                MIN(FirstOutDate) AS FirstOutDate, MIN(FirstOutRF) AS FirstOutRF, MIN(FirstOutCF) AS FirstOutCF, MIN(FirstOutScanType) AS FirstOutScanType, MIN(FirstOutScanStatus) AS FirstOutScanStatus,
                MIN(LastOutDate) AS LastOutDate, MIN(LastOutRF) AS LastOutRF, MIN(LastOutCF) AS LastOutCF, MIN(LastOutScanType) AS LastOutScanType, MIN(LastOutScanStatus) AS LastOutScanStatus,
                MIN(FirstStopDate) AS FirstStopDate, MIN(FirstStopRF) AS FirstStopRF, MIN(FirstStopCF) AS FirstStopCF, MIN(FirstStopScanType) AS FirstStopScanType, MIN(FirstStopScanStatus) AS FirstStopScanStatus,
                MIN(LastStopDate) AS LastStopDate, MIN(LastStopRF) AS LastStopRF, MIN(LastStopCF) AS LastStopCF, MIN(LastStopScanType) AS LastStopScanType, MIN(LastStopScanStatus) AS LastStopScanStatus,
                MIN(FirstDeliveryDate) AS FirstDeliveryDate, MIN(FirstDeliveryRF) AS FirstDeliveryRF, MIN(FirstDeliveryCF) AS FirstDeliveryCF, MIN(FirstDeliveryScanType) AS FirstDeliveryScanType, MIN(FirstDeliveryScanStatus) AS FirstDeliveryScanStatus,
                MIN(LastDeliveryDate) AS LastDeliveryDate, MIN(LastDeliveryRF) AS LastDeliveryRF, MIN(LastDeliveryCF) AS LastDeliveryCF, MIN(LastDeliveryScanType) AS LastDeliveryScanType, MIN(LastDeliveryScanStatus) AS LastDeliveryScanStatus,
                MIN(FirstImpactedDate) AS FirstImpactedDate, MIN(FirstImpactedRF) AS FirstImpactedRF, MIN(FirstImpactedCF) AS FirstImpactedCF, MIN(FirstImpactedScanType) AS FirstImpactedScanType, MIN(FirstImpactedScanStatus) AS FirstImpactedScanStatus,
                MIN(FirstFutileDate) AS FirstFutileDate, MIN(FirstFutileRF) AS FirstFutileRF, MIN(FirstFutileCF) AS FirstFutileCF, MIN(FirstFutileScanType) AS FirstFutileScanType, MIN(FirstFutileScanStatus) AS FirstFutileScanStatus
           
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
                    IF(UPPER(ScanType)='P' AND ScanTypeOrder = 1, ScanDate, NULL) AS FirstPscanDate,
                    IF(UPPER(ScanType)='P' AND ScanTypeOrder = 1, FranchiseeCode, NULL) AS FirstPscanRF,
                    IF(UPPER(ScanType)='P' AND ScanTypeOrder = 1, CourierNumber, NULL) AS FirstPscanCF,
                    IF(UPPER(ScanType)='P' AND ScanTypeOrder = 1, ScanStatus, NULL) AS FirstPScanStatus,
                    IF(UPPER(ScanType)='D' AND ScanTypeOrder = 1, ScanDate, NULL) AS FirstDscanDate,
                    IF(UPPER(ScanType)='D' AND ScanTypeOrder = 1, FranchiseeCode, NULL) AS FirstDscanRF,
                    IF(UPPER(ScanType)='D' AND ScanTypeOrder = 1, CourierNumber, NULL) AS FirstDscanCF,
                    IF(UPPER(ScanType)='D' AND ScanTypeOrder = 1, ScanStatus, NULL) AS FirstDScanStatus,
                    IF(UPPER(KPIGroup)='RECEIVED' AND KPIGroupOrder = 1, ScanDate, NULL) AS FirstReceivedDate,
                    IF(UPPER(KPIGroup)='RECEIVED' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS FirstReceivedRF,
                    IF(UPPER(KPIGroup)='RECEIVED' AND KPIGroupOrder = 1, CourierNumber, NULL) AS FirstReceivedCF,
                    IF(UPPER(KPIGroup)='RECEIVED' AND KPIGroupOrder = 1, ScanType, NULL) AS FirstReceivedScanType,
                    IF(UPPER(KPIGroup)='RECEIVED' AND KPIGroupOrder = 1, ScanStatus, NULL) AS FirstReceivedScanStatus,
                    IF(UPPER(KPIGroup)='RECEIVED' AND KPIGroupReverse = 1, ScanDate, NULL) AS LastReceivedDate,
                    IF(UPPER(KPIGroup)='RECEIVED' AND KPIGroupReverse = 1, FranchiseeCode, NULL) AS LastReceivedRF,
                    IF(UPPER(KPIGroup)='RECEIVED' AND KPIGroupReverse = 1, CourierNumber, NULL) AS LastReceivedCF,
                    IF(UPPER(KPIGroup)='RECEIVED' AND KPIGroupReverse = 1, ScanType, NULL) AS LastReceivedScanType,
                    IF(UPPER(KPIGroup)='RECEIVED' AND KPIGroupReverse = 1, ScanStatus, NULL) AS LastReceivedScanStatus,
                    IF(UPPER(KPIGroup)='SORTED' AND KPIGroupOrder = 1, ScanDate, NULL) AS FirstSortedDate,
                    IF(UPPER(KPIGroup)='SORTED' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS FirstSortedRF,
                    IF(UPPER(KPIGroup)='SORTED' AND KPIGroupOrder = 1, CourierNumber, NULL) AS FirstSortedCF,
                    IF(UPPER(KPIGroup)='SORTED' AND KPIGroupOrder = 1, ScanType, NULL) AS FirstSortedScanType,
                    IF(UPPER(KPIGroup)='SORTED' AND KPIGroupOrder = 1, ScanStatus, NULL) AS FirstSortedScanStatus,
                    IF(UPPER(KPIGroup)='SORTED' AND KPIGroupReverse = 1, ScanDate, NULL) AS LastSortedDate,
                    IF(UPPER(KPIGroup)='SORTED' AND KPIGroupReverse = 1, FranchiseeCode, NULL) AS LastSortedRF,
                    IF(UPPER(KPIGroup)='SORTED' AND KPIGroupReverse = 1, CourierNumber, NULL) AS LastSortedCF,
                    IF(UPPER(KPIGroup)='SORTED' AND KPIGroupReverse = 1, ScanType, NULL) AS LastSortedScanType,
                    IF(UPPER(KPIGroup)='SORTED' AND KPIGroupReverse = 1, ScanStatus, NULL) AS LastSortedScanStatus,
                    IF(UPPER(KPIGroup)='DEPARTED' AND KPIGroupOrder = 1, ScanDate, NULL) AS FirstDepartedDate,
                    IF(UPPER(KPIGroup)='DEPARTED' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS FirstDepartedRF,
                    IF(UPPER(KPIGroup)='DEPARTED' AND KPIGroupOrder = 1, CourierNumber, NULL) AS FirstDepartedCF,
                    IF(UPPER(KPIGroup)='DEPARTED' AND KPIGroupOrder = 1, ScanType, NULL) AS FirstDepartedScanType,
                    IF(UPPER(KPIGroup)='DEPARTED' AND KPIGroupOrder = 1, ScanStatus, NULL) AS FirstDepartedScanStatus,
                    IF(UPPER(KPIGroup)='DEPARTED' AND KPIGroupReverse = 1, ScanDate, NULL) AS LastDepartedDate,
                    IF(UPPER(KPIGroup)='DEPARTED' AND KPIGroupReverse = 1, FranchiseeCode, NULL) AS LastDepartedRF,
                    IF(UPPER(KPIGroup)='DEPARTED' AND KPIGroupReverse = 1, CourierNumber, NULL) AS LastDepartedCF,
                    IF(UPPER(KPIGroup)='DEPARTED' AND KPIGroupOrder = 1, ScanType, NULL) AS LastDepartedScanType,
                    IF(UPPER(KPIGroup)='DEPARTED' AND KPIGroupReverse = 1, ScanStatus, NULL) AS LastDepartedScanStatus,
                    IF(UPPER(KPIGroup)='ARRIVED' AND KPIGroupOrder = 1, ScanDate, NULL) AS FirstArrivedDate,
                    IF(UPPER(KPIGroup)='ARRIVED' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS FirstArrivedRF,
                    IF(UPPER(KPIGroup)='ARRIVED' AND KPIGroupOrder = 1, CourierNumber, NULL) AS FirstArrivedCF,
                    IF(UPPER(KPIGroup)='ARRIVED' AND KPIGroupOrder = 1, ScanType, NULL) AS FirstArrivedScanType,
                    IF(UPPER(KPIGroup)='ARRIVED' AND KPIGroupOrder = 1, ScanStatus, NULL) AS FirstArrivedScanStatus,
                    IF(UPPER(KPIGroup)='ARRIVED' AND KPIGroupReverse = 1, ScanDate, NULL) AS LastArrivedDate,
                    IF(UPPER(KPIGroup)='ARRIVED' AND KPIGroupReverse = 1, FranchiseeCode, NULL) AS LastArrivedRF,
                    IF(UPPER(KPIGroup)='ARRIVED' AND KPIGroupReverse = 1, CourierNumber, NULL) AS LastArrivedCF,
                    IF(UPPER(KPIGroup)='ARRIVED' AND KPIGroupReverse = 1, ScanType, NULL) AS LastArrivedScanType,
                    IF(UPPER(KPIGroup)='ARRIVED' AND KPIGroupReverse = 1, ScanStatus, NULL) AS LastArrivedScanStatus,
                    IF(UPPER(KPIGroup)='OUT' AND KPIGroupOrder = 1, ScanDate, NULL) AS FirstOutDate,
                    IF(UPPER(KPIGroup)='OUT' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS FirstOutRF,
                    IF(UPPER(KPIGroup)='OUT' AND KPIGroupOrder = 1, CourierNumber, NULL) AS FirstOutCF,
                    IF(UPPER(KPIGroup)='OUT' AND KPIGroupOrder = 1, ScanType, NULL) AS FirstOutScanType,
                    IF(UPPER(KPIGroup)='OUT' AND KPIGroupOrder = 1, ScanStatus, NULL) AS FirstOutScanStatus,
                    IF(UPPER(KPIGroup)='OUT' AND KPIGroupReverse = 1, ScanDate, NULL) AS LastOutDate,
                    IF(UPPER(KPIGroup)='OUT' AND KPIGroupReverse = 1, FranchiseeCode, NULL) AS LastOutRF,
                    IF(UPPER(KPIGroup)='OUT' AND KPIGroupReverse = 1, CourierNumber, NULL) AS LastOutCF,
                    IF(UPPER(KPIGroup)='OUT' AND KPIGroupReverse = 1, ScanType, NULL) AS LastOutScanType,
                    IF(UPPER(KPIGroup)='OUT' AND KPIGroupReverse = 1, ScanStatus, NULL) AS LastOutScanStatus,
                    IF(UPPER(KPIGroup)='STOP' AND KPIGroupOrder = 1, ScanDate, NULL) AS FirstStopDate,
                    IF(UPPER(KPIGroup)='STOP' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS FirstStopRF,
                    IF(UPPER(KPIGroup)='STOP' AND KPIGroupOrder = 1, CourierNumber, NULL) AS FirstStopCF,
                    IF(UPPER(KPIGroup)='STOP' AND KPIGroupOrder = 1, ScanType, NULL) AS FirstStopScanType,
                    IF(UPPER(KPIGroup)='STOP' AND KPIGroupOrder = 1, ScanStatus, NULL) AS FirstStopScanStatus,
                    IF(UPPER(KPIGroup)='STOP' AND KPIGroupReverse = 1, ScanDate, NULL) AS LastStopDate,
                    IF(UPPER(KPIGroup)='STOP' AND KPIGroupReverse = 1, FranchiseeCode, NULL) AS LastStopRF,
                    IF(UPPER(KPIGroup)='STOP' AND KPIGroupReverse = 1, CourierNumber, NULL) AS LastStopCF,
                    IF(UPPER(KPIGroup)='STOP' AND KPIGroupReverse = 1, ScanType, NULL) AS LastStopScanType,
                    IF(UPPER(KPIGroup)='STOP' AND KPIGroupReverse = 1, ScanStatus, NULL) AS LastStopScanStatus,
                    IF(UPPER(KPIGroup)='DELIVERY' AND KPIGroupOrder = 1, ScanDate, NULL) AS FirstDeliveryDate,
                    IF(UPPER(KPIGroup)='DELIVERY' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS FirstDeliveryRF,
                    IF(UPPER(KPIGroup)='DELIVERY' AND KPIGroupOrder = 1, CourierNumber, NULL) AS FirstDeliveryCF,
                    IF(UPPER(KPIGroup)='DELIVERY' AND KPIGroupOrder = 1, ScanType, NULL) AS FirstDeliveryScanType,
                    IF(UPPER(KPIGroup)='DELIVERY' AND KPIGroupOrder = 1, ScanStatus, NULL) AS FirstDeliveryScanStatus,
                    IF(UPPER(KPIGroup)='DELIVERY' AND KPIGroupReverse = 1, ScanDate, NULL) AS LastDeliveryDate,
                    IF(UPPER(KPIGroup)='DELIVERY' AND KPIGroupReverse = 1, FranchiseeCode, NULL) AS LastDeliveryRF,
                    IF(UPPER(KPIGroup)='DELIVERY' AND KPIGroupReverse = 1, CourierNumber, NULL) AS LastDeliveryCF,
                    IF(UPPER(KPIGroup)='DELIVERY' AND KPIGroupReverse = 1, ScanType, NULL) AS LastDeliveryScanType,
                    IF(UPPER(KPIGroup)='DELIVERY' AND KPIGroupReverse = 1, ScanStatus, NULL) AS LastDeliveryScanStatus,
                    IF(UPPER(KPIGroup)='IMPACTED' AND KPIGroupOrder = 1, ScanDate, NULL) AS FirstImpactedDate,
                    IF(UPPER(KPIGroup)='IMPACTED' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS FirstImpactedRF,
                    IF(UPPER(KPIGroup)='IMPACTED' AND KPIGroupOrder = 1, CourierNumber, NULL) AS FirstImpactedCF,
                    IF(UPPER(KPIGroup)='IMPACTED' AND KPIGroupOrder = 1, ScanType, NULL) AS FirstImpactedScanType,
                    IF(UPPER(KPIGroup)='IMPACTED' AND KPIGroupOrder = 1, ScanStatus, NULL) AS FirstImpactedScanStatus,
                    IF(UPPER(KPIGroup)='FUTILE' AND KPIGroupOrder = 1, ScanDate, NULL) AS FirstFutileDate,
                    IF(UPPER(KPIGroup)='FUTILE' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS FirstFutileRF,
                    IF(UPPER(KPIGroup)='FUTILE' AND KPIGroupOrder = 1, CourierNumber, NULL) AS FirstFutileCF,
                    IF(UPPER(KPIGroup)='FUTILE' AND KPIGroupOrder = 1, ScanType, NULL) AS FirstFutileScanType,
                    IF(UPPER(KPIGroup)='FUTILE' AND KPIGroupOrder = 1, ScanStatus, NULL) AS FirstFutileScanStatus
                FROM 
                (
                    SELECT  
                        scan.LabelNo, scan.ScanDate, k.KPIGroup,
                        ROW_NUMBER() OVER(PARTITION BY scan.LabelNo ORDER BY scan.ScanDate, scan.TrackAndTraceID) AS ScanOrder,
                        ROW_NUMBER() OVER(PARTITION BY scan.LabelNo ORDER BY scan.ScanDate DESC, scan.TrackAndTraceID DESC) AS ScanReverse,
                        ROW_NUMBER() OVER(PARTITION BY scan.LabelNo, k.KPIGroup ORDER BY scan.ScanDate, scan.TrackAndTraceID) AS KPIGroupOrder,
                        ROW_NUMBER() OVER(PARTITION BY scan.LabelNo, k.KPIGroup ORDER BY scan.ScanDate DESC, scan.TrackAndTraceID DESC) AS KPIGroupReverse,
                        ROW_NUMBER() OVER(PARTITION BY scan.LabelNo, scan.ScanType ORDER BY scan.ScanDate, scan.TrackAndTraceID) AS ScanTypeOrder,
                        scan.CountryName, scan.FranchiseeCode, scan.CourierNumber, scan.ScanType, scan.ScanStatus
                    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Scan_By_LabelNo` AS scan
                    JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_KPI_Labels_Stg` batch 
                        ON batch.LabelNo = scan.LabelNo
                    LEFT JOIN (
                        `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPICodes` AS k
                        INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Country` AS dc
                        ON dc.CountryCode = k.CountryCode
                    )
                    ON scan.ScanStatus = k.ScanStatus AND scan.CountryName = dc.CountryName
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
    CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
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
