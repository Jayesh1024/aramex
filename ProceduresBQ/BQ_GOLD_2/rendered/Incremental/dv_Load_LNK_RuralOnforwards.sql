CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_LNK_RuralOnforwards`(
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

        INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_RuralOnforwards`
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
            `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(
                Src.RF || '^' || Src.CF || '^' || Src.LabelNo || '^' || FORMAT_DATETIME('%Y-%m-%dT%H:%M:%E3S', Src.Date),'^') AS OnForwards_HSK,
            `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(Src.LabelNo,'^') AS LabelNo_HSK,
            `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(Src.RF,'^') AS FranchiseeCode_HSK,
            `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(Src.RF || '^' || Src.CF,'^') AS Courier_HSK,
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
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_LA_RuralOnforwards_Stg` Src
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Country` C ON C.CountryCode = Src.CountryCode
        WHERE NOT EXISTS (
            -- Check already done in Load_LNK_Scan_Stg but kept here in case routine is re-run
            SELECT 1
            FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_RuralOnforwards` tgt
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
    CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
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
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_RuralOnforwards`
    );

    SELECT NextDate;

END;