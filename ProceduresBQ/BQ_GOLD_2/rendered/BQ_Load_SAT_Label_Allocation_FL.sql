-- ==========================================================================================
-- Routine:		Load_SAT_Label_Allocation_FL
-- Description: Loads attributes into SAT_Label_Allocation_FL from Staging.tblFastLabel_Consignment_stg
-- Example:		Exec [dv].[Load_SAT_Label_Allocation_FL] 174  
-- History:
--	25/07/2019  P. Waldron		Routine Written
-- ==========================================================================================

CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_SAT_Label_Allocation_FL`(
    IN p_ProcessID INT64,
    IN p_RecordSource STRING
)
OPTIONS(strict_mode=false)
BEGIN
    -- 1. All DECLARE statements must be at the very top
    DECLARE v_Component STRING DEFAULT 'dv_Load_SAT_Label_Allocation_FL';
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;
    
    DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_DefaultValidFrom DATETIME DEFAULT DATETIME '1900-01-01';
    DECLARE v_DefaultValidTo DATETIME DEFAULT DATETIME '9999-12-31';

    BEGIN
        -- STEP 1: Identify and Expire current records that have changed attributes
        UPDATE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_FL` AS Tgt
        SET 
            IsCurrent = 0, 
            ValidTo = v_Loaded
        FROM (
            SELECT 
                `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(Stg.LabelNumber, '^') AS LabelNo_HSK,
                Stg.LabelNumber,
                Stg.CountryCode,
                IFNULL(cty.CountryName, 'Unknown') AS Country,
                Stg.LabelPrinted, Stg.CustomerID, Stg.ClientID, Stg.ConsumedByCustomerUserID,
                Stg.LblColour, Stg.LblPrice, Stg.LblPrice1, Stg.Reference, Stg.Packaging,
                Stg.Weight, Stg.WeightCubic, Stg.Length, Stg.Width, Stg.Height,
                Stg.ManifestID, Stg.Town, Stg.PostCode, Stg.destRF, Stg.CreateDate, Stg.ConsignmentID
            FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_tblFastLabel_Consignment_Stg` AS Stg
            LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Country` AS cty ON cty.CountryCode = Stg.CountryCode
        ) AS Src
        WHERE Tgt.LabelNo_HSK = Src.LabelNo_HSK 
          AND Tgt.IsCurrent = 1 
          AND (
                -- FIX: Explicitly cast all STRING IDs and use '-1' string fallback
                IFNULL(Tgt.LabelNo, '') != IFNULL(Src.LabelNumber, '') OR
                IFNULL(CAST(Tgt.CountryCode AS STRING), '') != IFNULL(CAST(Src.CountryCode AS STRING), '') OR
                IFNULL(Tgt.Country, '') != IFNULL(Src.Country, '') OR
                IFNULL(Tgt.LabelPrinted, DATETIME '1900-01-01') != IFNULL(Src.LabelPrinted, DATETIME '1900-01-01') OR
                IFNULL(CAST(Tgt.CustomerID AS STRING), '-1') != IFNULL(CAST(Src.CustomerID AS STRING), '-1') OR
                IFNULL(CAST(Tgt.ClientID AS STRING), '-1') != IFNULL(CAST(Src.ClientID AS STRING), '-1') OR
                IFNULL(CAST(Tgt.ConsumedByCustomerUserID AS STRING), '-1') != IFNULL(CAST(Src.ConsumedByCustomerUserID AS STRING), '-1') OR
                IFNULL(Tgt.LblColour, 'NULL') != IFNULL(Src.LblColour, 'NULL') OR
                IFNULL(CAST(Tgt.LblPrice AS FLOAT64), 0.0) != IFNULL(CAST(Src.LblPrice AS FLOAT64), 0.0) OR
                IFNULL(CAST(Tgt.LblPrice1 AS FLOAT64), 0.0) != IFNULL(CAST(Src.LblPrice1 AS FLOAT64), 0.0) OR
                IFNULL(Tgt.Reference, 'NULL') != IFNULL(Src.Reference, 'NULL') OR
                IFNULL(Tgt.Packaging, 'NULL') != IFNULL(Src.Packaging, 'NULL') OR
                IFNULL(CAST(Tgt.Weight AS FLOAT64), 0.0) != IFNULL(CAST(Src.Weight AS FLOAT64), 0.0) OR
                IFNULL(CAST(Tgt.WeightCubic AS FLOAT64), 0.0) != IFNULL(CAST(Src.WeightCubic AS FLOAT64), 0.0) OR
                IFNULL(CAST(Tgt.Length AS FLOAT64), 0.0) != IFNULL(CAST(Src.Length AS FLOAT64), 0.0) OR
                IFNULL(CAST(Tgt.Width AS FLOAT64), 0.0) != IFNULL(CAST(Src.Width AS FLOAT64), 0.0) OR
                IFNULL(CAST(Tgt.Height AS FLOAT64), 0.0) != IFNULL(CAST(Src.Height AS FLOAT64), 0.0) OR
                IFNULL(CAST(Tgt.ManifestID AS STRING), '-1') != IFNULL(CAST(Src.ManifestID AS STRING), '-1') OR
                IFNULL(Tgt.Town, 'NULL') != IFNULL(Src.Town, 'NULL') OR
                IFNULL(Tgt.PostCode, 'NULL') != IFNULL(Src.PostCode, 'NULL') OR
                IFNULL(Tgt.destRF, 'NULL') != IFNULL(Src.destRF, 'NULL') OR
                IFNULL(Tgt.CreateDate, DATETIME '1900-01-01') != IFNULL(Src.CreateDate, DATETIME '1900-01-01') OR
                IFNULL(CAST(Tgt.ConsignmentID AS STRING), '-1') != IFNULL(CAST(Src.ConsignmentID AS STRING), '-1')
          );

        SET v_Updated = @@row_count;

        -- STEP 2: Insert New Records
        INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_FL` (
            LabelNo_HSK, LabelNo, CountryCode, Country, LabelPrinted, CustomerID, 
            ClientID, ConsumedByCustomerUserID, LblColour, LblPrice, LblPrice1, 
            Reference, Packaging, Weight, WeightCubic, Length, Width, Height, 
            ManifestID, Town, PostCode, destRF, CreateDate, ConsignmentID,
            Loaded, ProcessId, RecordSource, RecordSourceId, ValidFrom, ValidTo, IsCurrent
        )
        SELECT
            `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(Src.LabelNumber, '^'),
            Src.LabelNumber, Src.CountryCode, Src.Country, Src.LabelPrinted, Src.CustomerID, 
            Src.ClientID, Src.ConsumedByCustomerUserID, Src.LblColour, Src.LblPrice, Src.LblPrice1, 
            Src.Reference, Src.Packaging, Src.Weight, Src.WeightCubic, Src.Length, Src.Width, Src.Height, 
            Src.ManifestID, Src.Town, Src.PostCode, Src.destRF, Src.CreateDate, Src.ConsignmentID,
            v_Loaded, p_ProcessID, p_RecordSource, Src.BookID,
            IF(Src.IsNewKey, v_DefaultValidFrom, v_Loaded),
            v_DefaultValidTo,
            1 
        FROM (
            SELECT 
                Stg.*,
                IFNULL(cty.CountryName, 'Unknown') AS Country,
                CASE WHEN Sat.LabelNo_HSK IS NULL THEN TRUE ELSE FALSE END AS IsNewKey,
                CASE 
                    WHEN Sat.LabelNo_HSK IS NULL THEN TRUE 
                    WHEN Sat.IsCurrent = 0 AND Sat.ValidTo = v_Loaded THEN TRUE 
                    ELSE FALSE 
                END AS ShouldInsert
            FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_tblFastLabel_Consignment_Stg` AS Stg
            LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Country` AS cty ON cty.CountryCode = Stg.CountryCode
            LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_FL` AS Sat 
                ON Sat.LabelNo = Stg.LabelNumber 
                AND Sat.CountryCode = Stg.CountryCode
                AND Sat.IsCurrent = 1 
        ) AS Src
        WHERE Src.ShouldInsert = TRUE;

        SET v_Inserted = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Final Log Call
    CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
        v_Component, p_ProcessID, v_Started, CURRENT_DATETIME(), v_Result, v_ErrorMessage, v_Inserted, v_Updated, -1
    );
END;