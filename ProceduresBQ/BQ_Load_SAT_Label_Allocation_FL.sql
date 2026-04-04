-- ==========================================================================================
-- Routine:		Load_SAT_Label_Allocation_FL
-- Description: Loads attributes into SAT_Label_Allocation_FL from Staging.tblFastLabel_Consignment_stg
-- Example:		Exec [dv].[Load_SAT_Label_Allocation_FL] 174  
-- History:
--	25/07/2019  P. Waldron		Routine Written
-- ==========================================================================================

CREATE OR REPLACE PROCEDURE `dv.Load_SAT_Label_Allocation_FL`(
    IN p_ProcessID INT64,
    IN p_RecordSource STRING
)
BEGIN
    -- DECLARE statements must be at the very top of the BEGIN...END block
    DECLARE v_Component STRING DEFAULT 'dv.Load_SAT_Label_Allocation_FL';
    DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;
    
    DECLARE v_Loaded TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_DefaultValidFrom TIMESTAMP DEFAULT TIMESTAMP('1900-01-01');
    DECLARE v_DefaultValidTo TIMESTAMP DEFAULT TIMESTAMP('9999-12-31');

    -- Handle default parameter value
    SET p_RecordSource = IFNULL(p_RecordSource, 'FastLabel');

    BEGIN
        -- STEP 1: Expire current records that have changed attributes
        -- BigQuery does not support INSERT FROM MERGE OUTPUT, so we split SCD Type 2 logic
        -- into an UPDATE to expire old versions and an INSERT for new versions.
        UPDATE `dv.SAT_Label_Allocation_FL` AS Tgt
        SET 
            IsCurrent = FALSE,
            ValidTo = v_Loaded
        FROM (
            SELECT 
                `dbo.GetHashKey`(Stg.LabelNumber) AS LabelNo_HSK,
                Stg.LabelNumber,
                Stg.CountryCode,
                IFNULL(cty.CountryName, 'Unknown') AS Country,
                Stg.LabelPrinted, Stg.CustomerID, Stg.ClientID, Stg.ConsumedByCustomerUserID,
                Stg.LblColour, Stg.LblPrice, Stg.LblPrice1, Stg.Reference, Stg.Packaging,
                Stg.Weight, Stg.WeightCubic, Stg.Length, Stg.Width, Stg.Height,
                Stg.ManifestID, Stg.Town, Stg.PostCode, Stg.destRF, Stg.CreateDate, Stg.ConsignmentID
            FROM `Staging.tblFastLabel_Consignment_stg` AS Stg
            LEFT JOIN `dbo.Dim_Country` AS cty ON cty.CountryCode = Stg.CountryCode
        ) AS Src
        WHERE Tgt.LabelNo_HSK = Src.LabelNo_HSK 
          AND Tgt.IsCurrent = TRUE
          AND (
                -- Logic equivalent to T-SQL EXCEPT (Detecting changes in any non-key attribute)
                Tgt.LabelNo != Src.LabelNumber OR
                Tgt.CountryCode != Src.CountryCode OR
                Tgt.Country != Src.Country OR
                IFNULL(Tgt.LabelPrinted, 'NULL') != IFNULL(Src.LabelPrinted, 'NULL') OR
                IFNULL(Tgt.CustomerID, -1) != IFNULL(Src.CustomerID, -1) OR
                IFNULL(Tgt.ClientID, -1) != IFNULL(Src.ClientID, -1) OR
                IFNULL(Tgt.ConsumedByCustomerUserID, -1) != IFNULL(Src.ConsumedByCustomerUserID, -1) OR
                IFNULL(Tgt.LblColour, 'NULL') != IFNULL(Src.LblColour, 'NULL') OR
                IFNULL(Tgt.LblPrice, 0) != IFNULL(Src.LblPrice, 0) OR
                IFNULL(Tgt.LblPrice1, 0) != IFNULL(Src.LblPrice1, 0) OR
                IFNULL(Tgt.Reference, 'NULL') != IFNULL(Src.Reference, 'NULL') OR
                IFNULL(Tgt.Packaging, 'NULL') != IFNULL(Src.Packaging, 'NULL') OR
                IFNULL(Tgt.Weight, 0) != IFNULL(Src.Weight, 0) OR
                IFNULL(Tgt.WeightCubic, 0) != IFNULL(Src.WeightCubic, 0) OR
                IFNULL(Tgt.Length, 0) != IFNULL(Src.Length, 0) OR
                IFNULL(Tgt.Width, 0) != IFNULL(Src.Width, 0) OR
                IFNULL(Tgt.Height, 0) != IFNULL(Src.Height, 0) OR
                IFNULL(Tgt.ManifestID, -1) != IFNULL(Src.ManifestID, -1) OR
                IFNULL(Tgt.Town, 'NULL') != IFNULL(Src.Town, 'NULL') OR
                IFNULL(Tgt.PostCode, 'NULL') != IFNULL(Src.PostCode, 'NULL') OR
                IFNULL(Tgt.destRF, 'NULL') != IFNULL(Src.destRF, 'NULL') OR
                IFNULL(Tgt.CreateDate, TIMESTAMP('1900-01-01')) != IFNULL(Src.CreateDate, TIMESTAMP('1900-01-01')) OR
                IFNULL(Tgt.ConsignmentID, -1) != IFNULL(Src.ConsignmentID, -1)
          );

        SET v_Updated = @@row_count;

        -- STEP 2: Insert New Records
        -- This includes brand new keys and the new versions of the expired records above.
        INSERT INTO `dv.SAT_Label_Allocation_FL` (
            LabelNo_HSK, LabelNo, CountryCode, Country, LabelPrinted, CustomerID, 
            ClientID, ConsumedByCustomerUserID, LblColour, LblPrice, LblPrice1, 
            Reference, Packaging, Weight, WeightCubic, Length, Width, Height, 
            ManifestID, Town, PostCode, destRF, CreateDate, ConsignmentID,
            Loaded, ProcessId, RecordSource, RecordSourceId, ValidFrom, ValidTo, IsCurrent
        )
        SELECT
            `dbo.GetHashKey`(Src.LabelNumber),
            Src.LabelNumber,
            Src.CountryCode,
            Src.Country,
            Src.LabelPrinted,
            Src.CustomerID,
            Src.ClientID,
            Src.ConsumedByCustomerUserID,
            Src.LblColour,
            Src.LblPrice,
            Src.LblPrice1,
            Src.Reference,
            Src.Packaging,
            Src.Weight,
            Src.WeightCubic,
            Src.Length,
            Src.Width,
            Src.Height,
            Src.ManifestID,
            Src.Town,
            Src.PostCode,
            Src.destRF,
            Src.CreateDate,
            Src.ConsignmentID,
            v_Loaded,
            p_ProcessID,
            p_RecordSource,
            Src.BookID,
            IF(Src.IsNewKey, v_DefaultValidFrom, v_Loaded),
            v_DefaultValidTo,
            TRUE
        FROM (
            SELECT 
                Stg.*,
                IFNULL(cty.CountryName, 'Unknown') AS Country,
                CASE WHEN Sat.LabelNo_HSK IS NULL THEN TRUE ELSE FALSE END AS IsNewKey,
                CASE 
                    WHEN Sat.LabelNo_HSK IS NULL THEN TRUE -- New Business Key
                    WHEN Sat.IsCurrent = FALSE AND Sat.ValidTo = v_Loaded THEN TRUE -- Key exists but was just expired
                    ELSE FALSE 
                END AS ShouldInsert
            FROM `Staging.tblFastLabel_Consignment_stg` AS Stg
            LEFT JOIN `dbo.Dim_Country` AS cty ON cty.CountryCode = Stg.CountryCode
            LEFT JOIN `dv.SAT_Label_Allocation_FL` AS Sat 
                ON Sat.LabelNo = Stg.LabelNumber 
                AND Sat.CountryCode = Stg.CountryCode
                AND Sat.IsCurrent = TRUE
        ) AS Src
        WHERE Src.ShouldInsert = TRUE;

        SET v_Inserted = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Final Log Call (Handles both Success and Failure)
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