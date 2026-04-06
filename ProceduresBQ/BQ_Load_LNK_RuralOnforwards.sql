-- ==========================================================================================
-- Routine:     Load_LNK_RuralOnforwards  (BigQuery Version)
-- Description: Loads relationships into LNK_RuralOnforwards
-- Example:     CALL dv.Load_LNK_RuralOnforwards(590)
-- History:
--  17/01/2024  B. Woods        Routine Written
--  [BQ Migration] Converted SQL Server -> BigQuery
--    * dbo.GetHashKey(key, default) -> TO_HEX(MD5(key))
--      If a BQ UDF `GetHashKey` exists in your project, replace TO_HEX(MD5(...)) with it.
--    * [Date] + [Time] (SQL Server date+time add) -> DATETIME(Date, Time)
--      Assumes Date is DATE type and Time is TIME type in staging table.
--    * CONVERT(varchar(26), datetime, 126) -> FORMAT_DATETIME('%Y-%m-%dT%H:%M:%E3S', ...)
--    * DATEADD(DAY,1,date) -> DATE_ADD(date, INTERVAL 1 DAY)
--    * COALESCE(OBJECT_SCHEMA_NAME...) -> hardcoded procedure name string
--    * BEGIN TRANSACTION / COMMIT / ROLLBACK -> BQ equivalents
--    * @@TRANCOUNT > 0 -> @@in_transaction (BQ system variable)
--    * RAISERROR -> removed (no BQ equivalent for informational messages)
--    * See file 1 header for full conversion notes
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE dv.Load_LNK_RuralOnforwards(
    IN ProcessID INT64   -- Pass NULL to use default -200
)
BEGIN
    DECLARE v_ProcessID     INT64    DEFAULT IFNULL(ProcessID, -200);
    DECLARE v_Loaded        DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Component       STRING   DEFAULT 'dv.Load_LNK_RuralOnforwards';
    DECLARE Started         DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended           DATETIME;
    DECLARE Result          STRING   DEFAULT 'Success';
    DECLARE ErrorMessage    STRING   DEFAULT NULL;
    DECLARE Inserted        INT64    DEFAULT 0;
    DECLARE NextDate        DATE;

    BEGIN

        BEGIN TRANSACTION;

        INSERT INTO dv.LNK_RuralOnforwards
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
            -- Hash key: RF^CF^LabelNo^ISO-timestamp  (TO_HEX(MD5) replaces dbo.GetHashKey)
            TO_HEX(MD5(CONCAT(
                Src.RF, '^',
                Src.CF, '^',
                Src.LabelNo, '^',
                FORMAT_DATETIME('%Y-%m-%dT%H:%M:%E3S', DATETIME(Src.Date, Src.Time))
            )))                                               AS OnForwards_HSK,
            TO_HEX(MD5(Src.RF))                               AS FranchiseeCode_HSK,
            TO_HEX(MD5(CONCAT(Src.RF, '^', Src.CF)))          AS Courier_HSK,
            TO_HEX(MD5(Src.LabelNo))                          AS LabelNo_HSK,
            Src.CountryCode,
            Src.RF,
            Src.CF,
            Src.LabelNo,
            DATETIME(Src.Date, Src.Time)                      AS CreatedDate,
            Src.Onforwards,
            C.CountryName,
            Src.FileId,
            v_Loaded,
            v_ProcessID,
            ''                                                AS RecordSource
        FROM Staging.LA_RuralOnforwards_Stg AS Src
        LEFT JOIN Dim_Country AS C ON C.CountryCode = Src.CountryCode
        WHERE NOT EXISTS (
            -- Already checked in Load_LNK_Scan_Stg but repeated here in case of re-run
            SELECT 1
            FROM dv.LNK_RuralOnforwards AS tgt
            WHERE tgt.RF         = Src.RF
              AND tgt.CF         = Src.CF
              AND tgt.LabelNo    = Src.LabelNo
              AND tgt.CreatedDate= DATETIME(Src.Date, Src.Time)
        );

        SET Inserted = Inserted + @@row_count;

        COMMIT TRANSACTION;
        SET Result = 'Success';

    EXCEPTION WHEN ERROR THEN
        IF @@in_transaction THEN
            ROLLBACK TRANSACTION;
        END IF;
        SET Result       = 'Failed';
        SET ErrorMessage = @@error_message;
    END;

    -- Record load metrics in log
    SET Ended = CURRENT_DATETIME();
    CALL Staging.SaveLog(
        Component,
        v_ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted
    );

    -- Return next expected date (day after latest CreatedDate in target)
    SET NextDate = (
        SELECT DATE_ADD(CAST(MAX(CreatedDate) AS DATE), INTERVAL 1 DAY)
        FROM dv.LNK_RuralOnforwards
    );

    SELECT NextDate AS NextDate;

END;
