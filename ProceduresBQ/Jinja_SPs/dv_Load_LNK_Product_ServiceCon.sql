-- ==========================================================================================
-- Routine:     dv_Load_LNK_Product_ServiceCon
-- Description: Loads LNK_Product_ServiceCon from `{{ project_id }}.{{ target_dataset_id }}.Staging_Product_ServiceCon_Stg`
--              BigQuery compatible version of Load_LNK_Product_ServiceCon
-- Example:     CALL dv.dv_Load_LNK_Product_ServiceCon(659, 'MyFastway')
-- History:
--  15/08/2020  P. Waldron      Routine Written
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_LNK_Product_ServiceCon`(
    IN ProcessID INT64,
    IN RecordSource STRING
)
BEGIN

    DECLARE DefaultValidFrom DATETIME DEFAULT DATETIME '1900-01-01 00:00:00';
    DECLARE DefaultValidTo   DATETIME DEFAULT DATETIME '9999-12-31 00:00:00';
    DECLARE Loaded           DATETIME DEFAULT CURRENT_DATETIME();

    DECLARE Component    STRING DEFAULT 'dv.Load_LNK_Product_ServiceCon';
    DECLARE Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING;
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64 DEFAULT 0;
    DECLARE Updated      INT64 DEFAULT 0;

    BEGIN

        -- Insert new records that don't already exist in the target
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_LNK_Product_ServiceCon`
        (
            Product_ServiceCon_HSK,
            Product_HSK,
            -- ServiceItem_HSK,
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
            -- Replicate ISNULL(IIF(...)) logic:
            -- Use DisplayText if non-empty, else Description, else fallback to ServiceItemId
            IFNULL(
                IF(SI.DisplayText <> '', SI.DisplayText, SI.Description),
                REPLACE('(:1:)', ':1:', CAST(Stg.ServiceItemId AS STRING))
            ) AS ServiceItem,
            Stg.ServiceItemId,
            Loaded        AS Loaded,
            ProcessID     AS ProcessID,
            Stg.RecordSource,
            Stg.RecordSourceId
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Product_ServiceCon_Stg` AS Stg
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.Staging_fl_ServiceItem_Stg` AS SI
            ON  Stg.CountryId    = SI.CountryId
            AND Stg.ProductId    = SI.ProductId
            AND Stg.ServiceItemId = SI.ServiceItemId
        WHERE NOT EXISTS (
            SELECT 1
            FROM `{{ project_id }}.{{ target_dataset_id }}.dv_LNK_Product_ServiceCon` AS Tgt
            WHERE Tgt.Product_ServiceCon_HSK = Stg.Product_ServiceCon_HSK
        );

        SET Inserted = @@ROW_COUNT;
        SET Result   = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed';
        SET ErrorMessage = @@error.message;

    END;

    -- Record load metrics in log
    SET Ended = CURRENT_DATETIME();
    CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
        Component,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted,
        -1,
        -1
    );

END;
