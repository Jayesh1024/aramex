CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_InterimStaging_TrackAndTrace_Stg_Hist`()
BEGIN
    INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.InterimStaging_TrackAndTrace_Stg`
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
            FROM `{{ project_id }}.{{ source_dataset_id }}.FastwayReports_dbo_TrackAndTraceDataP`
            WHERE CountryCode IN (1, 6, 11, 24)
        ) a
        ORDER BY ID;

END;