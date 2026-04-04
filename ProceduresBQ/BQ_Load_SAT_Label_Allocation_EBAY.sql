-- ==========================================================================================
-- Routine:		Load_SAT_Label_Allocation_EBAY
-- Description: Loads attributes into Load_SAT_Label_Allocation_EBAY from [Staging].[Ebay_Labels_Stg] 
-- Example:		Exec [dv].[Load_SAT_Label_Allocation_EBAY] 123 
-- History:
--	06/11/2019  P. Waldron		Routine Written
-- ==========================================================================================

CREATE OR REPLACE PROCEDURE `dv.Load_SAT_Label_Allocation_EBAY`(
    IN p_ProcessID INT64,
    IN p_RecordSource STRING
)
BEGIN
    -- All DECLARE statements must be at the very top of the BEGIN...END block
    DECLARE v_Component STRING DEFAULT 'dv.Load_SAT_Label_Allocation_EBAY';
    DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;
    
    DECLARE v_Loaded TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_DefaultValidFrom TIMESTAMP DEFAULT TIMESTAMP('1900-01-01');
    DECLARE v_DefaultValidTo TIMESTAMP DEFAULT TIMESTAMP('9999-12-31');

    -- Handle default parameter logic
    SET p_RecordSource = IFNULL(p_RecordSource, 'EBAY');

    BEGIN
        -- Step 1: Identify and Expire existing records that have changed.
        -- BigQuery does not support "INSERT FROM MERGE OUTPUT", so we split the SCD Type 2 logic 
        -- into an UPDATE (to expire) and an INSERT (to create new versions).
        
        -- Expire records where values differ
        UPDATE `dv.SAT_Label_Allocation_EBAY` AS Tgt
        SET 
            IsCurrent = FALSE,
            ValidTo = v_Loaded
        FROM (
            SELECT 
                `dbo.GetHashKey`(Stg.LabelNumber) AS LabelNo_HSK,
                IFNULL(cty.CountryName, 'Unknown') AS Country,
                Stg.B_CountryCode AS CountryCode,
                Stg.B_RF AS OriginRF,
                Stg.DeliveryRF AS DestinationRF,
                Stg.CreatedDateUTC AS CreateDateUTC,
                Stg.LabelColour,
                Stg.TotalLabelCost AS LabelCost
            FROM `Staging.Ebay_Labels_Stg` AS Stg
            LEFT JOIN `dbo.Dim_Country` AS cty ON cty.CountryCode = Stg.B_CountryCode
            WHERE Stg.LabelNumber IS NOT NULL AND Stg.LabelNumber != ''
        ) AS Src
        WHERE Tgt.LabelNo_HSK = Src.LabelNo_HSK 
          AND Tgt.IsCurrent = TRUE
          AND (
                -- Logic equivalent to T-SQL EXCEPT: check for any changes in attributes
                Tgt.Country != Src.Country OR
                Tgt.CountryCode != Src.CountryCode OR
                Tgt.OriginRF != Src.OriginRF OR
                Tgt.DestinationRF != Src.DestinationRF OR
                Tgt.CreateDateUTC != Src.CreateDateUTC OR
                Tgt.LabelColour != Src.LabelColour OR
                Tgt.LabelCost != Src.LabelCost
          );

        SET v_Updated = @@row_count;

        -- Step 2: Insert New Records.
        -- This covers both brand new business keys and the new versions of expired records.
        INSERT INTO `dv.SAT_Label_Allocation_EBAY` (
            LabelNo_HSK, LabelNo, Country, CountryCode, OriginRF, DestinationRF,
            CreateDateUTC, LabelColour, LabelCost, Loaded, ProcessId,
            RecordSource, RecordSourceId, ValidFrom, ValidTo, IsCurrent
        )
        SELECT
            `dbo.GetHashKey`(Src.LabelNo),
            Src.LabelNo,
            Src.Country,
            Src.CountryCode,
            Src.OriginRF,
            Src.DestinationRF,
            Src.CreateDateUTC,
            Src.LabelColour,
            Src.LabelCost,
            v_Loaded,
            p_ProcessID,
            p_RecordSource,
            Src.ID,
            IF(Src.IsNewKey, v_DefaultValidFrom, v_Loaded), -- If brand new key, use Default; if version change, use Loaded
            v_DefaultValidTo,
            TRUE
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
                -- Flag to check if the record needs to be inserted
                CASE 
                    WHEN Sat.LabelNo_HSK IS NULL THEN TRUE -- Brand New Key
                    WHEN Sat.IsCurrent = FALSE AND Sat.ValidTo = v_Loaded THEN TRUE -- Was just expired in the step above
                    ELSE FALSE 
                END AS ShouldInsert,
                CASE WHEN Sat.LabelNo_HSK IS NULL THEN TRUE ELSE FALSE END AS IsNewKey
            FROM `Staging.Ebay_Labels_Stg` AS Stg
            LEFT JOIN `dbo.Dim_Country` AS cty ON cty.CountryCode = Stg.B_CountryCode
            LEFT JOIN `dv.SAT_Label_Allocation_EBAY` AS Sat 
                ON Sat.LabelNo = Stg.LabelNumber AND Sat.IsCurrent = TRUE
            WHERE Stg.LabelNumber IS NOT NULL AND Stg.LabelNumber != ''
        ) AS Src
        WHERE Src.ShouldInsert = TRUE;

        SET v_Inserted = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Final Log Call (Handles Success and Failure metrics)
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