{#-- ==========================================================================================
Routine:		dv_Load_SAT_FL_Zones
Description: 	Loads business keys into HUB_RF
History:
	06/09/2024  B. Woods		Routine Written
========================================================================================== --#}

CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_SAT_FL_Zones`(
    IN p_ProcessID INT64,
    IN p_RecordSource STRING
)
BEGIN
    -- Logging Variables
    DECLARE v_Component STRING DEFAULT '{{ project_id }}.{{ target_dataset_id }}.dv_Load_SAT_FL_Zones';
    
    -- OPTION 2: Changed from TIMESTAMP to DATETIME
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;

    -- Initialize to 0 for logging safety
    DECLARE v_Updated INT64 DEFAULT 0; 
    DECLARE v_Step STRING;
    DECLARE v_delim STRING DEFAULT '\r'; -- Carriage Return

    -- Working Variables
    DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();

    BEGIN
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_FL_Zones` (
            Zone_HSK,
            CountryId,
            ZoneCode,
            Description,
            Type,
            DomOrInt,
            Loaded,
            RecordSource
        )
        SELECT
            -- Call UDF: dbo.GetHashKey -> dbo_GetHashKey
            `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(
                CONCAT(
                    IFNULL(NULLIF(CAST(CountryId AS STRING), ''), '') || v_delim,
                    IFNULL(NULLIF(CAST(ZoneCode AS STRING), ''), '') || v_delim
                ), '^'
            ) AS ZoneKey,
            CountryId,
            ZoneCode,
            Description,
            Type,
            DomOrInt,
            v_Loaded AS Loaded,
            p_RecordSource AS RecordSource
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_fl_Zones_Stg`;
        
        SET v_Inserted = @@row_count;
        SET v_Result = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Record load metrics in log (Option 2: Using DATETIME and CURRENT_DATETIME)
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