-- ==========================================================================================
-- Routine:		Load_Dim_Time
-- Description: Loads dates for the given year into the Dim_Time table. 
-- Proc will not not add any new dates if the year already exists in the table.
-- Example:		Exec [dbo].[Load_Dim_Label] 2024
-- Example:		Exec [dbo].[Load_Dim_Label] 2024, 1 -- To remove existing data

CREATE OR REPLACE PROCEDURE `dbo.Load_Dim_Time`(
    IN p_ProcessID INT64, 
    IN p_Year INT64,
    IN p_RemoveExisting BOOL
)
BEGIN
    DECLARE v_Component STRING DEFAULT 'dbo.Load_Dim_Time';
    DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;
    
    DECLARE v_StartDate DATE;
    DECLARE v_EndDate DATE;
    DECLARE v_AlreadyExists BOOL DEFAULT FALSE;

    BEGIN
        -- Set boundaries for BigQuery's native date generator
        SET v_StartDate = DATE(p_Year, 1, 1);
        SET v_EndDate = DATE(p_Year, 12, 31);

        -- Remove existing data if requested
        IF IFNULL(p_RemoveExisting, FALSE) THEN
            DELETE FROM `dbo.Dim_Time` WHERE cal_year = p_Year;
        END IF;

        -- Check if data already exists to avoid duplication
        SET v_AlreadyExists = (SELECT COUNT(1) > 0 FROM `dbo.Dim_Time` WHERE cal_year = p_Year);

        IF v_AlreadyExists THEN
            SET v_Result = 'Skipped - Already Exists';
        ELSE
            -- BigQuery's UNNEST(GENERATE_DATE_ARRAY) entirely replaces the need for recursive CTEs
            INSERT INTO `dbo.Dim_Time` (
                Date_Key,
                Calendar_Date,
                cal_day_in_week,
                cal_day_in_week_no,
                cal_day_in_month,
                cal_day_in_year,
                cal_week_in_year,
                cal_month_no,
                cal_month,
                cal_month_name,
                cal_quarter_no,
                cal_quarter,
                cal_year,
                week_day_flag,
                week_end_flag
            )
            SELECT
                FORMAT_DATE('%Y%m%d', NextDate),
                CAST(NextDate AS TIMESTAMP),                                                  -- DATETIME to TIMESTAMP mapping
                SUBSTR(FORMAT_DATE('%A', NextDate), 1, 3),                                    -- Left 3 characters of day name
                EXTRACT(DAYOFWEEK FROM NextDate),                                             -- Sunday = 1, Saturday = 7
                EXTRACT(DAY FROM NextDate),
                EXTRACT(DAYOFYEAR FROM NextDate),
                EXTRACT(WEEK FROM NextDate),
                EXTRACT(MONTH FROM NextDate),
                FORMAT_DATE('%Y%m', NextDate),                                                -- Equivalent to YYYYMM
                FORMAT_DATE('%b', NextDate),                                                  -- Equivalent to Left 3 Month Name
                EXTRACT(QUARTER FROM NextDate),
                CONCAT(CAST(p_Year AS STRING), '0', CAST(EXTRACT(QUARTER FROM NextDate) AS STRING)), -- e.g., 202301
                EXTRACT(YEAR FROM NextDate),
                IF(EXTRACT(DAYOFWEEK FROM NextDate) IN (1, 7), 'N', 'Y'),                     -- weekday flag
                IF(EXTRACT(DAYOFWEEK FROM NextDate) IN (1, 7), 'Y', 'N')                      -- weekend flag
            FROM UNNEST(GENERATE_DATE_ARRAY(v_StartDate, v_EndDate)) AS NextDate;

            SET v_Inserted = @@row_count;
        END IF;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Final Log Call (Handles Success, Skipped, and Failure metrics)
    -- Added p_ProcessID dependency to comply with constraints and log metadata standards
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