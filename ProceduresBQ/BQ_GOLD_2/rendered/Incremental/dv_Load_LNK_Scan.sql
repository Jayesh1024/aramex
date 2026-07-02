CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_LNK_Scan`(
    IN ProcessID INT64
)
BEGIN

    DECLARE Loaded       DATETIME DEFAULT CURRENT_DATETIME();

    DECLARE Component    STRING DEFAULT 'dv.Load_LNK_Scan';
    DECLARE Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING;
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64 DEFAULT 0;

    BEGIN

        INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Scan`
        (
            Scan_HSK,
            FranchiseeCode_HSK,
            Courier_HSK,
            LabelNo_HSK,
            Location_HSK,
            ScanStatus_HSK,
            FranchiseeCode,
            CourierNumber,
            LabelNo,
            Latitude,
            Longitude,
            ScanStatus,
            CountryName,
            ScanDate,
            ScanType,
            Loaded,
            ProcessId,
            RecordSource,
            RecordSourceId,
            TrackAndTraceID,
            iLocate,
            UploadDate
        )
        SELECT
            Scan_HSK,
            COALESCE(FranchiseeCode_HSK, `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(FranchiseeCode,'^'))                                          AS FranchiseeCode_HSK,
            COALESCE(Courier_HSK,        `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(FranchiseeCode || '^' || CourierNumber,'^'))                  AS Courier_HSK,
            COALESCE(LabelNo_HSK,        `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(LabelNo,'^'))                                                 AS LabelNo_HSK,
            COALESCE(Location_HSK,       `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(CAST(Latitude AS STRING) || '^' || CAST(Longitude AS STRING),'^')) AS Location_HSK,
            COALESCE(ScanStatus_HSK,     `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(ScanStatus || '^' || CountryName,'^'))                        AS ScanStatus_HSK,
            FranchiseeCode,
            CourierNumber,
            LabelNo,
            Latitude,
            Longitude,
            ScanStatus,
            CountryName,
            ScanDate,
            ScanType,
            Loaded,
            ProcessID,
            RecordSource,
            RecordSourceId,
            TrackAndTraceID,
            iLocate,
            UploadDate
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_LNK_Scan_Stg` AS Src
        ORDER BY Src.ScanDate DESC;

        SET Inserted = @@ROW_COUNT;
        SET Result   = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed';
        SET ErrorMessage = @@error.message;

    END;

    -- Record load metrics in log
    SET Result = 'Success';
    SET Ended  = CURRENT_DATETIME();
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

END;