-- ==========================================================================================
-- Routine:     Load_Fact_Delivery_Performance
-- Description: Refreshes Fact_Delivery_Performance from Fact_Scan_KPI
-- Example:     Exec [dbo].[Load_Fact_Delivery_Performance] 533, 1
-- History:
--  28/08/2019  P. Waldron      Routine Written
--  18/02/2020  P. Waldron      Add SLA columns
--  02/04/2020  P. Waldron      Change schema and main select query
--  09/04/2020  P. Waldron      Removed CountryCode=1 restriction
--  27/04/2020  P. Waldron      Add DeliveryCF column
--  28/05/2020  P. Waldron      Add Category column
--  27/04/2021  B. Woods        BI-99 - Remove extra days from KPI, KPI1 & KPI2 calculations
--  22/05/2022  B. Woods        BI-254 - Categorize labels with FirstStopScanStatus = 'MAC' as 'Invalid'
--  27/06/2022  B. Woods        BI-264 - Add local bulk customers
--  09/01/2024  J. Rogers       BI-460 - Improve speed of Load_Fact_Delivery_Performance
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_Load_Fact_Delivery_Performance`(IN p_ProcessID INT64, IN p_Force INT64)
BEGIN
  /*
  ** Routine: Load_Fact_Delivery_Performance
  ** Description: Refreshes Fact_Delivery_Performance from Fact_Scan_KPI
  */

  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Component STRING DEFAULT 'dbo_Load_Fact_Delivery_Performance';
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING;
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_Inserted INT64 DEFAULT 0;
  DECLARE v_Updated INT64 DEFAULT 0;

  BEGIN
    -- Handle the TRUNCATE logic if p_Force is 1 (simulating SQL Server BIT)
    IF p_Force = 1 THEN
      TRUNCATE TABLE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Delivery_Performance`;
    END IF;

    -- MERGE Rule: Single MERGE since SP contains both INSERT and UPDATE
    MERGE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Delivery_Performance` AS Tgt
    USING (
      SELECT
        ReceivedRF,  
        DeliveryRF, 
        DeliveryCF,
        DeliveryDate,
        Category,
        COUNT(1) AS NumLabels,
        SUM(KPI) AS OnTimeKPI,
        SUM(KPI1) AS OnTimeKPI1,
        SUM(KPI2) AS OnTimeKPI2,
        SUM(SLA) AS OnTimeSLA    
      FROM (
        SELECT 
          k.FirstReceivedRF AS ReceivedRF,
          k.FirstStopRF AS DeliveryRF, 
          k.FirstStopCF AS DeliveryCF,
          -- FLAG: CONVERT without a style argument is safely translated to a standard ANSI CAST.
          CAST(k.FirstStopDate AS DATE) AS DeliveryDate, 
          CASE 
            WHEN (k.FirstReceivedRF IS NULL OR k.FirstStopScanStatus = 'MAC') THEN 'Invalid' 
            WHEN c.OESCustomerID IS NOT NULL OR lc.FMSCustomerId IS NOT NULL THEN 'Bulk'
            WHEN k.FirstReceivedRF = k.FirstStopRF THEN 'Local' 
            ELSE 'Interbranch' 
          END AS Category,
          CASE WHEN k.KPI + k.StopHoliday - k.StopDays >= 0 THEN 1 ELSE 0 END AS KPI,
          CASE WHEN k.KPI + 1 + k.StopHoliday - k.StopDays >= 0 THEN 1 ELSE 0 END AS KPI1,
          CASE WHEN k.KPI + 2 + k.StopHoliday - k.StopDays >= 0 THEN 1 ELSE 0 END AS KPI2,
          CASE WHEN k.SLA + k.DeliveryHoliday - k.DeliveryDays >= 0 THEN 1 ELSE 0 END AS SLA
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Scan_KPI_partitioned` AS k
        INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_RF` AS r ON k.FirstStopRF = r.FranchiseeCode
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label_partitioned` AS l ON k.LabelNo = l.LabelNo AND r.CountryCode = l.CountryCode
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIBulkCustomer` AS c ON l.OESCustomerID = c.OESCustomerID AND l.CountryCode = c.CountryCode
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIBulkLocalCustomer` AS lc ON l.FMSCustomerID = lc.FMSCustomerId AND l.CountryCode = lc.CountryCode            
      ) AS d
      GROUP BY ReceivedRF, DeliveryRF, DeliveryCF, DeliveryDate, Category
    ) AS Src
    ON Tgt.ReceivedRF = Src.ReceivedRF 
       AND Tgt.DeliveryRF = Src.DeliveryRF 
       AND Tgt.DeliveryCF = Src.DeliveryCF 
       AND Tgt.DeliveryDate = Src.DeliveryDate

    -- Replaced EXCEPT logic with IS DISTINCT FROM for BigQuery optimization
    WHEN MATCHED AND (
      Tgt.Category IS DISTINCT FROM Src.Category OR
      Tgt.NumLabels IS DISTINCT FROM Src.NumLabels OR
      Tgt.OnTimeKPI IS DISTINCT FROM Src.OnTimeKPI OR
      Tgt.OnTimeKPI1 IS DISTINCT FROM Src.OnTimeKPI1 OR
      Tgt.OnTimeKPI2 IS DISTINCT FROM Src.OnTimeKPI2 OR
      Tgt.OnTimeSLA IS DISTINCT FROM Src.OnTimeSLA
    )
    THEN UPDATE SET
      Category = Src.Category,
      NumLabels = Src.NumLabels,
      OnTimeKPI = Src.OnTimeKPI,
      OnTimeKPI1 = Src.OnTimeKPI1,
      OnTimeKPI2 = Src.OnTimeKPI2,
      OnTimeSLA = Src.OnTimeSLA,
      ProcessId = p_ProcessID,
      Updated = v_Loaded

    WHEN NOT MATCHED BY TARGET THEN
      INSERT (
        ReceivedRF,
        DeliveryRF,
        DeliveryCF,
        DeliveryDate,
        Category,
        NumLabels,
        OnTimeKPI,
        OnTimeKPI1,
        OnTimeKPI2,
        OnTimeSLA,
        ProcessId,
        Created,
        Updated
      )
      VALUES (
        Src.ReceivedRF,
        Src.DeliveryRF,
        Src.DeliveryCF,
        Src.DeliveryDate,
        Src.Category,
        Src.NumLabels,
        Src.OnTimeKPI,
        Src.OnTimeKPI1,
        Src.OnTimeKPI2,
        Src.OnTimeSLA,
        p_ProcessID,
        v_Loaded,
        v_Loaded 
      );

    -- When MERGE is used: @@row_count returns total rows affected (inserts + updates combined).
    -- Original SQL Server OUTPUT tracking mapped to this standard approach.
    SET v_Updated = @@row_count;
    SET v_Inserted = 0;
    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result = 'Failed';
    SET v_ErrorMessage = @@error.message;
  END;

  -- Logging Rule: Every translated SP MUST end with CALL Staging_SaveLog covering success and failure
  SET v_Ended = CURRENT_DATETIME();
  CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
    v_Component,
    p_ProcessID,
    v_Started,
    v_Ended,
    v_Result,
    v_ErrorMessage,
    v_Inserted,
    v_Updated,
    -1
  );

END;