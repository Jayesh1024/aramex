-- ==========================================================================================
-- Routine:		Load_HUB_Truck
-- Description: Loads business keys into HUB_Truck
-- Example:		Exec [dv].[Load_HUB_Truck] 123, 'Fastway'  (40871100 rows in 19 mins)
-- History:
--	25/10/2018  P. Waldron		Routine Written
-- ==========================================================================================

CREATE OR REPLACE PROCEDURE `dv.Load_HUB_Truck`(
    IN p_ProcessID INT64,
    IN p_RecordSource STRING
)
BEGIN
    -- Standard variables for load tracking and logging
    DECLARE v_Loaded TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Component STRING DEFAULT 'dv.Load_HUB_Truck';
    DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;

    BEGIN
        -- A MERGE statement efficiently handles the "Insert if Not Exists" Hub load pattern,
        -- replacing the CTE, LEFT JOIN, and INSERT approach from SQL Server.
        MERGE INTO `dv.HUB_Truck` AS Dest
        USING (
            SELECT DISTINCT Container AS TruckNum
            FROM `Staging.BBA_ContainerMaster_Stg`
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
                -- Assuming GetHashKey is migrated as a BigQuery UDF. 
                -- T-SQL 'default' keyword parameter is omitted as BigQuery UDFs don't use it this way.
                `dbo.GetHashKey`(Src.TruckNum),
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
    CALL `Staging.SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,
        CURRENT_TIMESTAMP(),
        v_Result,
        v_ErrorMessage,
        v_Inserted,
        v_Updated,
        -1
    );
END;