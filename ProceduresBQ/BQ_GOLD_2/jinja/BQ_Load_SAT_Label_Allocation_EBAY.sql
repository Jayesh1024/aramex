-- ==========================================================================================
-- Routine:		Load_SAT_Label_Allocation_EBAY
-- Description: Loads attributes into Load_SAT_Label_Allocation_EBAY from [Staging].[Ebay_Labels_Stg] 
-- Example:		Exec [dv].[Load_SAT_Label_Allocation_EBAY] 123 
-- History:
--	06/11/2019  P. Waldron		Routine Written
-- ==========================================================================================

CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_SAT_Label_Allocation_EBAY`(
    IN p_ProcessID INT64
)
OPTIONS(strict_mode=false)
BEGIN
    -- 1. All DECLARE statements must be at the very top
    DECLARE v_Component STRING DEFAULT 'dv_Load_SAT_Label_Allocation_EBAY';
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;
    
    DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
    -- FIX: Changed these to DATETIME to match your table schema
    DECLARE v_DefaultValidFrom DATETIME DEFAULT DATETIME '1900-01-01';
    DECLARE v_DefaultValidTo DATETIME DEFAULT DATETIME '9999-12-31';

    -- Static RecordSource
    DECLARE v_RecordSource STRING DEFAULT 'EBAY';

    BEGIN
        -- Step 1: Identify and Expire existing records that have changed
        UPDATE `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_EBAY` AS Tgt
        SET 
            IsCurrent = 0, 
            ValidTo = v_Loaded -- Both are now DATETIME
        FROM (
            SELECT 
                `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(Stg.LabelNumber, '^') AS LabelNo_HSK,
                IFNULL(cty.CountryName, 'Unknown') AS Country,
                Stg.B_CountryCode AS CountryCode,
                Stg.B_RF AS OriginRF,
                Stg.DeliveryRF AS DestinationRF,
                Stg.CreatedDateUTC AS CreateDateUTC,
                Stg.LabelColour,
                Stg.TotalLabelCost AS LabelCost
            FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Ebay_Labels_Stg` AS Stg
            LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` AS cty ON cty.CountryCode = Stg.B_CountryCode
            WHERE Stg.LabelNumber IS NOT NULL AND Stg.LabelNumber != ''
        ) AS Src
        WHERE Tgt.LabelNo_HSK = Src.LabelNo_HSK 
          AND Tgt.IsCurrent = 1 
          AND (
                -- Using DATETIME literals for comparison consistency
                IFNULL(Tgt.Country, '') != IFNULL(Src.Country, '') OR
                IFNULL(CAST(Tgt.CountryCode AS STRING), '') != IFNULL(CAST(Src.CountryCode AS STRING), '') OR 
                IFNULL(Tgt.OriginRF, '') != IFNULL(Src.OriginRF, '') OR
                IFNULL(Tgt.DestinationRF, '') != IFNULL(Src.DestinationRF, '') OR
                IFNULL(Tgt.CreateDateUTC, DATETIME '1900-01-01') != IFNULL(Src.CreateDateUTC, DATETIME '1900-01-01') OR
                IFNULL(Tgt.LabelColour, '') != IFNULL(Src.LabelColour, '') OR
                IFNULL(CAST(Tgt.LabelCost AS FLOAT64), 0.0) != IFNULL(CAST(Src.LabelCost AS FLOAT64), 0.0)
          );

        SET v_Updated = @@row_count;

        -- Step 2: Insert New Records
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_EBAY` (
            LabelNo_HSK, LabelNo, Country, CountryCode, OriginRF, DestinationRF,
            CreateDateUTC, LabelColour, LabelCost, Loaded, ProcessId,
            RecordSource, RecordSourceId, ValidFrom, ValidTo, IsCurrent
        )
        SELECT
            `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(Src.LabelNo, '^'),
            Src.LabelNo,
            Src.Country,
            Src.CountryCode,
            Src.OriginRF,
            Src.DestinationRF,
            Src.CreateDateUTC,
            Src.LabelColour,
            Src.LabelCost,
            v_Loaded, -- DATETIME
            p_ProcessID,
            v_RecordSource,
            Src.ID,
            IF(Src.IsNewKey, v_DefaultValidFrom, v_Loaded),
            v_DefaultValidTo,
            1 
        FROM (
            SELECT 
                Stg.LabelNumber AS LabelNo,
                IFNULL(cty.CountryName, 'Unknown') AS Country,
                Stg.B_CountryCode AS CountryCode,
                Stg.B_RF AS OriginRF,
                Stg.DeliveryRF AS DestinationRF,
                Stg.CreatedDateUTC AS CreateDateUTC,
                Stg.LabelColour,
                Stg.TotalLabelCost AS LabelCost,
                Stg.ID,
                CASE 
                    WHEN Sat.LabelNo_HSK IS NULL THEN TRUE 
                    WHEN Sat.IsCurrent = 0 AND Sat.ValidTo = v_Loaded THEN TRUE 
                    ELSE FALSE 
                END AS ShouldInsert,
                CASE WHEN Sat.LabelNo_HSK IS NULL THEN TRUE ELSE FALSE END AS IsNewKey
            FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Ebay_Labels_Stg` AS Stg
            LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` AS cty ON cty.CountryCode = Stg.B_CountryCode
            LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_EBAY` AS Sat 
                ON Sat.LabelNo = Stg.LabelNumber AND Sat.IsCurrent = 1 
            WHERE Stg.LabelNumber IS NOT NULL AND Stg.LabelNumber != ''
        ) AS Src
        WHERE Src.ShouldInsert = TRUE;

        SET v_Inserted = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Final Log Call
    CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
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