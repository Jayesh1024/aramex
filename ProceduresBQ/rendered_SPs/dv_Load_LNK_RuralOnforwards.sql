-- ==========================================================================================
-- Routine:     dv_Load_LNK_RuralOnforwards
-- Description: Loads relationships into LNK_RuralOnforwards
--              BigQuery compatible version of Load_LNK_RuralOnforwards
-- Example:     CALL dv.dv_Load_LNK_RuralOnforwards(590)
-- History:
--  17/01/2024  B. Woods        Routine Written
--  [BQ Port]   Converted from SQL Server to BigQuery
--  [BQ Fix]    Dim_Country → fully qualified `searce-sandbox-da-delivery.Aramex_oceania.dbo_Dim_Country`
--  [BQ Fix]    Src.Date + Src.Time → Src.Date only (Src.Time contains non-time values e.g. "Time_49")
--  [BQ Fix]    TO_HEX(MD5(...)) → MD5(...) for all HSK columns (target columns are BYTES not STRING)
--  [BQ Fix]    SaveLog → Staging_SaveLog with additional -1, -1 arguments.
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `searce-sandbox-da-delivery.Aramex_oceania_SP.dv_Load_LNK_RuralOnforwards`(
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

        INSERT INTO `searce-sandbox-da-delivery.Aramex_oceania.dv_LNK_RuralOnforwards`
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
            -- MD5 returns BYTES directly to match target BYTES column type
            -- Src.Time dropped — contains non-time values (e.g. "Time_49"), Src.Date used directly
            MD5(
                Src.RF || '^'
                || Src.CF || '^'
                || Src.LabelNo || '^'
                || FORMAT_DATETIME('%Y-%m-%dT%H:%M:%E3S', Src.Date)
            )                                                            AS OnForwards_HSK,
            MD5(Src.LabelNo)                                            AS LabelNo_HSK,
            MD5(Src.RF)                                                  AS FranchiseeCode_HSK,
            MD5(Src.RF || '^' || Src.CF)                                AS Courier_HSK,
            Src.CountryCode,
            Src.RF,
            Src.CF,
            Src.LabelNo,
            Src.Date                                                    AS CreatedDate,
            Src.Onforwards,
            C.CountryName,
            Src.FileId,
            Loaded,
            ProcessID,
            ''                                                          AS RecordSource
        FROM `searce-sandbox-da-delivery.Aramex_oceania.Staging_LA_RuralOnforwards_Stg` Src
        LEFT JOIN `searce-sandbox-da-delivery.Aramex_oceania.dbo_Dim_Country` C ON C.CountryCode = Src.CountryCode
        WHERE NOT EXISTS (
            -- Check already done in Load_LNK_Scan_Stg but kept here in case routine is re-run
            SELECT 1
            FROM `searce-sandbox-da-delivery.Aramex_oceania.dv_LNK_RuralOnforwards` tgt
            WHERE tgt.RF          = Src.RF
              AND tgt.CF          = Src.CF
              AND tgt.LabelNo     = Src.LabelNo
              AND tgt.CreatedDate = Src.Date
        );

        SET Inserted = @@ROW_COUNT;
        SET Result   = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed';
        SET ErrorMessage = @@error.message;

    END;

    -- Record load metrics in log
    SET Ended = CURRENT_DATETIME();
    CALL `searce-sandbox-da-delivery.Aramex_oceania_SP.Staging_SaveLog`(
        Component,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted,
        -1,
        -1
    );

    -- Return next date (the day after the max CreatedDate loaded)
    SET NextDate = (
        SELECT DATE_ADD(DATE(MAX(CreatedDate)), INTERVAL 1 DAY)
        FROM `searce-sandbox-da-delivery.Aramex_oceania.dv_LNK_RuralOnforwards`
    );

    SELECT NextDate;

END;