CREATE OR REPLACE PROCEDURE `Staging.Load_LNK_Scan_Stg`(
    IN p_ProcessID INT64
)
BEGIN
    -- 2. Variables & Parameters: DECLARE statements at the very top
    DECLARE v_Loaded TIMESTAMP;
    DECLARE v_BatchSize INT64 DEFAULT 500000;
    DECLARE v_StartID INT64 DEFAULT 1;
    DECLARE v_EndID INT64;
    DECLARE v_LastID INT64; 
    DECLARE v_DefaultDate TIMESTAMP DEFAULT TIMESTAMP('1901-01-01');
    DECLARE v_MinScanDate TIMESTAMP;
    DECLARE v_ABSMinDate TIMESTAMP;

    DECLARE v_Component STRING DEFAULT 'Staging.Load_LNK_Scan_Stg';
    DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Ended TIMESTAMP;
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;

    -- Initialize logic
    SET v_ABSMinDate = TIMESTAMP_SUB(v_Started, INTERVAL 24 MONTH);

    BEGIN
        -- Initial metadata gathering logic
        SET (v_LastID, v_MinScanDate) = (
            SELECT AS STRUCT 
                IFNULL(MAX(RowID), 0),
                MIN(ScanDate)
            FROM `Staging.Scans_Stg`
            WHERE ScanDate >= v_ABSMinDate
        );

        -- Preserve the Batching Loop logic exactly as provided
        WHILE (v_StartID <= v_LastID) DO
            
            SET v_EndID = v_StartID + v_BatchSize - 1;
            SET v_Loaded = CURRENT_TIMESTAMP();

            -- Inner Logic: Insert into staging link table
            INSERT INTO `Staging.LNK_Scan_Stg` (
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
                    `dbo.GetHashKey`(
                        CONCAT(
                            Src.FranchiseeCode, '^',
                            Src.CourierNumber, '^',
                            Src.LabelNo, '^',
                            FORMAT_TIMESTAMP('%Y-%m-%dT%H:%M:%E3S', Src.ScanDate), '^',
                            Src.ScanStatus, '^', Src.CountryName, '^',
                            CAST(Src.Latitude AS STRING), '^', CAST(Src.Longitude AS STRING), '^',
                            Src.ScanType
                        )
                    ) AS Scan_HSK,
                    FranchiseeCode_HSK, Courier_HSK, LabelNo_HSK, Location_HSK, ScanStatus_HSK, 
                    FranchiseeCode, CourierNumber, RTRIM(LabelNo) as LabelNo, Latitude, Longitude, 
                    ScanStatus, CountryName, ScanDate, ScanType,
                    RecordSource, RecordSourceId, TrackAndTraceID, iLocate, `Signature`, UploadDate,
                    v_Loaded as Loaded, p_ProcessID as ProcessId
                FROM 
                (
                    SELECT 
                        rf.FranchiseeCode_HSK, 
                        cf.Courier_HSK, 
                        `dbo.GetHashKey`(COALESCE(stg.LabelNo, 'Unknown')) AS LabelNo_HSK, 
                        `dbo.GetHashKey`(CONCAT(CAST(COALESCE(stg.Latitude, 0) AS STRING), '/', CAST(COALESCE(stg.Longitude, 0) AS STRING))) AS [Location_HSK],
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
                    FROM `Staging.Scans_Stg` as stg
                    LEFT JOIN `dv.HUB_RF` AS rf 
                      ON rf.FranchiseeCode = stg.FranchiseeCode
                    LEFT JOIN `dv.HUB_CF` AS cf
                      ON cf.RFCode = stg.FranchiseeCode AND cf.CourierNumber = stg.CourierNo
                    LEFT JOIN `dv.HUB_ScanStatus` AS stat 
                      ON stat.ScanStatus = stg.ScanStatus AND stat.CountryName = stg.CountryName
                    WHERE stg.RowID BETWEEN v_StartID AND v_EndID
                    AND stg.ScanDate >= v_ABSMinDate
                ) Src
            ) new
            WHERE NOT EXISTS (
                SELECT 1 FROM `dv.LNK_Scan` scan 
                WHERE scan.Scan_HSK = new.Scan_HSK
                AND scan.ScanDate >= v_MinScanDate
            );

            SET v_Inserted = v_Inserted + @@row_count;
            SET v_StartID = v_EndID + 1;

        END WHILE;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Final Log Call (Metadata & Logging)
    SET v_Ended = CURRENT_TIMESTAMP();
    CALL `Staging.SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,
        v_Ended,
        v_Result,
        v_ErrorMessage,
        v_Inserted,
        v_Updated, -- Updated remains 0 as per logic
        -1
    );
END;