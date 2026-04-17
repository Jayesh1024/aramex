-- ==========================================================================================
-- Routine:     dv_Load_SAT_Label_Allocation_IFS
-- Description: Loads attributes into SAT_Label_Allocation_IFS from `searce-sandbox-da-delivery.Aramex_oceania.Staging_HDManifests_Stg`
--              BigQuery compatible version of Load_SAT_Label_Allocation_IFS
--              Note: MERGE with OUTPUT $action not supported in BQ.
--                    Replaced with:
--                      1. MERGE to expire changed current rows (IsCurrent=0, ValidTo=Loaded)
--                      2. INSERT new rows (IsCurrent=1)
--                    Audit table format preserved exactly.
--                    PIVOT replaced with conditional aggregation.
--                    dbo.GetHashKey replaced with TO_HEX(MD5(...)).
-- Example:     CALL dv.dv_Load_SAT_Label_Allocation_IFS(153, 'IFS')
-- History:
--  25/07/2019  P. Waldron      Routine Written
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `searce-sandbox-da-delivery.Aramex_oceania_SP.dv_Load_SAT_Label_Allocation_IFS`(
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
        MERGE `searce-sandbox-da-delivery.Aramex_oceania.dv_SAT_Label_Allocation_IFS` AS Tgt
        USING (
            SELECT DISTINCT
                MD5(Stg.LabelNo) AS LabelNo_HSK,
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
            FROM `searce-sandbox-da-delivery.Aramex_oceania.Staging_HDManifests_Stg` Stg
            LEFT JOIN `searce-sandbox-da-delivery.Aramex_oceania.dbo_Dim_Country` cty ON cty.CountryCode = Stg.CountryCode
        ) AS Src
        ON  Tgt.LabelNo_HSK = Src.LabelNo_HSK
        AND Tgt.IsCurrent   = 1
        WHEN MATCHED AND (
            -- Replicate EXCEPT change detection with proper BigQuery type casting
               IFNULL(CAST(Tgt.ManifestId AS STRING), '')            <> IFNULL(CAST(Src.ManifestId AS STRING), '')
            OR IFNULL(CAST(Tgt.ConDate AS STRING), '')               <> IFNULL(CAST(Src.ConDate AS STRING), '')
            OR IFNULL(CAST(Tgt.ClientId AS STRING), '')              <> IFNULL(CAST(Src.ClientId AS STRING), '')
            OR IFNULL(CAST(Tgt.CustomerID AS STRING), '')            <> IFNULL(CAST(Src.CustomerID AS STRING), '')
            OR IFNULL(CAST(Tgt.DeliveryCountryCode AS STRING), '')   <> IFNULL(CAST(Src.DeliveryCountryCode AS STRING), '')
            OR IFNULL(CAST(Tgt.CollectionCountryCode AS STRING), '') <> IFNULL(CAST(Src.CollectionCountryCode AS STRING), '')
            OR IFNULL(CAST(Tgt.DeliveryRF AS STRING), '')            <> IFNULL(CAST(Src.DeliveryRF AS STRING), '')
            OR IFNULL(CAST(Tgt.CollectionRF AS STRING), '')          <> IFNULL(CAST(Src.CollectionRF AS STRING), '')
            OR IFNULL(CAST(Tgt.Quantity AS STRING), '')              <> IFNULL(CAST(Src.Quantity AS STRING), '')
            OR IFNULL(CAST(Tgt.Weight AS STRING), '')                <> IFNULL(CAST(Src.Weight AS STRING), '')
            OR IFNULL(CAST(Tgt.Width AS STRING), '')                 <> IFNULL(CAST(Src.Width AS STRING), '')
            OR IFNULL(CAST(Tgt.Length AS STRING), '')                <> IFNULL(CAST(Src.Length AS STRING), '')
            OR IFNULL(CAST(Tgt.Height AS STRING), '')                <> IFNULL(CAST(Src.Height AS STRING), '')
            OR IFNULL(CAST(Tgt.DateInserted AS STRING), '')          <> IFNULL(CAST(Src.DateInserted AS STRING), '')
            OR IFNULL(CAST(Tgt.RecordId AS STRING), '')              <> IFNULL(CAST(Src.RecordId AS STRING), '')
            OR IFNULL(CAST(Tgt.UniqueParcelIdentifier AS STRING), '')<> IFNULL(CAST(Src.UniqueParcelIdentifier AS STRING), '')
        )
        THEN UPDATE SET
            IsCurrent = 0,
            ValidTo   = Loaded;

        SET Updated = @@ROW_COUNT;

        -- -----------------------------------------------------------------------
        -- STEP 2: Insert new rows for unmatched source records
        -- -----------------------------------------------------------------------
        INSERT INTO `searce-sandbox-da-delivery.Aramex_oceania.dv_SAT_Label_Allocation_IFS`
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
            MD5(Stg.LabelNo) AS LabelNo_HSK,
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
            Loaded,
            ProcessID,
            RecordSource,
            Stg.RecordId,
            DefaultValidFrom,
            DefaultValidTo,
            1,
            Stg.UniqueParcelIdentifier
        FROM `searce-sandbox-da-delivery.Aramex_oceania.Staging_HDManifests_Stg` Stg
        LEFT JOIN `searce-sandbox-da-delivery.Aramex_oceania.dbo_Dim_Country` cty ON cty.CountryCode = Stg.CountryCode
        WHERE NOT EXISTS (
            SELECT 1
            FROM `searce-sandbox-da-delivery.Aramex_oceania.dv_SAT_Label_Allocation_IFS` AS Tgt
            WHERE Tgt.LabelNo_HSK = MD5(Stg.LabelNo)
              AND Tgt.IsCurrent   = 1
        );

        SET Inserted = @@ROW_COUNT;
        SET Result   = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed';
        SET ErrorMessage = @@error.message;

    END;

    -- -----------------------------------------------------------------------
    -- Audit counts based on current ProcessID
    -- -----------------------------------------------------------------------
    SET Updated = (
        SELECT IFNULL(COUNTIF(IsCurrent = 0), 0)
        FROM `searce-sandbox-da-delivery.Aramex_oceania.dv_SAT_Label_Allocation_IFS`
        WHERE ProcessId = ProcessID AND ValidTo = Loaded
    );
    SET Inserted = (
        SELECT IFNULL(COUNTIF(IsCurrent = 1), 0)
        FROM `searce-sandbox-da-delivery.Aramex_oceania.dv_SAT_Label_Allocation_IFS`
        WHERE ProcessId = ProcessID AND Loaded = Loaded
    );

    SET Ended = CURRENT_DATETIME();
    CALL `searce-sandbox-da-delivery.Aramex_oceania_SP.Staging_SaveLog`(
        Component,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted,
        Updated,
        -1
    );

END;