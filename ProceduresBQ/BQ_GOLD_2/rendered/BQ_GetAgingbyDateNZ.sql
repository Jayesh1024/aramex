CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.rpt_GetAgingbyDateNZ`(
    -- OPTION 2: Use DATETIME instead of TIMESTAMP for consistency across reporting scripts
    IN p_ReportDate DATETIME
)
BEGIN
    -- ------------------------------------------------------------------------------------------
    -- Routine:     GetAgingbyDateNZ
    -- Description: Calculates NZ Label Aging based on KPIMatrix and franchise-specific working days.
    --              Uses ROW_NUMBER to bypass BigQuery's dynamic OFFSET limitation.
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
                WHEN k.LastSortedScanStatus IS NOT NULL AND k.LastSortedScanStatus NOT IN ('UNW', 'MIX') THEN k.LastSortedScanStatus 
                WHEN k.FirstOutRF IS NOT NULL THEN k.FirstOutRF 
                ELSE '' 
             END) AS DestRF,
            p.CFDeliveryString AS DestCF
        FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_Fact_Scan_KPI` AS k
        INNER JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_Dim_RF` AS r 
            ON k.FirstReceivedRF = r.FranchiseeCode 
        LEFT OUTER JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_Dim_Label` AS l 
            ON k.LabelNo = l.LabelNo AND r.CountryCode = l.CountryCode 
        LEFT OUTER JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_TSS_PostCodeMaster` AS p 
            ON l.DeliveryPostcode = RTRIM(p.PostCode) 
            AND UPPER(LTRIM(l.DeliveryTown)) = RTRIM(p.Suburb) 
            AND p.CountryCode IN (1, 6) 
        WHERE 
            k.FirstScanDate >= DATE_SUB(DATE(p_ReportDate), INTERVAL 3 MONTH) AND 
            (DATE(k.FirstReceivedDate) >= DATE_SUB(DATE(p_ReportDate), INTERVAL 1 MONTH) AND DATE(k.FirstReceivedDate) < DATE(p_ReportDate)) 
            AND (DATE(k.FirstStopDate) > DATE(p_ReportDate) OR k.FirstStopDate IS NULL) 
            AND (r.CountryCode = 6)              -- Filter for NZ
            AND (SUBSTR(k.LabelNo, 1, 1) <> '9') -- NZ specific Label prefix check
            AND k.LastScanStatus NOT IN ('ONF', 'RTS', 'FUT', 'RUD', 'N/A', 'CCP', 'BDS', 'O07')
    ),

    -- CTE 2: Calculate the Target Offset based on the KPI Matrix
    target_offsets AS (
        SELECT 
            l.*,
            CAST(COALESCE((CASE WHEN l.PickupRF = l.DestRF THEN 1 ELSE m.Days + 1 END), 0) AS INT64) AS TargetOffset
        FROM labels l
        LEFT JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_KPIMatrix` m 
            ON l.PickupRF = m.PickupFranchise AND l.DestRF = m.DeliveryFranchise
    ),

    -- CTE 3: Generate ranking of valid working days per Label
    calendar_ranking AS (
        SELECT 
            t.LabelNo,
            dt.Calendar_Date,
            -- Create an index for valid working days for each specific label/franchise
            ROW_NUMBER() OVER(PARTITION BY t.LabelNo ORDER BY dt.Calendar_Date ASC) - 1 AS WorkingDayIndex
        FROM target_offsets t
        CROSS JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_Dim_Time` dt
        LEFT JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_KPIExcludedDates` ex 
            ON dt.Calendar_Date = ex.Date 
            AND ex.Franchise = t.DestRF  -- NZ Specific logic: Filter by Destination Franchise
        WHERE dt.Calendar_Date >= t.PickupDate 
          AND dt.week_day_flag = 'Y' 
          AND ex.Comment IS NULL
    )

    -- Final Select: Match the calculated WorkingDayIndex to the TargetOffset
    SELECT 
        t.DestRF, 
        t.DestCF, 
        cr.Calendar_Date AS DueDate, 
        COUNT(1) AS NumofLabels, 
        p_ReportDate AS ReportDate 
    FROM calendar_ranking cr
    JOIN target_offsets t ON cr.LabelNo = t.LabelNo 
    WHERE cr.WorkingDayIndex = t.TargetOffset
      AND cr.Calendar_Date < DATE(p_ReportDate)  -- Final filtering of overdue records
    GROUP BY t.DestRF, t.DestCF, DueDate;

END;