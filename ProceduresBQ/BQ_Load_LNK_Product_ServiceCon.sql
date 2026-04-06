-- ==========================================================================================
-- Routine:     Load_LNK_Product_ServiceCon  (BigQuery Version)
-- Description: Loads LNK_Label_Product_ServiceItem from Staging.fl_ConItemSrv_Stg
-- Example:     CALL dv.Load_LNK_Product_ServiceCon(659, 'MyFastway')
-- History:
--  15/08/2020  P. Waldron      Routine Written
--  [BQ Migration] Converted SQL Server -> BigQuery
--    * ISNULL()         -> IFNULL()
--    * IIF()            -> IF()
--    * REPLACE w/ cast  -> REPLACE(..., CAST(val AS STRING))
--    * See file 1 header for full conversion notes
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE dv.Load_LNK_Product_ServiceCon(
    IN ProcessID    INT64,
    IN RecordSource STRING   -- Pass NULL to use default 'MyFastway'
)
BEGIN
    DECLARE v_Loaded        DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_RecordSource  STRING   DEFAULT IFNULL(RecordSource, 'MyFastway');
    DECLARE Component       STRING   DEFAULT 'dv.Load_LNK_Product_ServiceCon';
    DECLARE Started         DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended           DATETIME;
    DECLARE Result          STRING   DEFAULT 'Success';
    DECLARE ErrorMessage    STRING   DEFAULT NULL;
    DECLARE Inserted        INT64    DEFAULT 0;
    DECLARE Updated         INT64    DEFAULT 0;

    BEGIN

        INSERT INTO dv.LNK_Product_ServiceCon
        (
            Product_ServiceCon_HSK,
            Product_HSK,
            -- ServiceItem_HSK,   -- commented out as per original
            ConId,
            Country,
            ProductCode,
            ServiceItem,
            ServiceItemId,
            Loaded,
            ProcessID,
            RecordSource,
            RecordSourceId
        )
        SELECT
            Stg.Product_ServiceCon_HSK,
            Stg.Product_HSK,
            -- Stg.ServiceItem_HSK,
            Stg.ConId,
            Stg.Country,
            Stg.ProductCode,
            IFNULL(
                IF(SI.DisplayText <> '', SI.DisplayText, SI.Description),
                REPLACE('(:1:)', ':1:', CAST(Stg.ServiceItemId AS STRING))
            )               AS ServiceItem,
            Stg.ServiceItemId,
            v_Loaded        AS Loaded,
            ProcessID       AS ProcessID,
            Stg.RecordSource,
            Stg.RecordSourceId
        FROM Staging.Product_ServiceCon_Stg AS Stg
        LEFT JOIN Staging.fl_ServiceItem_Stg AS SI
            ON  Stg.CountryId    = SI.CountryId
            AND Stg.ProductId    = SI.ProductId
            AND Stg.ServiceItemId= SI.ServiceItemId
        WHERE NOT EXISTS (
            SELECT 1
            FROM dv.LNK_Product_ServiceCon AS Tgt
            WHERE Tgt.Product_ServiceCon_HSK = Stg.Product_ServiceCon_HSK
        );

        SET Inserted = @@row_count;
        SET Result   = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed';
        SET ErrorMessage = @@error_message;
    END;

    -- Record load metrics in log
    SET Ended = CURRENT_DATETIME();
    CALL Staging.SaveLog(
        Component,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted
    );

END;
