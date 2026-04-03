
-- ==========================================================================================
-- Routine:		Load_Fact_Scan_KPI_Stg
-- Description: Recalc scan KPI stats for Labels that have just arrived
-- Example:		Exec [Staging].[Load_Fact_Scan_KPI_Stg2] 124
-- History:
--	11/04/2019  P. Waldron		Routine Written
--	01/07/2019  P. Waldron		Add First/Last Scan elements
--  20/11/2019  P. Waldron		Change Inner Join on dbo.KPILabels to Left Join
--  14/02/2020  P. Waldron      Refactor for new KPI Groups
--  29/04/2020  P. Waldron      Use ScanTypeOrder for FirstPscan and FirstDscan calcs
-- ==========================================================================================


CREATE OR REPLACE PROCEDURE `Staging.Load_Fact_Scan_KPI_Stg`(
    IN p_ProcessID INT64
)
BEGIN
    -- System and Logging Variables
    DECLARE v_Component STRING DEFAULT 'Staging.Load_Fact_Scan_KPI_Stg';
    DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Ended TIMESTAMP;
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;

    -- Control Variables
    DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_LastID INT64;
    DECLARE v_MinScanDate DATETIME DEFAULT DATETIME_SUB(CURRENT_DATETIME(), INTERVAL 1 YEAR);

    -- Get Max ID to check if there is data to process
    SET v_LastID = (SELECT COALESCE(MAX(ID), 0) FROM `Staging.KPI_Labels_Stg`);

    IF v_LastID = 0 THEN
        -- BQ Procedures don't return datasets dynamically like SQL Server, 
        -- but we can log the empty execution or just return gracefully.
        RETURN;
    END IF;

    BEGIN
        -- NOTE: The SQL Server WHILE loop for 30k batching has been removed. 
        -- BigQuery is optimized to run the entire set at once much faster.
        
        INSERT INTO `Staging.Fact_Scan_KPI_Stg` (
            LabelNo,
            -- Scan
            FirstScanDate, FirstScanRF, FirstScanCF, FirstScanType, FirstScanStatus,
            LastScanDate, LastScanRF, LastScanCF, LastScanType, LastScanStatus,
            -- Pscan
            FirstPscanDate, FirstPscanRF, FirstPscanCF, FirstPScanStatus, 
            -- Dscan
            FirstDscanDate, FirstDscanRF, FirstDscanCF, FirstDScanStatus,
            -- Received
            FirstReceivedDate, FirstReceivedRF, FirstReceivedCF, FirstReceivedScanType, FirstReceivedScanStatus,
            LastReceivedDate, LastReceivedRF, LastReceivedCF, LastReceivedScanType, LastReceivedScanStatus,
            -- Sorted
            FirstSortedDate, FirstSortedRF, FirstSortedCF, FirstSortedScanType, FirstSortedScanStatus,
            LastSortedDate, LastSortedRF, LastSortedCF, LastSortedScanType, LastSortedScanStatus,
            -- Departed
            FirstDepartedDate, FirstDepartedRF, FirstDepartedCF, FirstDepartedScanType, FirstDepartedScanStatus,
            LastDepartedDate, LastDepartedRF, LastDepartedCF, LastDepartedScanType, LastDepartedScanStatus,
            -- Arrived
            FirstArrivedDate, FirstArrivedRF, FirstArrivedCF, FirstArrivedScanType, FirstArrivedScanStatus,
            LastArrivedDate, LastArrivedRF, LastArrivedCF, LastArrivedScanType, LastArrivedScanStatus,
            -- Out
            FirstOutDate, FirstOutRF, FirstOutCF, FirstOutScanType, FirstOutScanStatus,
            LastOutDate, LastOutRF, LastOutCF, LastOutScanType, LastOutScanStatus,
            -- Stop Clock
            FirstStopDate, FirstStopRF, FirstStopCF, FirstStopScanType, FirstStopScanStatus,
            LastStopDate, LastStopRF, LastStopCF, LastStopScanType, LastStopScanStatus,
            -- Delivery
            FirstDeliveryDate, FirstDeliveryRF, FirstDeliveryCF, FirstDeliveryScanType, FirstDeliveryScanStatus,
            LastDeliveryDate, LastDeliveryRF, LastDeliveryCF, LastDeliveryScanType, LastDeliveryScanStatus,
            -- Impacted
            FirstImpactedDate, FirstImpactedRF, FirstImpactedCF, FirstImpactedScanType, FirstImpactedScanStatus,
            -- Futile
            FirstFutileDate, FirstFutileRF, FirstFutileCF, FirstFutileScanType, FirstFutileScanStatus,
            -- Calculations
            StopDays, StopHoliday, KPI, SingleCycle, SubDepot, DeliveryDays, DeliveryHoliday, SLA,
            -- Other 
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
            (SELECT COUNT(*) FROM `dbo.KPIExcludedDates` xd 
             WHERE xd.Franchise = FirstStopRF AND xd.Date BETWEEN DATE(FirstReceivedDate) AND DATE(FirstStopDate)) AS StopHoliday,
            
            -- KPI
            (SELECT MAX(m.Days) FROM `dbo.KPIMatrix` m 
             WHERE m.PickupFranchise = FirstReceivedRF AND m.DeliveryFranchise = FirstStopRF) AS KPI,
             
            -- SingleCycle
            (SELECT COUNT(DISTINCT sc.CFCode) FROM `dbo.SingleCycleCF` sc 
             WHERE sc.RFCode = COALESCE(FirstStopRF, FirstDeliveryRF) AND sc.CFCode = COALESCE(FirstStopCF, FirstDeliveryCF)) AS SingleCycle,
             
            -- SubDepot
            (SELECT COUNT(DISTINCT sd.SubDepotCode) FROM `dbo.SubDepot` sd 
             WHERE sd.DeedRF = COALESCE(FirstStopRF, FirstDeliveryRF) AND sd.CF = COALESCE(FirstStopCF, FirstDeliveryCF)) AS SubDepot,
             
            -- DeliveryDays
            (DATE_DIFF(DATE(FirstDeliveryDate), DATE(FirstReceivedDate), DAY) 
                - DATE_DIFF(DATE(FirstDeliveryDate), DATE(FirstReceivedDate), WEEK) * 2 
                - IF(EXTRACT(DAYOFWEEK FROM FirstReceivedDate) = 1, 1, 0) 
            ) + IF(EXTRACT(DAYOFWEEK FROM FirstDeliveryDate) = 1, 1, 0) AS DeliveryDays,
            
            -- DeliveryHoliday
            (SELECT COUNT(*) FROM `dbo.KPIExcludedDates` xd 
             WHERE xd.Franchise = FirstDeliveryRF AND xd.Date BETWEEN DATE(FirstReceivedDate) AND DATE(FirstDeliveryDate)) AS DeliveryHoliday,
             
            -- SLA
            (SELECT MAX(m.Days) FROM `dbo.KPICustomerMatrix` m 
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
                -- Scan
                MIN(FirstScanDate) AS FirstScanDate, MIN(FirstScanRF) AS FirstScanRF, MIN(FirstScanCF) AS FirstScanCF, MIN(FirstScanType) AS FirstScanType, MIN(FirstScanStatus) AS FirstScanStatus, 
                MIN(LastScanDate) AS LastScanDate, MIN(LastScanRF) AS LastScanRF, MIN(LastScanCF) AS LastScanCF, MIN(LastScanType) AS LastScanType, MIN(LastScanStatus) AS LastScanStatus, 
                -- PScan
                MIN(FirstPScanDate) AS FirstPScanDate, MIN(FirstPScanRF) AS FirstPScanRF, MIN(FirstPScanCF) AS FirstPScanCF, MIN(FirstPScanStatus) AS FirstPScanStatus,
                -- DScan
                MIN(FirstDScanDate) AS FirstDScanDate, MIN(FirstDScanRF) AS FirstDScanRF, MIN(FirstDScanCF) AS FirstDScanCF, MIN(FirstDScanStatus) AS FirstDScanStatus,
                -- Received
                MIN(FirstReceivedDate) AS FirstReceivedDate, MIN(FirstReceivedRF) AS FirstReceivedRF, MIN(FirstReceivedCF) AS FirstReceivedCF, MIN(FirstReceivedScanType) AS FirstReceivedScanType, MIN(FirstReceivedScanStatus) AS FirstReceivedScanStatus,
                MIN(LastReceivedDate) AS LastReceivedDate, MIN(LastReceivedRF) AS LastReceivedRF, MIN(LastReceivedCF) AS LastReceivedCF, MIN(LastReceivedScanType) AS LastReceivedScanType, MIN(LastReceivedScanStatus) AS LastReceivedScanStatus,
                -- Sorted  
                MIN(FirstSortedDate) AS FirstSortedDate, MIN(FirstSortedRF) AS FirstSortedRF, MIN(FirstSortedCF) AS FirstSortedCF, MIN(FirstSortedScanType) AS FirstSortedScanType, MIN(FirstSortedScanStatus) AS FirstSortedScanStatus,
                MIN(LastSortedDate) AS LastSortedDate, MIN(LastSortedRF) AS LastSortedRF, MIN(LastSortedCF) AS LastSortedCF, MIN(LastSortedScanType) AS LastSortedScanType, MIN(LastSortedScanStatus) AS LastSortedScanStatus,
                -- Departed  
                MIN(FirstDepartedDate) AS FirstDepartedDate, MIN(FirstDepartedRF) AS FirstDepartedRF, MIN(FirstDepartedCF) AS FirstDepartedCF, MIN(FirstDepartedScanType) AS FirstDepartedScanType, MIN(FirstDepartedScanStatus) AS FirstDepartedScanStatus,
                MIN(LastDepartedDate) AS LastDepartedDate, MIN(LastDepartedRF) AS LastDepartedRF, MIN(LastDepartedCF) AS LastDepartedCF, MIN(LastDepartedScanType) AS LastDepartedScanType, MIN(LastDepartedScanStatus) AS LastDepartedScanStatus,
                -- Arrived  
                MIN(FirstArrivedDate) AS FirstArrivedDate, MIN(FirstArrivedRF) AS FirstArrivedRF, MIN(FirstArrivedCF) AS FirstArrivedCF, MIN(FirstArrivedScanType) AS FirstArrivedScanType, MIN(FirstArrivedScanStatus) AS FirstArrivedScanStatus,
                MIN(LastArrivedDate) AS LastArrivedDate, MIN(LastArrivedRF) AS LastArrivedRF, MIN(LastArrivedCF) AS LastArrivedCF, MIN(LastArrivedScanType) AS LastArrivedScanType, MIN(LastArrivedScanStatus) AS LastArrivedScanStatus,
                -- Out  
                MIN(FirstOutDate) AS FirstOutDate, MIN(FirstOutRF) AS FirstOutRF, MIN(FirstOutCF) AS FirstOutCF, MIN(FirstOutScanType) AS FirstOutScanType, MIN(FirstOutScanStatus) AS FirstOutScanStatus,
                MIN(LastOutDate) AS LastOutDate, MIN(LastOutRF) AS LastOutRF, MIN(LastOutCF) AS LastOutCF, MIN(LastOutScanType) AS LastOutScanType, MIN(LastOutScanStatus) AS LastOutScanStatus,
                -- Stop Clock
                MIN(FirstStopDate) AS FirstStopDate, MIN(FirstStopRF) AS FirstStopRF, MIN(FirstStopCF) AS FirstStopCF, MIN(FirstStopScanType) AS FirstStopScanType, MIN(FirstStopScanStatus) AS FirstStopScanStatus,
                MIN(LastStopDate) AS LastStopDate, MIN(LastStopRF) AS LastStopRF, MIN(LastStopCF) AS LastStopCF, MIN(LastStopScanType) AS LastStopScanType, MIN(LastStopScanStatus) AS LastStopScanStatus,
                -- Delivery
                MIN(FirstDeliveryDate) AS FirstDeliveryDate, MIN(FirstDeliveryRF) AS FirstDeliveryRF, MIN(FirstDeliveryCF) AS FirstDeliveryCF, MIN(FirstDeliveryScanType) AS FirstDeliveryScanType, MIN(FirstDeliveryScanStatus) AS FirstDeliveryScanStatus,
                MIN(LastDeliveryDate) AS LastDeliveryDate, MIN(LastDeliveryRF) AS LastDeliveryRF, MIN(LastDeliveryCF) AS LastDeliveryCF, MIN(LastDeliveryScanType) AS LastDeliveryScanType, MIN(LastDeliveryScanStatus) AS LastDeliveryScanStatus,
                -- Impacted
                MIN(FirstImpactedDate) AS FirstImpactedDate, MIN(FirstImpactedRF) AS FirstImpactedRF, MIN(FirstImpactedCF) AS FirstImpactedCF, MIN(FirstImpactedScanType) AS FirstImpactedScanType, MIN(FirstImpactedScanStatus) AS FirstImpactedScanStatus,
                -- Futile
                MIN(FirstFutileDate) AS FirstFutileDate, MIN(FirstFutileRF) AS FirstFutileRF, MIN(FirstFutileCF) AS FirstFutileCF, MIN(FirstFutileScanType) AS FirstFutileScanType, MIN(FirstFutileScanStatus) AS FirstFutileScanStatus
            FROM 
            (
                SELECT  
                    LabelNo,
                    -- Scan
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
                    -- Pscan
                    IF(ScanType='P' AND ScanTypeOrder = 1, ScanDate, NULL) AS FirstPscanDate,
                    IF(ScanType='P' AND ScanTypeOrder = 1, FranchiseeCode, NULL) AS FirstPscanRF,
                    IF(ScanType='P' AND ScanTypeOrder = 1, CourierNumber, NULL) AS FirstPscanCF,
                    IF(ScanType='P' AND ScanTypeOrder = 1, ScanStatus, NULL) AS FirstPScanStatus,
                    -- Dscan
                    IF(ScanType='D' AND ScanTypeOrder = 1, ScanDate, NULL) AS FirstDscanDate,
                    IF(ScanType='D' AND ScanTypeOrder = 1, FranchiseeCode, NULL) AS FirstDscanRF,
                    IF(ScanType='D' AND ScanTypeOrder = 1, CourierNumber, NULL) AS FirstDscanCF,
                    IF(ScanType='D' AND ScanTypeOrder = 1, ScanStatus, NULL) AS FirstDScanStatus,
                    -- Received
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
                    -- Sorted
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
                    -- Departed
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
                    -- Arrived
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
                    -- Out
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
                    -- Stop Clock
                    IF(KPIGroup='Stop' AND KPIGroupOrder = 1, ScanDate, NULL) AS FirstStopDate,
                    IF(KPIGroup='Stop' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS FirstStopRF,
                    IF(KPIGroup='Stop' AND KPIGroupOrder = 1, CourierNumber, NULL) AS FirstStopCF,
                    IF(KPIGroup='Stop' AND KPIGroupOrder = 1, ScanType, NULL) AS FirstStopScanType,
                    IF(KPIGroup='Stop' AND KPIGroupOrder = 1, ScanStatus, NULL) AS FirstStopScanStatus,
                    IF(KPIGroup='Stop' AND KPIGroupReverse = 1, ScanDate, NULL) AS LastStopDate,
                    IF(KPIGroup='Stop' AND KPIGroupReverse = 1, FranchiseeCode, NULL) AS LastStopRF,
                    IF(KPIGroup='Stop' AND KPIGroupReverse = 1, CourierNumber, NULL) AS LastStopCF,
                    IF(KPIGroup='Stop' AND KPIGroupReverse = 1, ScanType, NULL) AS LastStopScanType,
                    IF(KPIGroup='Stop' AND KPIGroupReverse = 1, ScanStatus, NULL) AS LastStopScanStatus,
                    -- Delivery
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
                    -- Impacted Scan
                    IF(KPIGroup='Impacted' AND KPIGroupOrder = 1, ScanDate, NULL) AS FirstImpactedDate,
                    IF(KPIGroup='Impacted' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS FirstImpactedRF,
                    IF(KPIGroup='Impacted' AND KPIGroupOrder = 1, CourierNumber, NULL) AS FirstImpactedCF,
                    IF(KPIGroup='Impacted' AND KPIGroupOrder = 1, ScanType, NULL) AS FirstImpactedScanType,
                    IF(KPIGroup='Impacted' AND KPIGroupOrder = 1, ScanStatus, NULL) AS FirstImpactedScanStatus,
                    -- Futile Scan
                    IF(KPIGroup='Futile' AND KPIGroupOrder = 1, ScanDate, NULL) AS FirstFutileDate,
                    IF(KPIGroup='Futile' AND KPIGroupOrder = 1, FranchiseeCode, NULL) AS FirstFutileRF,
                    IF(KPIGroup='Futile' AND KPIGroupOrder = 1, CourierNumber, NULL) AS FirstFutileCF,
                    IF(KPIGroup='Futile' AND KPIGroupOrder = 1, ScanType, NULL) AS FirstFutileScanType,
                    IF(KPIGroup='Futile' AND KPIGroupOrder = 1, ScanStatus, NULL) AS FirstFutileScanStatus

                FROM 
                (
                    SELECT  
                        scan.LabelNo, 
                        scan.ScanDate, 
                        k.KPIGroup,
                        ROW_NUMBER() OVER(PARTITION BY scan.LabelNo ORDER BY scan.ScanDate) AS ScanOrder,
                        ROW_NUMBER() OVER(PARTITION BY scan.LabelNo ORDER BY scan.ScanDate DESC) AS ScanReverse,
                        ROW_NUMBER() OVER(PARTITION BY scan.LabelNo, k.KPIGroup ORDER BY scan.ScanDate) AS KPIGroupOrder,
                        ROW_NUMBER() OVER(PARTITION BY scan.LabelNo, k.KPIGroup ORDER BY scan.ScanDate DESC) AS KPIGroupReverse,
                        ROW_NUMBER() OVER(PARTITION BY scan.LabelNo, scan.ScanType ORDER BY scan.ScanDate) AS ScanTypeOrder,
                        scan.CountryName,
                        scan.FranchiseeCode, 
                        scan.CourierNumber, 
                        scan.ScanType,
                        scan.ScanStatus
                    FROM `dv.LNK_Scan_By_LabelNo` AS scan 
                    JOIN `Staging.KPI_Labels_Stg` batch 
                        ON batch.LabelNo = scan.LabelNo
                    LEFT JOIN `dbo.KPICodes` AS k 
                        ON scan.ScanStatus = k.ScanStatus 
                    LEFT JOIN `dbo.Dim_Country` AS dc 
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

    -- Record load metrics in log
    SET v_Ended = CURRENT_TIMESTAMP();
    CALL `Staging.SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,
        v_Ended,
        v_Result,
        v_ErrorMessage,
        v_Inserted,
        0,
        IF(v_Result = 'Success', 0, -1)
    );

END;