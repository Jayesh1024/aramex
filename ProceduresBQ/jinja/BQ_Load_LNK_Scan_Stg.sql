-- ==========================================================================================
-- Routine:     Load_LNK_Scan_Stg
-- Description: Prepares staging table for loading into LNK_Scan
-- Example:     Exec Staging.Load_LNK_Scan_Stg 687  
-- History:
--  28/11/2018  P. Waldron      Routine Written
--  17/07/2020  P. Waldron      Check for already existing LNK_Scan rows based on Scan_HSK
--  12/10/2020  P. Waldron      Replace Joins to HUB_Label and HUB_Location with HSK calc 
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.Staging_Load_LNK_Scan_Stg`(
    IN p_ProcessID INT64
)
OPTIONS(strict_mode=false)
BEGIN
    -- 1. Variables & Parameters
    DECLARE v_DefaultDate DATETIME DEFAULT DATETIME '1901-01-01';
    DECLARE v_MinScanDate DATETIME;
    DECLARE v_ABSMinDate DATETIME;

    DECLARE v_Component STRING DEFAULT 'Staging_Load_LNK_Scan_Stg';
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Ended DATETIME;
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;

    -- Initialize logic
    SET v_ABSMinDate = DATETIME_SUB(v_Started, INTERVAL 24 MONTH);

    BEGIN
        -- Calculate MinScanDate for the filter logic
        SET v_MinScanDate = (
            SELECT MIN(ScanDate)
            FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Scans_Stg`
            WHERE ScanDate >= v_ABSMinDate
        );

        -- Process the entire load in one step (Removed broken GUID-based WHILE loop)
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_LNK_Scan_Stg` (
            Scan_HSK, FranchiseeCode_HSK, Courier_HSK, LabelNo_HSK, Location_HSK, ScanStatus_HSK, 
            FranchiseeCode, CourierNumber, LabelNo, Latitude, Longitude, ScanStatus, CountryName, ScanDate, ScanType,
            RecordSource, RecordSourceId, Loaded, ProcessId, TrackAndTraceID, iLocate, `Signature`, UploadDate
        )
        SELECT 
            Scan_HSK, FranchiseeCode_HSK, Courier_HSK, LabelNo_HSK, Location_HSK, ScanStatus_HSK, 
            FranchiseeCode, CourierNumber, LabelNo, Latitude, Longitude, ScanStatus, CountryName, ScanDate, ScanType, 
            RecordSource, RecordSourceId, Loaded, ProcessId, TrackAndTraceID, iLocate, `Signature`, UploadDate
        FROM 
        (
            SELECT 
                `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(
                    CONCAT(
                        Src.FranchiseeCode, '^',
                        Src.CourierNumber, '^',
                        Src.LabelNo, '^',
                        FORMAT_DATETIME('%Y-%m-%dT%H:%M:%E3S', Src.ScanDate), '^',
                        Src.ScanStatus, '^', Src.CountryName, '^',
                        CAST(Src.Latitude AS STRING), '^', CAST(Src.Longitude AS STRING), '^',
                        Src.ScanType
                    )
                ) AS Scan_HSK,
                FranchiseeCode_HSK, Courier_HSK, LabelNo_HSK, Location_HSK, ScanStatus_HSK, 
                FranchiseeCode, CourierNumber, RTRIM(LabelNo) as LabelNo, Latitude, Longitude, 
                ScanStatus, CountryName, ScanDate, ScanType,
                RecordSource, RecordSourceId, TrackAndTraceID, iLocate, `Signature`, UploadDate,
                CURRENT_DATETIME() as Loaded, p_ProcessID as ProcessId
            FROM 
            (
                SELECT 
                    rf.FranchiseeCode_HSK, 
                    cf.Courier_HSK, 
                    `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(COALESCE(stg.LabelNo, 'Unknown')) AS LabelNo_HSK, 
                    `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(CONCAT(CAST(COALESCE(stg.Latitude, 0) AS STRING), '/', CAST(COALESCE(stg.Longitude, 0) AS STRING))) AS Location_HSK,
                    stat.ScanStatus_HSK,
                    COALESCE(rf.FranchiseeCode, stg.FranchiseeCode, 'Unk') AS FranchiseeCode,
                    COALESCE(cf.CourierNumber, stg.CourierNo, 'Unk') AS CourierNumber,
                    COALESCE(stg.LabelNo, 'Unknown') AS LabelNo,                  
                    COALESCE(stg.Latitude, 0) AS Latitude, 
                    COALESCE(stg.Longitude, 0) AS Longitude,                  
                    COALESCE(stat.ScanStatus, stg.ScanStatus, 'Unk') AS ScanStatus,
                    COALESCE(stg.CountryName, 'Unknown') AS CountryName,
                    COALESCE(stg.ScanDate, v_DefaultDate) AS ScanDate,
                    COALESCE(stg.ScanType, '?') AS ScanType,
                    stg.RecordSource,
                    stg.RecordSourceId,
                    stg.TrackAndTraceID,
                    stg.iLocate,
                    stg.`Signature`,
                    stg.UploadDate
                FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Scans_Stg` as stg
                LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_HUB_RF` AS rf 
                  ON rf.FranchiseeCode = stg.FranchiseeCode
                LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_HUB_CF` AS cf
                  ON cf.RFCode = stg.FranchiseeCode AND cf.CourierNumber = stg.CourierNo
                LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_HUB_ScanStatus` AS stat 
                  ON stat.ScanStatus = stg.ScanStatus AND stat.CountryName = stg.CountryName
                WHERE stg.ScanDate >= v_ABSMinDate
            ) Src
        ) AS new_scans
        WHERE NOT EXISTS (
            SELECT 1 FROM `{{ project_id }}.{{ target_dataset_id }}.dv_LNK_Scan` scan 
            WHERE scan.Scan_HSK = new_scans.Scan_HSK
            AND scan.ScanDate >= v_MinScanDate
        );

        SET v_Inserted = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Final Log Call
    SET v_Ended = CURRENT_DATETIME();
    CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,
        v_Ended,
        v_Result,
        v_ErrorMessage,
        v_Inserted,
        v_Updated,
        -1
    );
END;