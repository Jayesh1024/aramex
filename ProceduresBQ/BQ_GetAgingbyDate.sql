{#-- ==========================================================================================
Routine:     rpt_GetAgingbyDate
Description: Calculates Label Aging based on KPIMatrix and working day calendars.
History:
  Converted from SQL Server to BigQuery
========================================================================================== --#}

CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id}}.rpt_GetAgingbyDate`(
    IN p_ReportDate TIMESTAMP
)
BEGIN
    -- ------------------------------------------------------------------------------------------
    -- Routine:     GetAgingbyDate
    -- Description: Calculates Label Aging based on KPIMatrix and working day calendars.
    -- ------------------------------------------------------------------------------------------

    WITH labels AS (
        SELECT  
            k.LabelNo, 
            DATE(k.FirstReceivedDate) AS PickupDate, 
            k.FirstReceivedRF AS PickupRF, 
            k.FirstReceivedCF AS PickupCF, 
            (CASE 
                WHEN FastLabel_DestinationRF IS NOT NULL THEN FastLabel_DestinationRF 
                WHEN DeedRF IS NOT NULL THEN DeedRF 
                WHEN k.LastSortedScanStatus IS NOT NULL AND k.LastSortedScanStatus NOT IN ('UNW', 'MIX', 'STC') THEN k.LastSortedScanStatus 
                WHEN k.FirstOutRF IS NOT NULL THEN k.FirstOutRF 
                ELSE '' 
             END) AS DestRF,
            p.CFDeliveryString AS DestCF
        FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_Scan_KPI` AS k
        INNER JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_RF` AS r 
            ON k.FirstReceivedRF = r.FranchiseeCode 
        LEFT OUTER JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Label` AS l 
            ON k.LabelNo = l.LabelNo AND r.CountryCode = l.CountryCode 
        LEFT OUTER JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_TSS_PostCodeMaster` AS p 
            ON l.DeliveryPostcode = RTRIM(p.PostCode) 
            AND UPPER(LTRIM(l.DeliveryTown)) = RTRIM(p.Suburb) 
            AND p.CountryCode IN (1,6) 
        WHERE 
            k.FirstScanDate >= DATE_SUB(DATE(p_ReportDate), INTERVAL 3 MONTH) AND 
            (DATE(k.FirstReceivedDate) >= DATE_SUB(DATE(p_ReportDate), INTERVAL 1 MONTH) AND DATE(k.FirstReceivedDate) < DATE(p_ReportDate)) 
            AND (DATE(k.FirstStopDate) > DATE(p_ReportDate) OR k.FirstStopDate IS NULL) 
            AND (r.CountryCode = 1) 
            AND (SUBSTR(k.LabelNo, 1, 2) <> '5A') 
            AND k.LastScanStatus NOT IN ('ONF', 'RTS', 'FUT', 'RUD', 'N/A', 'CCP', 'BDS', 'O07')
    )

    SELECT 
        DestRF, 
        DestCF, 
        DueDate, 
        COUNT(1) AS NumofLabels, 
        p_ReportDate AS ReportDate 
    FROM (
        SELECT 
            l.*, 
            (CASE WHEN PickupRF = DestRF THEN m.Days ELSE m.Days + 1 END) AS KPIDays,
            -- Subquery to calculate the Nth working day based on KPI Matrix days
            (SELECT Calendar_Date
             FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Time` AS dt
             LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIExcludedDates` AS ex 
                ON dt.Calendar_Date = ex.Date AND ex.Franchise = ''
             WHERE dt.Calendar_Date >= l.PickupDate 
               AND dt.week_day_flag = 'Y' 
               AND ex.Comment IS NULL 
             ORDER BY dt.Calendar_Date
             LIMIT 1 OFFSET CAST(COALESCE((CASE WHEN PickupRF = DestRF THEN 1 ELSE m.Days + 1 END), 0) AS INT64)
            ) AS DueDate
        FROM labels l
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIMatrix` m 
            ON l.PickupRF = m.PickupFranchise AND l.DestRF = m.DeliveryFranchise
    ) AS final_set
    GROUP BY DestRF, DestCF, DueDate;

END;