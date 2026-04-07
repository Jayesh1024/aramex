-- ==========================================================================================
-- Routine:     BQ_Load_SAT_BLKContainerManifest
-- Description: Loads SAT_BLKContainerManifest from `{{ project_id }}.{{ target_dataset_id }}.Staging_BLK_ContainerManifest_Stg`
--              BigQuery compatible version of Load_SAT_BLKContainerManifest
--              Note: TRUNCATE + INSERT pattern preserved.
--                    WITH (TABLOCK) hint removed (not supported in BQ).
-- Example:     CALL dv.BQ_Load_SAT_BLKContainerManifest(-2, 'BLK_ManifestID')
-- History:
--  30/05/2024  B. Woods        Routine Written
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.BQ_Load_SAT_BLKContainerManifest`(
    IN ProcessID    INT64,
    IN RecordSource STRING
)
BEGIN

    DECLARE Loaded    DATETIME DEFAULT CURRENT_DATETIME();

    DECLARE Component    STRING DEFAULT 'dv.Load_SAT_BLKContainerManifest';
    DECLARE Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING;
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64 DEFAULT 0;

    BEGIN

        TRUNCATE TABLE `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_BLKContainerManifest`;

        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_BLKContainerManifest`
        SELECT
             ContainerManifestId
            ,ContainerId
            ,ContainerBarcode
            ,Location
            ,Destination
            ,TotalParcels
            ,Status
            ,ActionDate
            ,IsMixed
            ,MixedUnknownDest
            ,CurrentLocation
            ,CountryCode
            ,Sortation
            ,SortationStatus
            ,SortationOpen
            ,SortationClosed
            ,Started  AS Loaded
            ,ProcessID AS ProcessID
            ,RecordSource AS RecordSource
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_BLK_ContainerManifest_Stg`;

        SET Inserted = @@ROW_COUNT;
        SET Result   = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed';
        SET ErrorMessage = @@error.message;

    END;

    -- Record load metrics in log
    SET Result = 'Success';
    SET Ended  = CURRENT_DATETIME();
    CALL `{{ project_id }}.{{ sp_dataset_id }}.SaveLog`(
        Component,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted
    );

END;
