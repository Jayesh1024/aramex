CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.rpt_GetAgingbyDate`(
    IN p_ReportDate DATETIME
)
BEGIN
    -- CTE 1: Fetch base label data
    WITH labels AS (
        SELECT  
            k.LabelNo, 
            DATE(k.FirstReceivedDate) AS PickupDate, 
            k.FirstReceivedRF AS PickupRF, 
            k.FirstReceivedRF AS PickupCF, 
            (CASE 
                WHEN FastLabel_DestinationRF IS NOT NULL THEN FastLabel_DestinationRF 
                WHEN DeedRF IS NOT NULL THEN DeedRF 
                WHEN k.LastSortedScanStatus IS NOT NULL AND k.LastSortedScanStatus NOT IN ('UNW', 'MIX', 'STC') THEN k.LastSortedScanStatus 
                WHEN k.FirstOutRF IS NOT NULL THEN k.FirstOutRF 
                ELSE '' 
             END) AS DestRF,
            p.CFDeliveryString AS DestCF,
            m.Days AS MatrixDays
        FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_Fact_Scan_KPI` AS k
        INNER JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_Dim_RF` AS r 
            ON k.FirstReceivedRF = r.FranchiseeCode 
        LEFT OUTER JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_Dim_Label` AS l 
            ON k.LabelNo = l.LabelNo AND r.CountryCode = l.CountryCode 
        LEFT OUTER JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_TSS_PostCodeMaster` AS p 
            ON l.DeliveryPostcode = RTRIM(p.PostCode) 
            AND UPPER(LTRIM(l.DeliveryTown)) = RTRIM(p.Suburb) 
            AND p.CountryCode IN (1,6) 
        LEFT JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_KPIMatrix` m 
            ON k.FirstReceivedRF = m.PickupFranchise 
            AND (CASE 
                WHEN FastLabel_DestinationRF IS NOT NULL THEN FastLabel_DestinationRF 
                WHEN DeedRF IS NOT NULL THEN DeedRF 
                WHEN k.LastSortedScanStatus IS NOT NULL AND k.LastSortedScanStatus NOT IN ('UNW', 'MIX', 'STC') THEN k.LastSortedScanStatus 
                WHEN k.FirstOutRF IS NOT NULL THEN k.FirstOutRF 
                ELSE '' 
             END) = m.DeliveryFranchise
        WHERE 
            k.FirstScanDate >= DATE_SUB(DATE(p_ReportDate), INTERVAL 3 MONTH) AND 
            (DATE(k.FirstReceivedDate) >= DATE_SUB(DATE(p_ReportDate), INTERVAL 1 MONTH) AND DATE(k.FirstReceivedDate) < DATE(p_ReportDate)) 
            AND (DATE(k.FirstStopDate) > DATE(p_ReportDate) OR k.FirstStopDate IS NULL) 
            AND (r.CountryCode = 1) 
            AND (SUBSTR(k.LabelNo, 1, 2) <> '5A') 
            AND k.LastScanStatus NOT IN ('ONF', 'RTS', 'FUT', 'RUD', 'N/A', 'CCP', 'BDS', 'O07')
    ),

    -- CTE 2: Calculate the target "Nth" day offset
    target_offsets AS (
        SELECT 
            LabelNo,
            PickupDate,
            PickupRF,
            DestRF,
            DestCF,
            CAST(COALESCE((CASE WHEN PickupRF = DestRF THEN 1 ELSE MatrixDays + 1 END), 0) AS INT64) AS TargetOffset
        FROM labels
    ),

    -- CTE 3: Expand each label against the calendar to find working days
    calendar_ranking AS (
        SELECT 
            t.LabelNo,
            dt.Calendar_Date,
            -- Rank working days starting from the PickupDate
            ROW_NUMBER() OVER(PARTITION BY t.LabelNo ORDER BY dt.Calendar_Date ASC) - 1 AS WorkingDayIndex
        FROM target_offsets t
        CROSS JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_Dim_Time` dt
        LEFT JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_KPIExcludedDates` ex 
            ON dt.Calendar_Date = ex.Date AND ex.Franchise = ''
        WHERE dt.Calendar_Date >= t.PickupDate 
          AND dt.week_day_flag = 'Y' 
          AND ex.Comment IS NULL
          -- Optimization: Only look forward 30 days for performance
          AND dt.Calendar_Date <= DATE_ADD(t.PickupDate, INTERVAL 30 DAY)
    )

    -- Final Select: Prefixed columns to avoid ambiguity
    SELECT 
        t.DestRF, 
        t.DestCF, 
        cr.Calendar_Date AS DueDate, 
        COUNT(1) AS NumofLabels, 
        p_ReportDate AS ReportDate 
    FROM calendar_ranking cr
    JOIN target_offsets t ON cr.LabelNo = t.LabelNo 
    WHERE cr.WorkingDayIndex = t.TargetOffset
    GROUP BY t.DestRF, t.DestCF, DueDate;

END;