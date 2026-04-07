-- ==========================================================================================
-- Routine:     BQ_Load_LNK_RuralOnforwards
-- Description: Loads relationships into LNK_RuralOnforwards
--              BigQuery compatible version of Load_LNK_RuralOnforwards
-- Example:     CALL dv.BQ_Load_LNK_RuralOnforwards(590)
-- History:
--  17/01/2024  B. Woods        Routine Written
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.BQ_Load_LNK_RuralOnforwards`(
    IN ProcessID INT64
)
BEGIN

    DECLARE Loaded       DATETIME DEFAULT CURRENT_DATETIME();

    DECLARE Component    STRING DEFAULT 'dv.Load_LNK_RuralOnforwards';
    DECLARE Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING;
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64 DEFAULT 0;

    DECLARE NextDate     DATE;

    BEGIN

        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_LNK_RuralOnforwards`
        (
            OnForwards_HSK,
            LabelNo_HSK,
            FranchiseeCode_HSK,
            Courier_HSK,
            CountryCode,
            RF,
            CF,
            LabelNo,
            CreatedDate,
            Onforwards,
            CountryName,
            FileId,
            Loaded,
            ProcessId,
            RecordSource
        )
        SELECT
            -- Replicate dbo.GetHashKey composite key
            TO_HEX(MD5(
                Src.RF || '^'
                || Src.CF || '^'
                || Src.LabelNo || '^'
                || FORMAT_DATETIME('%Y-%m-%dT%H:%M:%E3S', DATETIME(Src.Date + Src.Time))
            ))                                                           AS OnForwards_HSK,
            TO_HEX(MD5(Src.RF))                                         AS FranchiseeCode_HSK,
            TO_HEX(MD5(Src.RF || '^' || Src.CF))                        AS Courier_HSK,
            TO_HEX(MD5(Src.LabelNo))                                    AS LabelNo_HSK,
            Src.CountryCode,
            Src.RF,
            Src.CF,
            Src.LabelNo,
            DATETIME(Src.Date + Src.Time)                               AS CreatedDate,
            Src.Onforwards,
            C.CountryName,
            Src.FileId,
            Loaded,
            ProcessID,
            ''                                                          AS RecordSource
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_LA_RuralOnforwards_Stg` Src
        LEFT JOIN Dim_Country C ON C.CountryCode = Src.CountryCode
        WHERE NOT EXISTS (
            -- Check already done in Load_LNK_Scan_Stg but kept here in case routine is re-run
            SELECT 1
            FROM `{{ project_id }}.{{ target_dataset_id }}.dv_LNK_RuralOnforwards` tgt
            WHERE tgt.RF        = Src.RF
              AND tgt.CF        = Src.CF
              AND tgt.LabelNo   = Src.LabelNo
              AND tgt.CreatedDate = DATETIME(Src.Date + Src.Time)
        );

        SET Inserted = @@ROW_COUNT;
        SET Result   = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed';
        SET ErrorMessage = @@error.message;

    END;

    -- Record load metrics in log
    SET Ended = CURRENT_DATETIME();
    CALL `{{ project_id }}.{{ sp_dataset_id }}.SaveLog`(
        Component,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted
    );

    -- Return next date (the day after the max CreatedDate loaded)
    SET NextDate = (
        SELECT DATE_ADD(DATE(MAX(CreatedDate)), INTERVAL 1 DAY)
        FROM `{{ project_id }}.{{ target_dataset_id }}.dv_LNK_RuralOnforwards`
    );

    SELECT NextDate;

END;
