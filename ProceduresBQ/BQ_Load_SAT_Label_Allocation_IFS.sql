-- ==========================================================================================
-- Routine:     BQ_Load_SAT_Label_Allocation_IFS
-- Description: Loads attributes into SAT_Label_Allocation_IFS from `{{ project_id }}.{{ target_dataset_id }}.Staging_HDManifests_Stg`
--              BigQuery compatible version of Load_SAT_Label_Allocation_IFS
--              Note: MERGE with OUTPUT $action not supported in BQ.
--                    Replaced with:
--                      1. MERGE to expire changed current rows (IsCurrent=0, ValidTo=Loaded)
--                      2. INSERT new rows (IsCurrent=1)
--                    Audit table format preserved exactly.
--                    PIVOT replaced with conditional aggregation.
--                    dbo.GetHashKey replaced with TO_HEX(MD5(...)).
-- Example:     CALL dv.BQ_Load_SAT_Label_Allocation_IFS(153, 'IFS')
-- History:
--  25/07/2019  P. Waldron      Routine Written
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.BQ_Load_SAT_Label_Allocation_IFS`(
    IN ProcessID    INT64,
    IN RecordSource STRING
)
BEGIN

    DECLARE DefaultValidFrom DATETIME DEFAULT DATETIME '1900-01-01 00:00:00';
    DECLARE DefaultValidTo   DATETIME DEFAULT DATETIME '9999-12-31 00:00:00';
    DECLARE Loaded           DATETIME DEFAULT CURRENT_DATETIME();

    DECLARE Component    STRING DEFAULT 'dv.Load_SAT_Label_Allocation_IFS';
    DECLARE Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING;
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64 DEFAULT 0;
    DECLARE Updated      INT64 DEFAULT 0;

    BEGIN

        -- -----------------------------------------------------------------------
        -- STEP 1: Expire changed current rows (IsCurrent=0, ValidTo=Loaded)
        -- -----------------------------------------------------------------------
        MERGE `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_IFS` AS Tgt
        USING (
            SELECT DISTINCT
                Sat.LabelNo_HSK,
                Stg.LabelNo,
                Stg.CountryCode,
                IFNULL(cty.CountryName, 'Unknown') AS Country,
                Stg.ManifestId,
                Stg.ConDate,
                Stg.ClientId,
                Stg.CustomerID,
                Stg.DeliveryCountryCode,
                Stg.CollectionCountryCode,
                Stg.DeliveryRF,
                Stg.CollectionRF,
                Stg.Quantity,
                Stg.Weight,
                Stg.Width,
                Stg.Length,
                Stg.Height,
                Stg.DateInserted,
                Stg.RecordId,
                Stg.UniqueParcelIdentifier
            FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_HDManifests_Stg` Stg
            LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` cty ON cty.CountryCode = Stg.CountryCode
            LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_IFS` Sat ON Sat.LabelNo = Stg.LabelNo
        ) AS Src
        ON  Tgt.LabelNo_HSK = Src.LabelNo_HSK
        AND Tgt.IsCurrent   = 1
        WHEN MATCHED AND (
            -- Replicate EXCEPT change detection
            IFNULL(Tgt.LabelNo,                         '') <> IFNULL(Src.LabelNo,                         '')
         OR IFNULL(Tgt.CountryCode,                     '') <> IFNULL(Src.CountryCode,                     '')
         OR IFNULL(Tgt.Country,                         '') <> IFNULL(Src.Country,                         '')
         OR IFNULL(CAST(Tgt.ManifestId AS STRING),       '') <> IFNULL(CAST(Src.ManifestId AS STRING),       '')
         OR IFNULL(CAST(Tgt.ConDate AS STRING),           '') <> IFNULL(CAST(Src.ConDate AS STRING),           '')
         OR IFNULL(CAST(Tgt.ClientId AS STRING),          '') <> IFNULL(CAST(Src.ClientId AS STRING),          '')
         OR IFNULL(CAST(Tgt.CustomerID AS STRING),        '') <> IFNULL(CAST(Src.CustomerID AS STRING),        '')
         OR IFNULL(Tgt.DeliveryCountryCode,              '') <> IFNULL(Src.DeliveryCountryCode,              '')
         OR IFNULL(Tgt.CollectionCountryCode,            '') <> IFNULL(Src.CollectionCountryCode,            '')
         OR IFNULL(Tgt.DeliveryRF,                       '') <> IFNULL(Src.DeliveryRF,                       '')
         OR IFNULL(Tgt.CollectionRF,                     '') <> IFNULL(Src.CollectionRF,                     '')
         OR IFNULL(CAST(Tgt.Quantity AS STRING),          '') <> IFNULL(CAST(Src.Quantity AS STRING),          '')
         OR IFNULL(CAST(Tgt.Weight AS STRING),            '') <> IFNULL(CAST(Src.Weight AS STRING),            '')
         OR IFNULL(CAST(Tgt.Width AS STRING),             '') <> IFNULL(CAST(Src.Width AS STRING),             '')
         OR IFNULL(CAST(Tgt.Length AS STRING),            '') <> IFNULL(CAST(Src.Length AS STRING),            '')
         OR IFNULL(CAST(Tgt.Height AS STRING),            '') <> IFNULL(CAST(Src.Height AS STRING),            '')
         OR IFNULL(CAST(Tgt.DateInserted AS STRING),      '') <> IFNULL(CAST(Src.DateInserted AS STRING),      '')
         OR IFNULL(CAST(Tgt.RecordId AS STRING),          '') <> IFNULL(CAST(Src.RecordId AS STRING),          '')
         OR IFNULL(Tgt.UniqueParcelIdentifier,            '') <> IFNULL(Src.UniqueParcelIdentifier,            '')
        )
        THEN UPDATE SET
            IsCurrent = 0,
            ValidTo   = Loaded;

        SET Updated = @@ROW_COUNT;

        -- -----------------------------------------------------------------------
        -- STEP 2: Insert new rows for unmatched source records
        -- -----------------------------------------------------------------------
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_IFS`
        (
            LabelNo_HSK,
            LabelNo,
            CountryCode,
            Country,
            ManifestId,
            ConDate,
            ClientId,
            CustomerID,
            DeliveryCountryCode,
            CollectionCountryCode,
            DeliveryRF,
            CollectionRF,
            Quantity,
            Weight,
            Width,
            Length,
            Height,
            DateInserted,
            RecordId,
            Loaded,
            ProcessId,
            RecordSource,
            RecordSourceId,
            ValidFrom,
            ValidTo,
            IsCurrent,
            UniqueParcelIdentifier
        )
        SELECT DISTINCT
            IFNULL(Sat.LabelNo_HSK, TO_HEX(MD5(Stg.LabelNo))) AS LabelNo_HSK,
            Stg.LabelNo,
            Stg.CountryCode,
            IFNULL(cty.CountryName, 'Unknown') AS Country,
            Stg.ManifestId,
            Stg.ConDate,
            Stg.ClientId,
            Stg.CustomerID,
            Stg.DeliveryCountryCode,
            Stg.CollectionCountryCode,
            Stg.DeliveryRF,
            Stg.CollectionRF,
            Stg.Quantity,
            Stg.Weight,
            Stg.Width,
            Stg.Length,
            Stg.Height,
            Stg.DateInserted,
            Stg.RecordId,
            Loaded          AS Loaded,
            ProcessID       AS ProcessId,
            RecordSource,
            Stg.RecordId    AS RecordSourceId,
            DefaultValidFrom AS ValidFrom,
            DefaultValidTo  AS ValidTo,
            1               AS IsCurrent,
            Stg.UniqueParcelIdentifier
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_HDManifests_Stg` Stg
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` cty ON cty.CountryCode = Stg.CountryCode
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_IFS` Sat ON Sat.LabelNo = Stg.LabelNo
        WHERE NOT EXISTS (
            SELECT 1
            FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_IFS` AS Tgt
            WHERE Tgt.LabelNo_HSK = IFNULL(Sat.LabelNo_HSK, TO_HEX(MD5(Stg.LabelNo)))
              AND Tgt.IsCurrent   = 1
        );

        SET Inserted = @@ROW_COUNT;
        SET Result   = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed';
        SET ErrorMessage = @@error.message;

    END;

    -- -----------------------------------------------------------------------
    -- Audit counts: replicate PIVOT(IsCurrent in [0],[1]) pattern
    -- -----------------------------------------------------------------------
    SET Updated = (
        SELECT IFNULL(COUNTIF(IsCurrent = 0), 0)
        FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_IFS`
        WHERE ProcessId = ProcessID
    );
    SET Inserted = (
        SELECT IFNULL(COUNTIF(IsCurrent = 1), 0)
        FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_IFS`
        WHERE ProcessId = ProcessID
    );

    SET Ended = CURRENT_DATETIME();
    CALL `{{ project_id }}.{{ sp_dataset_id }}.SaveLog`(
        Component,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted,
        Updated
    );

END;
