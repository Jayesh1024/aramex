CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_SAT_BLKContainerManifestContents`(
    IN p_ProcessID    INT64,
    IN p_RecordSource STRING
)
BEGIN
    -- Declarations & Variable Initialization
    DECLARE Loaded        DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Component     STRING DEFAULT 'dv.Load_SAT_BLKContainerManifestContents';
    DECLARE Started       DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended         DATETIME;
    DECLARE Result        STRING DEFAULT 'Success';
    DECLARE ErrorMessage  STRING DEFAULT NULL;
    
    DECLARE Updated       INT64 DEFAULT 0;
    DECLARE Inserted      INT64 DEFAULT 0;

    BEGIN
        BEGIN TRANSACTION;

        -- STEP 1: UPDATE Existing Records if attributes have changed
        -- Replicates the MSSQL JOIN + EXCEPT behavior
        MERGE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_BLKContainerManifestContents` AS LTP
        USING `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_BLK_ContainerManifestContents_Stg` AS Src
        ON LTP.ContainerManifestId = Src.ContainerManifestId 
           AND RTRIM(LTP.LabelNo) = RTRIM(Src.LabelNo)
        WHEN MATCHED AND (
            -- Replicating the EXCEPT clause logic (checking if any descriptive attributes differ or contain changes)
            IFNULL(LTP.ScanDate, DATETIME '1900-01-01')        != IFNULL(Src.ScanDate, DATETIME '1900-01-01') OR
            IFNULL(LTP.MixedManifestId, -1)                    != IFNULL(Src.MixedManifestId, -1) OR
            IFNULL(LTP.ScanUserId, -1)                         != IFNULL(Src.ScanUserId, -1) OR
            IFNULL(LTP.Destination, '')                        != IFNULL(Src.Destination, '') OR
            IFNULL(LTP.Weight, -1.0)                           != IFNULL(Src.Weight, -1.0) OR
            IFNULL(LTP.CF, '')                               != IFNULL(Src.CF, '')
        ) THEN
            UPDATE SET
                LTP.ScanDate        = Src.ScanDate,
                LTP.ScanUserId      = Src.ScanUserId,
                LTP.Destination     = Src.Destination,
                LTP.MixedManifestId = Src.MixedManifestId,
                LTP.Weight          = Src.Weight,
                LTP.CF              = Src.CF,
                LTP.Loaded          = Started,
                LTP.ProcessID       = p_ProcessID,
                LTP.RecordSource    = p_RecordSource;

        SET Updated = @@ROW_COUNT;

        -- STEP 2: INSERT Brand New Records
        INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_BLKContainerManifestContents` (
            ContainerManifestContents_HSK, ContainerManifestId, LabelNo, ScanDate, 
            ScanUserId, Destination, MixedManifestId, Weight, CF, Loaded, ProcessID, RecordSource
        )
        SELECT
            `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(CONCAT(CAST(Src.ContainerManifestId AS STRING), RTRIM(Src.LabelNo)), '^') AS ContainerManifestContents_HSK,
            Src.ContainerManifestId,
            Src.LabelNo,
            Src.ScanDate,
            Src.ScanUserId,
            Src.Destination,
            Src.MixedManifestId,
            Src.Weight,
            Src.CF,
            Started      AS Loaded,
            p_ProcessID    AS ProcessID,
            p_RecordSource AS RecordSource
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_BLK_ContainerManifestContents_Stg` AS Src
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_BLKContainerManifestContents` AS LTP
            ON LTP.ContainerManifestId = Src.ContainerManifestId 
           AND RTRIM(LTP.LabelNo) = RTRIM(Src.LabelNo)
        WHERE LTP.LabelNo IS NULL;

        SET Inserted = @@ROW_COUNT;
        
        COMMIT TRANSACTION;

    EXCEPTION WHEN ERROR THEN
        -- Automated Rollback on Exception block execution
        ROLLBACK TRANSACTION;
        SET Result       = 'Failed';
        SET ErrorMessage = @@error.message;
    END;

    -- Record load metrics in log (Clean exit, safely tracking Failure or Success states)
    SET Ended = CURRENT_DATETIME();
    CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
        Component,
        p_ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted,
        Updated,
        -1
    );

END;