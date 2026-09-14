-- ==========================================================================================
-- Routine:		Load_Dim_Time
-- Description: Loads dates for the given year into the Dim_Time table. 
-- Proc will not not add any new dates if the year already exists in the table.
-- Example:		Exec [dbo].[Load_Dim_Label] 2024
-- Example:		Exec [dbo].[Load_Dim_Label] 2024, 1 -- To remove existing data

CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_Load_Dim_Time`(
    IN p_ProcessID INT64, 
    IN p_Year INT64,
    IN p_RemoveExisting BOOL
)
OPTIONS(strict_mode=false)
BEGIN
    DECLARE v_Component STRING DEFAULT 'dbo_Load_Dim_Time';
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
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
            DELETE FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Time` WHERE cal_year = p_Year;
        END IF;

        -- Check if data already exists to avoid duplication
        SET v_AlreadyExists = (SELECT COUNT(1) > 0 FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Time` WHERE cal_year = p_Year);

        IF v_AlreadyExists THEN
            SET v_Result = 'Skipped - Already Exists';
        ELSE
            -- Insert block with explicit CASTs to INT64 where necessary
            INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Time` (
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
                CAST(FORMAT_DATE('%Y%m%d', NextDate) AS INT64),               -- Cast STRING to INT64
                CAST(NextDate AS DATETIME),
                SUBSTR(FORMAT_DATE('%A', NextDate), 1, 3),
                EXTRACT(DAYOFWEEK FROM NextDate),
                EXTRACT(DAY FROM NextDate),
                EXTRACT(DAYOFYEAR FROM NextDate),
                EXTRACT(WEEK FROM NextDate),
                EXTRACT(MONTH FROM NextDate),
                CAST(FORMAT_DATE('%Y%m', NextDate) AS INT64),                 -- Cast YYYYMM to INT64
                FORMAT_DATE('%b', NextDate),
                EXTRACT(QUARTER FROM NextDate),
                CAST(CONCAT(CAST(p_Year AS STRING), '0', CAST(EXTRACT(QUARTER FROM NextDate) AS STRING)) AS INT64), -- Cast Quarter ID to INT64
                EXTRACT(YEAR FROM NextDate),
                IF(EXTRACT(DAYOFWEEK FROM NextDate) IN (1, 7), 'N', 'Y'),
                IF(EXTRACT(DAYOFWEEK FROM NextDate) IN (1, 7), 'Y', 'N')
            FROM UNNEST(GENERATE_DATE_ARRAY(v_StartDate, v_EndDate)) AS NextDate;

            SET v_Inserted = @@row_count;
        END IF;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Final Log Call
    CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
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