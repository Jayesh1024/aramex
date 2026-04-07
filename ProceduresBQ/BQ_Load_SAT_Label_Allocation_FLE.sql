-- ==========================================================================================
-- Routine:     BQ_Load_SAT_Label_Allocation_FLE
-- Description: Loads attributes into SAT_Label_Allocation_FLE from `{{ project_id }}.{{ target_dataset_id }}.Staging_ConsignmentItem_Stg`
--              BigQuery compatible version of Load_SAT_Label_Allocation_FLE
--              Note: MERGE with OUTPUT $action is not supported in BQ.
--                    Pattern replaced with:
--                      1. MERGE to UPDATE existing changed rows (set IsCurrent=0, ValidTo=Loaded)
--                      2. INSERT new rows (IsCurrent=1)
--                    Audit table format preserved exactly.
--                    PIVOT for @Updated/@Inserted replaced with conditional aggregation.
--                    dbo.GetHashKey replaced with TO_HEX(MD5(...)).
-- Example:     CALL dv.BQ_Load_SAT_Label_Allocation_FLE(153, 'FastLabelEnterprise')
-- History:
--  05/08/2019  P. Waldron      Routine Written
--  07/11/2019  P. Waldron      Remove CountryName from Label_HSK
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.BQ_Load_SAT_Label_Allocation_FLE`(
    IN ProcessID    INT64,
    IN RecordSource STRING
)
BEGIN

    DECLARE DefaultValidFrom DATETIME DEFAULT DATETIME '1900-01-01 00:00:00';
    DECLARE DefaultValidTo   DATETIME DEFAULT DATETIME '9999-12-31 00:00:00';
    DECLARE Loaded           DATETIME DEFAULT CURRENT_DATETIME();

    DECLARE Component    STRING DEFAULT 'dv.Load_SAT_Label_Allocation_FLE';
    DECLARE Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING;
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64 DEFAULT 0;
    DECLARE Updated      INT64 DEFAULT 0;

    BEGIN

        -- -----------------------------------------------------------------------
        -- STEP 1: Expire changed current rows (IsCurrent=0, ValidTo=Loaded)
        -- Replicates the MERGE WHEN MATCHED ... THEN UPDATE SET IsCurrent=0 branch.
        -- -----------------------------------------------------------------------
        MERGE `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_FLE` AS Tgt
        USING (
            SELECT DISTINCT
                Sat.LabelNo_HSK,
                Stg.LabelNumber         AS LabelNo,
                Stg.CountryId           AS CountryCode,
                IFNULL(cty.CountryName, 'Unknown') AS Country,
                Stg.WebCustomerId       AS OESCustomerId,
                Stg.CustomerId          AS FMSCustomerID,
                Stg.ReceiverContactName AS ToContactName,
                Stg.ReceiverAddress1    AS ToAddress1,
                Stg.ReceiverAddress2    AS ToAddress2,
                Stg.ReceiverSuburb      AS ToSuburb,
                Stg.ReceiverPostcode    AS ToPostcode,
                Stg.ReceiverPhone       AS ToPhone,
                Stg.ReceiverEmail       AS ToEmail,
                Stg.PrintedOn,
                Stg.Reference,
                Stg.SpecialInstructions,
                Stg.DestinationRF       AS DeliveryRF,
                Stg.ManifestId,
                Stg.Price,
                Stg.InvoiceNo           AS FMSInvoiceNo,
                Stg.ItemCount,
                Stg.CreatedOn,
                Stg.WeightCubic         AS CubicWeight,
                Stg.WeightDead          AS DeadWeight,
                Stg.Length              AS LengthInCm,
                Stg.Width               AS WidthInCm,
                Stg.Height              AS HeightInCm,
                Stg.Colour              AS LabelColour,
                Stg.ConsignmentItemId
            FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_ConsignmentItem_Stg` Stg
            LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` cty ON cty.CountryCode = Stg.CountryId
            LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF` Sat ON Sat.LabelNo = Stg.LabelNumber
        ) AS Src
        ON  Tgt.LabelNo_HSK = Src.LabelNo_HSK
        AND Tgt.IsCurrent   = 1
        WHEN MATCHED AND (
            -- Replicate EXCEPT change detection
            IFNULL(Tgt.LabelNo,             '') <> IFNULL(Src.LabelNo,             '')
         OR IFNULL(Tgt.CountryCode,         '') <> IFNULL(Src.CountryCode,         '')
         OR IFNULL(Tgt.Country,             '') <> IFNULL(Src.Country,             '')
         OR IFNULL(CAST(Tgt.OESCustomerId AS STRING), '') <> IFNULL(CAST(Src.OESCustomerId AS STRING), '')
         OR IFNULL(CAST(Tgt.FMSCustomerID AS STRING), '') <> IFNULL(CAST(Src.FMSCustomerID AS STRING), '')
         OR IFNULL(Tgt.ToContactName,       '') <> IFNULL(Src.ToContactName,       '')
         OR IFNULL(Tgt.ToAddress1,          '') <> IFNULL(Src.ToAddress1,          '')
         OR IFNULL(Tgt.ToAddress2,          '') <> IFNULL(Src.ToAddress2,          '')
         OR IFNULL(Tgt.ToSuburb,            '') <> IFNULL(Src.ToSuburb,            '')
         OR IFNULL(Tgt.ToPostcode,          '') <> IFNULL(Src.ToPostcode,          '')
         OR IFNULL(Tgt.ToPhone,             '') <> IFNULL(Src.ToPhone,             '')
         OR IFNULL(Tgt.ToEmail,             '') <> IFNULL(Src.ToEmail,             '')
         OR IFNULL(CAST(Tgt.PrintedOn AS STRING),  '') <> IFNULL(CAST(Src.PrintedOn AS STRING),  '')
         OR IFNULL(Tgt.Reference,           '') <> IFNULL(Src.Reference,           '')
         OR IFNULL(Tgt.SpecialInstructions, '') <> IFNULL(Src.SpecialInstructions, '')
         OR IFNULL(Tgt.DeliveryRF,          '') <> IFNULL(Src.DeliveryRF,          '')
         OR IFNULL(CAST(Tgt.ManifestId AS STRING),  '') <> IFNULL(CAST(Src.ManifestId AS STRING),  '')
         OR IFNULL(CAST(Tgt.Price AS STRING),        '') <> IFNULL(CAST(Src.Price AS STRING),        '')
         OR IFNULL(Tgt.FMSInvoiceNo,        '') <> IFNULL(Src.FMSInvoiceNo,        '')
         OR IFNULL(CAST(Tgt.ItemCount AS STRING),    '') <> IFNULL(CAST(Src.ItemCount AS STRING),    '')
         OR IFNULL(CAST(Tgt.CreatedOn AS STRING),    '') <> IFNULL(CAST(Src.CreatedOn AS STRING),    '')
         OR IFNULL(CAST(Tgt.DeadWeight AS STRING),   '') <> IFNULL(CAST(Src.DeadWeight AS STRING),   '')
         OR IFNULL(CAST(Tgt.CubicWeight AS STRING),  '') <> IFNULL(CAST(Src.CubicWeight AS STRING),  '')
         OR IFNULL(CAST(Tgt.LengthInCm AS STRING),   '') <> IFNULL(CAST(Src.LengthInCm AS STRING),   '')
         OR IFNULL(CAST(Tgt.WidthInCm AS STRING),    '') <> IFNULL(CAST(Src.WidthInCm AS STRING),    '')
         OR IFNULL(CAST(Tgt.HeightInCm AS STRING),   '') <> IFNULL(CAST(Src.HeightInCm AS STRING),   '')
         OR IFNULL(Tgt.LabelColour,         '') <> IFNULL(Src.LabelColour,         '')
         OR IFNULL(CAST(Tgt.ConsignmentItemId AS STRING), '') <> IFNULL(CAST(Src.ConsignmentItemId AS STRING), '')
        )
        THEN UPDATE SET
            IsCurrent = 0,
            ValidTo   = Loaded;

        SET Updated = @@ROW_COUNT;

        -- -----------------------------------------------------------------------
        -- STEP 2: Insert new rows for all unmatched source records (IsCurrent=1).
        -- Replicates MERGE WHEN NOT MATCHED BY TARGET ... THEN INSERT branch,
        -- plus the outer INSERT from the OUTPUT Src.* WHERE Action='UPDATE' branch.
        -- -----------------------------------------------------------------------
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_FLE`
        (
            LabelNo_HSK,
            LabelNo,
            CountryCode,
            Country,
            OESCustomerId,
            FMSCustomerID,
            ToContactName,
            ToAddress1,
            ToAddress2,
            ToSuburb,
            ToPostcode,
            ToPhone,
            ToEmail,
            PrintedOn,
            Reference,
            SpecialInstructions,
            DeliveryRF,
            ManifestId,
            Price,
            FMSInvoiceNo,
            ItemCount,
            CreatedOn,
            DeadWeight,
            CubicWeight,
            LengthInCm,
            WidthInCm,
            HeightInCm,
            LabelColour,
            ConsignmentItemId,
            Loaded,
            ProcessId,
            RecordSource,
            RecordSourceId,
            ValidFrom,
            ValidTo,
            IsCurrent
        )
        SELECT DISTINCT
            IFNULL(Sat.LabelNo_HSK, TO_HEX(MD5(Stg.LabelNumber))) AS LabelNo_HSK,
            Stg.LabelNumber         AS LabelNo,
            Stg.CountryId           AS CountryCode,
            IFNULL(cty.CountryName, 'Unknown') AS Country,
            Stg.WebCustomerId       AS OESCustomerId,
            Stg.CustomerId          AS FMSCustomerID,
            Stg.ReceiverContactName AS ToContactName,
            Stg.ReceiverAddress1    AS ToAddress1,
            Stg.ReceiverAddress2    AS ToAddress2,
            Stg.ReceiverSuburb      AS ToSuburb,
            Stg.ReceiverPostcode    AS ToPostcode,
            Stg.ReceiverPhone       AS ToPhone,
            Stg.ReceiverEmail       AS ToEmail,
            Stg.PrintedOn,
            Stg.Reference,
            Stg.SpecialInstructions,
            Stg.DestinationRF       AS DeliveryRF,
            Stg.ManifestId,
            Stg.Price,
            Stg.InvoiceNo           AS FMSInvoiceNo,
            Stg.ItemCount,
            Stg.CreatedOn,
            Stg.WeightDead          AS DeadWeight,
            Stg.WeightCubic         AS CubicWeight,
            Stg.Length              AS LengthInCm,
            Stg.Width               AS WidthInCm,
            Stg.Height              AS HeightInCm,
            Stg.Colour              AS LabelColour,
            Stg.ConsignmentItemId,
            Loaded                  AS Loaded,
            ProcessID               AS ProcessId,
            RecordSource,
            Stg.ConsignmentItemId   AS RecordSourceId,
            Loaded                  AS ValidFrom,
            DefaultValidTo          AS ValidTo,
            1                       AS IsCurrent
        FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_ConsignmentItem_Stg` Stg
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Country` cty ON cty.CountryCode = Stg.CountryId
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF` Sat ON Sat.LabelNo = Stg.LabelNumber
        WHERE NOT EXISTS (
            SELECT 1
            FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_FLE` AS Tgt
            WHERE Tgt.LabelNo_HSK = IFNULL(Sat.LabelNo_HSK, TO_HEX(MD5(Stg.LabelNumber)))
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
    -- Updated = rows with IsCurrent=0 for this ProcessID
    -- Inserted = rows with IsCurrent=1 for this ProcessID
    -- -----------------------------------------------------------------------
    SET Updated = (
        SELECT IFNULL(COUNTIF(IsCurrent = 0), 0)
        FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_FLE`
        WHERE ProcessId = ProcessID
    );
    SET Inserted = (
        SELECT IFNULL(COUNTIF(IsCurrent = 1), 0)
        FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_FLE`
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
