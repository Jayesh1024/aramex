-- ==========================================================================================
-- Routine:     dv_Load_Weekly_Priced_Invoices
-- Description: Checks API_RF_AdHocLabel_AllocationHistory_Stg for any price or FMSInvoiceID
--              changes occurring during the previous week.
--              BigQuery compatible version of Load_Weekly_Priced_Invoices
--              Note: UPDATE ... FROM replaced with MERGE (BQ requires MERGE for UPDATE with JOIN).
--                    SET ANSI_WARNINGS OFF removed (not applicable in BQ).
-- Example:     CALL dv.dv_Load_Weekly_Priced_Invoices(649, <lastID>)
-- History:
--  13/07/2021  B. Woods        Routine Written
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.dv_Load_Weekly_Priced_Invoices`(
    IN ProcessID INT64,
    IN LastID    INT64
)
BEGIN

    DECLARE Component    STRING DEFAULT 'dv.Load_Weekly_Priced_Invoices';
    DECLARE SubComponent STRING;
    DECLARE Step         STRING;
    DECLARE Started      DATETIME;
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING DEFAULT 'Success';
    DECLARE ErrorMessage STRING;
    DECLARE Updated      INT64 DEFAULT 0;
    DECLARE FromID       INT64;

    SET Step      = 'Update';
    SET Started   = CURRENT_DATETIME();
    -- 1 mil rows ≈ approx 1 week of allocations
    SET FromID    = LastID - 1000000;
    SET Updated   = 0;

    -- -----------------------------------------------------------------------
    -- UPDATE: replicate UPDATE ... FROM ... INNER JOIN using MERGE
    -- Updates Price and FMSInvoiceID on current rows that meet change criteria
    -- -----------------------------------------------------------------------
    MERGE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_DL` AS DL
    USING (
        SELECT
            H.HistoryID,
            H.PriceSoldAtExGST,
            H.FMSInvoiceID
        FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_API_RF_AdHocLabel_AllocationHistory_Stg` H
    ) AS H
    ON  DL.RecordSourceId = H.HistoryID
    AND DL.IsCurrent      = 1
    AND DL.RecordSourceId > FromID
    AND (
        (DL.Price = 999 AND H.PriceSoldAtExGST <> 999)
        OR
        (IFNULL(DL.FMSInvoiceID, 0) = 0 AND IFNULL(H.FMSInvoiceID, 0) <> 0)
    )
    WHEN MATCHED THEN UPDATE SET
        DL.Price        = H.PriceSoldAtExGST,
        DL.FMSInvoiceID = H.FMSInvoiceID;

    SET Updated = @@ROW_COUNT;

    SET Ended        = CURRENT_DATETIME();
    SET SubComponent = Component || ' (' || Step || ')';

    CALL `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.Staging_SaveLog`(
        SubComponent,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        0,
        Updated,
        -1
        
    );

END;