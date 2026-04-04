			 
-- ==========================================================================================
-- Routine:		Load_HUB_RF
-- Description: Loads business keys into HUB_RF
-- Example:		Exec [DV].[Load_SAT_FL_Zone_Overrides] 123, 'Fastway_PriceOverrides'  
-- History:
--	06/09/2024  B. Woods		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `dv.Load_SAT_FL_Zone_Overrides`(
    IN p_ProcessID INT64,
    IN p_RecordSource STRING
)
BEGIN
    -- 1. All DECLARE statements must be at the very top
    DECLARE v_Loaded TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Component STRING DEFAULT 'dv.Load_SAT_FL_Zone_Overrides';
    DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;
    
    DECLARE v_Step STRING;
    -- CHR(13) is the BigQuery equivalent of nchar(13) (Carriage Return)
    DECLARE v_delim STRING DEFAULT CHR(13);

    -- Handle Default Parameters from T-SQL Signature
    IF p_ProcessID IS NULL THEN
        SET p_ProcessID = -37;
    END IF;
    IF p_RecordSource IS NULL THEN
        SET p_RecordSource = '';
    END IF;

    BEGIN
        -- Insert with UNION DISTINCT to match T-SQL's implicit distinct UNION
        -- T-SQL CONCAT ignores NULLs. The pattern NULLIF(...)+@delim turns into NULL 
        -- when empty, causing T-SQL CONCAT to skip it. 
        -- BigQuery's CONCAT yields NULL if *any* argument is NULL. 
        -- To perfectly replicate the T-SQL logic, we wrap the segments in IFNULL(..., '').
        INSERT INTO `dv.SAT_FL_ServiceZoneOverride`
        SELECT
            `dbo.GetHashKey`(
                CONCAT(
                    'Satchel', v_delim,
                    IFNULL(CONCAT(NULLIF(CAST(OverrideId AS STRING), ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(CAST(ServiceItemId AS STRING), ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(Zone, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(SatchelSize, ''), v_delim), '')
                )
            ) AS ZoneOverrides_HSK,
            'Satchel' AS OverrideType,
            OverrideId,
            ServiceItemId,
            Zone,
            SatchelSize,
            0 AS FromWeight,
            0 AS ToWeight,
            PickupAmount,
            ServiceCommission,
            ServiceAmount,
            FixedOrPercentage,
            UpdatedOn,
            UpdatedBy,
            v_Loaded,
            p_RecordSource
        FROM `Staging.fl_ServiceZoneSatchelOverride_Stg`
        
        UNION DISTINCT
        
        SELECT
            `dbo.GetHashKey`(
                CONCAT(
                    'Weight', v_delim,
                    IFNULL(CONCAT(NULLIF(CAST(OverrideId AS STRING), ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(CAST(ServiceItemId AS STRING), ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(Zone, ''), v_delim), ''),
                    IFNULL(CONCAT(NULLIF(CAST(FromWeight AS STRING), ''), v_delim), '')
                )
            ) AS ZoneOverrides_HSK,
            'Weight' AS OverrideType,
            OverrideId,
            ServiceItemId,
            Zone,
            '' AS SatchelSize,
            FromWeight,
            ToWeight,
            PickupAmount,
            ServiceCommission,
            ServiceAmount,
            FixedOrPercentage,
            UpdatedOn,
            UpdatedBy,
            v_Loaded,
            p_RecordSource
        FROM `Staging.fl_ServiceZoneWeightOverride_Stg`;	 
        
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