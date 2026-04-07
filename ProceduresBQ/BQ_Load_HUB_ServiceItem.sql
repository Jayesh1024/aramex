-- ==========================================================================================
-- Routine:		Load_HUB_Product
-- Description: Loads business keys into HUB_Product
-- Example:		Exec [dv].[Load_HUB_ServiceItem] 657, 'Fastway'  
-- History:
--	16/09/2020  P. Waldron		Routine Written
--	01/09/2021  P. Waldron		Add HSK column on Staging table select to improve performance
-- ==========================================================================================

CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_HUB_ServiceItem`(
    IN p_ProcessID INT64,
    IN p_RecordSource STRING
)
BEGIN
    DECLARE v_Loaded TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Component STRING DEFAULT 'dv_Load_HUB_ServiceItem';
    DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;

    BEGIN
        -- A MERGE statement handles the load pattern using Jinja2 templates for all identifiers.
        -- p_RecordSource remains a dynamic input parameter as requested.
        MERGE INTO `{{ project_id }}.{{ target_dataset_id }}.dv_HUB_ServiceItem` AS dest
        USING (
            SELECT DISTINCT 
                -- Assuming GetHashKey is migrated as a BigQuery UDF within the target project/dataset
                `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(
                    CONCAT(cty.CountryName, '^', IF(IFNULL(si.DisplayText, '') != '', si.DisplayText, si.Description))
                ) AS ServiceItem_HSK,
                cty.CountryName AS Country, 
                IF(IFNULL(si.DisplayText, '') != '', si.DisplayText, si.Description) AS ServiceItem,
                si.ServiceItemId
            FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_fl_ServiceItem_Stg` AS si
            JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` AS cty 
                ON cty.CountryCode = si.CountryId
        ) AS stg
        ON dest.ServiceItem_HSK = stg.ServiceItem_HSK
        WHEN NOT MATCHED THEN
            INSERT (
                ServiceItem_HSK,
                Country,
                ServiceItem,
                Loaded,
                ProcessID,
                RecordSource,
                RecordSourceId
            )
            VALUES (
                stg.ServiceItem_HSK,
                stg.Country,
                stg.ServiceItem,
                v_Loaded,
                p_ProcessID,
                p_RecordSource,
                stg.ServiceItemId
            );

        -- Capture the number of new records inserted
        SET v_Inserted = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Final Log Call (Handles both Success and Failure metrics)
    CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
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