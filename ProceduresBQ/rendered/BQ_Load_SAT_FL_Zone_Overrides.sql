			 
-- ==========================================================================================
-- Routine:		Load_HUB_RF
-- Description: Loads business keys into HUB_RF
-- Example:		Exec [DV].[Load_SAT_FL_Zone_Overrides] 123, 'Fastway_PriceOverrides'  
-- History:
--	06/09/2024  B. Woods		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `searce-sandbox-da-delivery.Aramex_oceania_SP.dv_Load_SAT_FL_Zone_Overrides`(
    IN p_ProcessID INT64
)
OPTIONS(strict_mode=false)
BEGIN
    -- 1. All DECLARE statements must be at the very top
    DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Component STRING DEFAULT 'dv_Load_SAT_FL_Zone_Overrides';
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;
    
    -- Static RecordSource as per original T-SQL default logic
    DECLARE v_RecordSource STRING DEFAULT '';
    
    DECLARE v_Step STRING;
    DECLARE v_delim STRING DEFAULT CHR(13); -- Carriage Return

    -- Handle Default p_ProcessID
    IF p_ProcessID IS NULL THEN
        SET p_ProcessID = -37;
    END IF;

    BEGIN
        -- Insert with UNION DISTINCT to match T-SQL's implicit distinct UNION
        -- All table and function identifiers use Jinja2 templates and underscore schema naming.
        INSERT INTO `searce-sandbox-da-delivery.Aramex_oceania.dv_SAT_FL_ServiceZoneOverride`
        SELECT
            `searce-sandbox-da-delivery.Aramex_oceania.dbo_GetHashKey`(
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
            v_RecordSource
        FROM `searce-sandbox-da-delivery.Aramex_oceania.Staging_fl_ServiceZoneSatchelOverride_Stg`
        
        UNION DISTINCT
        
        SELECT
            `searce-sandbox-da-delivery.Aramex_oceania.dbo_GetHashKey`(
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
            v_RecordSource
        FROM `searce-sandbox-da-delivery.Aramex_oceania.Staging_fl_ServiceZoneWeightOverride_Stg`;	 
        
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