CREATE OR REPLACE PROCEDURE `dv.Load_SAT_STK_RFProducts`(
    IN p_RecordSource STRING
)
BEGIN
    -- ------------------------------------------------------------------------------------------
    -- Routine:     Load_SAT_STK_RFProducts
    -- Description: Full refresh of SAT_STK_RFProducts from Staging
    -- History:
    --  25/09/2024  B. Woods / AI   Routine written and converted to BigQuery
    -- ------------------------------------------------------------------------------------------

    DECLARE v_Component STRING DEFAULT 'dv.Load_SAT_STK_RFProducts';
    DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Ended TIMESTAMP;
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING DEFAULT NULL;
    DECLARE v_Inserted INT64 DEFAULT 0;
    
    -- Keeping @delim logic as requested (Carriage Return)
    DECLARE v_Delim STRING DEFAULT '\r'; 

    BEGIN
        -- 1. Clear the target table
        TRUNCATE TABLE `dv.SAT_STK_RFProducts`;

        -- 2. Load the data from Staging
        INSERT INTO `dv.SAT_STK_RFProducts` (
            RFCode,
            ProductId,
            QtyOnHand,
            QtyOnOrder,
            DeliveryPrice,
            PickupPrice,
            CommisionPercentage,
            IncludesGst,
            FMSBookPrice,
            ProductType,
            SalesRepCommissionPercentage,
            LocalPickup,
            UpdatedOn,
            UpdatedBy,
            Loaded,
            RecordSource
        )
        SELECT
            RFCode,
            ProductId,
            QtyOnHand,
            QtyOnOrder,
            DeliveryPrice,
            PickupPrice,
            CommisionPercentage,
            IncludesGst,
            FMSBookPrice,
            ProductType,
            SalesRepCommissionPercentage,
            LocalPickup,
            UpdatedOn,
            UpdatedBy,
            v_Started AS Loaded,
            p_RecordSource AS RecordSource
        FROM `Staging.STK_RFProducts_Stg`;

        -- Capture row count of the insert
        SET v_Inserted = @@row_count;

    EXCEPTION WHEN ERROR THEN
        -- Catch any system errors and log the failure
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Record load metrics in log
    SET v_Ended = CURRENT_TIMESTAMP();

    CALL `Staging.SaveLog`(
        v_Component,
        -1,                 -- ProcessID default
        v_Started,
        v_Ended,
        v_Result,
        v_ErrorMessage,
        v_Inserted,         -- Inserted
        0                   -- Updated
    );

END;