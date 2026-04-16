CREATE OR REPLACE PROCEDURE `searce-sandbox-da-delivery.Aramex_oceania_SP.dv_Load_SAT_STK_RFProducts`(
    IN p_RecordSource STRING
)
BEGIN
    -- ------------------------------------------------------------------------------------------
    -- Routine:     dv_Load_SAT_STK_RFProducts
    -- Description: Full refresh of dv_SAT_STK_RFProducts from Staging
    -- ------------------------------------------------------------------------------------------

    DECLARE v_Component STRING DEFAULT 'searce-sandbox-da-delivery.Aramex_oceania.dv_Load_SAT_STK_RFProducts';
    
    -- OPTION 2: Changed from TIMESTAMP to DATETIME
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Ended DATETIME;
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING DEFAULT NULL;
    DECLARE v_Inserted INT64 DEFAULT 0;
    
    DECLARE v_Delim STRING DEFAULT '\r'; 

    BEGIN
        -- 1. Clear the target table
        TRUNCATE TABLE `searce-sandbox-da-delivery.Aramex_oceania.dv_SAT_STK_RFProducts`;

        -- 2. Load the data from Staging
        INSERT INTO `searce-sandbox-da-delivery.Aramex_oceania.dv_SAT_STK_RFProducts` (
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
            v_Started AS Loaded, -- Now a DATETIME
            p_RecordSource AS RecordSource
        FROM `searce-sandbox-da-delivery.Aramex_oceania.Staging_STK_RFProducts_Stg`;

        -- Capture row count of the insert
        SET v_Inserted = @@row_count;

    EXCEPTION WHEN ERROR THEN
        -- Catch any system errors and log the failure
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- OPTION 2: Changed from CURRENT_TIMESTAMP() to CURRENT_DATETIME()
    SET v_Ended = CURRENT_DATETIME();

    -- Standardize Call Logging block (Option 2: Using DATETIME and status logic)
    CALL `searce-sandbox-da-delivery.Aramex_oceania_SP.Staging_SaveLog`(
        v_Component,
        -1,                 
        v_Started,
        v_Ended,
        v_Result,
        v_ErrorMessage,
        v_Inserted,         
        -1,
        -1
    );

END;