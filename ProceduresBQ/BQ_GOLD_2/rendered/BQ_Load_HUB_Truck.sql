-- ==========================================================================================
-- Routine:		Load_HUB_Truck
-- Description: Loads business keys into HUB_Truck
-- Example:		Exec [dv].[Load_HUB_Truck] 123, 'Fastway'  (40871100 rows in 19 mins)
-- History:
--	25/10/2018  P. Waldron		Routine Written
-- ==========================================================================================

CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.dv_Load_HUB_Truck`(
    IN p_ProcessID INT64,
    IN p_RecordSource STRING
)
OPTIONS(strict_mode=false)
BEGIN
    -- Standard variables for load tracking and logging
    DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Component STRING DEFAULT 'dv_Load_HUB_Truck';
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;

    BEGIN
        -- A MERGE statement handles the load pattern using Jinja2 templates for identifiers.
        -- p_RecordSource remains a dynamic input parameter as requested.
        MERGE INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dv_HUB_Truck` AS Dest
        USING (
            SELECT DISTINCT Container AS TruckNum
            FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_BBA_ContainerMaster_Stg`
            WHERE TruckOrContainer = 'T'
        ) AS Src
        ON Dest.TruckNum = Src.TruckNum
        WHEN NOT MATCHED THEN
            INSERT (
                TruckNum_HSK,
                TruckNum,
                Loaded,
                ProcessID,
                RecordSource
            )
            VALUES (
                -- UDF reference converted to Jinja2 path format
                TO_HEX(`prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.dbo_GetHashKey`(Src.TruckNum, '^')),
                Src.TruckNum,
                v_Loaded,
                p_ProcessID,
                p_RecordSource
            );

        -- Capture the number of new records inserted
        SET v_Inserted = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Final Log Call (Handles both Success and Failure metrics)
    CALL `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.Staging_SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,
        CURRENT_DATETIME(),
        v_Result,
        v_ErrorMessage,
        v_Inserted,
        v_Updated,
        -1
    );
END;