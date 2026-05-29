CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.sp_load_InterimStaging_TrackAndTrace_Stg_Hist`()
BEGIN
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.InterimStaging_TrackAndTrace_Stg`
        SELECT
            a.ID,
            a.RecordId,
            a.CountryCode,
            a.FranchiseeCode,
            a.ScanType,
            a.ScanStatus,
            a.LabelNo,
            a.ScanDate,
            a.CourierNo,
            a.CountryName,
            a.UploadDate,
            a.RecordCreateDate,
            a.iLocate,
            a.ProductId,
            a.Latitude,
            a.Longitude,
            a.Signature
        FROM (
            SELECT
                ID,
                RecordId,
                CountryCode,
                FranchiseeCode,
                ScanType,
                Status AS ScanStatus,
                LabelNo,
                ScanDate,
                CourierNo,
                '' AS CountryName,
                UploadDate,
                RecordCreateDate,
                iLocate,
                ProductId,
                Latitude,
                Longitude,
                Signature
            FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_vegeta_silver.FastwayReports_dbo_TrackAndTraceDataP`
            WHERE CountryCode IN (1, 6, 11, 24)
        ) a
        ORDER BY ID;

END;