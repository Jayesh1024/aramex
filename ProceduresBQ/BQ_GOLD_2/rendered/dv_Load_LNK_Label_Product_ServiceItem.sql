-- ==========================================================================================
-- Routine:     dv_Load_LNK_Label_Product_ServiceItem
-- Description: Loads LNK_Label_Product_ServiceItem from Staging.fl_ConItemSrv_Stg
--              BigQuery compatible version of Load_LNK_Label_Product_ServiceItem
-- Example:     CALL dv.dv_Load_LNK_Label_Product_ServiceItem(659, 'MyFastway')
-- History:
--  15/08/2020  P. Waldron      Routine Written
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.dv_Load_LNK_Label_Product_ServiceItem`(
    IN ProcessID INT64,
    IN RecordSource STRING
)
BEGIN

    DECLARE DefaultValidFrom DATETIME DEFAULT DATETIME '1900-01-01 00:00:00';
    DECLARE DefaultValidTo   DATETIME DEFAULT DATETIME '9999-12-31 00:00:00';
    DECLARE Loaded           DATETIME DEFAULT CURRENT_DATETIME();

    DECLARE Component    STRING DEFAULT 'dv.Load_LNK_Label_Product_ServiceItem';
    DECLARE Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING;
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64 DEFAULT 0;
    DECLARE Updated      INT64 DEFAULT 0;

    BEGIN

        -- Insert new records that don't already exist in the target
        INSERT INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dv_LNK_Label_Product_ServiceItem`
        (
            Label_Product_ServiceItem_HSK,
            LabelNo_HSK,
            Product_HSK,
            ServiceItem_HSK,
            LabelNo,
            Country,
            ProductCode,
            ServiceItem,
            Loaded,
            ProcessID,
            RecordSource,
            RecordSourceId
        )
        SELECT
            Label_Product_ServiceItem_HSK,
            LabelNo_HSK,
            Product_HSK,
            ServiceItem_HSK,
            LabelNo,
            Country,
            ProductCode,
            ServiceItem,
            Loaded         AS Loaded,
            ProcessID      AS ProcessID,
            RecordSource,
            RecordSourceId
        FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_Label_Product_ServiceItem_Stg` AS Stg
        WHERE NOT EXISTS (
            SELECT 1
            FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dv_LNK_Label_Product_ServiceItem` AS Tgt
            WHERE Tgt.Label_Product_ServiceItem_HSK = Stg.Label_Product_ServiceItem_HSK
        );

        SET Inserted = @@ROW_COUNT;
        SET Result   = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed';
        SET ErrorMessage = @@error.message;

    END;

    -- Record load metrics in log
    SET Ended = CURRENT_DATETIME();
    CALL `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.Staging_SaveLog`(
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