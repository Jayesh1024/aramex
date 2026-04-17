-- ==========================================================================================
-- Routine:		Load_HUB_ScanStatus
-- Description: Loads business keys into HUB_ScanStatus
-- Example:		Exec [dv].[Load_HUB_ScanStatus] 10, 'Fastway'  
-- History:
--	13/11/2018  P. Waldron		Routine Written
-- ==========================================================================================

CREATE OR REPLACE PROCEDURE `searce-sandbox-da-delivery.Aramex_oceania_SP.dv_Load_HUB_ScanStatus`(
    IN p_ProcessID INT64,
    IN p_RecordSource STRING
)
OPTIONS(strict_mode=false)
BEGIN
    DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Component STRING DEFAULT 'dv_Load_HUB_ScanStatus';
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;

    BEGIN
        -- A MERGE statement handles the "Insert if Not Exists" logic using Jinja2 templates for paths.
        MERGE INTO `searce-sandbox-da-delivery.Aramex_oceania.dv_HUB_ScanStatus` AS Dest
        USING (
            SELECT DISTINCT 
                IFNULL(RTRIM(CountryName), 'Unknown') AS CountryName, 
                StatusCode AS ScanStatus 
            FROM `searce-sandbox-da-delivery.Aramex_oceania.Staging_ScanStatus_Stg`
        ) AS Src
        ON Dest.CountryName = Src.CountryName 
           AND Dest.ScanStatus = Src.ScanStatus
        WHEN NOT MATCHED THEN
            INSERT (
                ScanStatus_HSK,
                CountryName,
                ScanStatus,
                Loaded,
                ProcessID,
                RecordSource
            )
            VALUES (
                -- UDF reference converted to Jinja2 path format
                `searce-sandbox-da-delivery.Aramex_oceania.dbo_GetHashKey`(CONCAT(Src.CountryName, '^', Src.ScanStatus)),
                Src.CountryName,
                Src.ScanStatus,
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
    CALL `searce-sandbox-da-delivery.Aramex_oceania_SP.Staging_SaveLog`(
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