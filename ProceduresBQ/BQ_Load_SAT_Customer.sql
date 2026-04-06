-- ==========================================================================================
-- Routine:     BQ_Load_SAT_Customer
-- Description: Loads attributes into SAT_Customer
--              BigQuery compatible version of dv.Load_SAT_Customer
--              Note: MERGE with OUTPUT $action not supported in BQ.
--                    Replaced with:
--                      1. MERGE to expire changed current rows (IsCurrent=0, ValidTo=Loaded)
--                      2. INSERT new rows (IsCurrent=1)
--                    dbo.GetHashKey → TO_HEX(MD5(...))
--                    LTRIM(RTRIM(x)) → TRIM(x)
--                    SET NOCOUNT ON / SET ANSI_WARNINGS OFF removed
--                    GOTO RESULT restructured as EXCEPTION block
--                    PIVOT for audit counts → COUNTIF
--                    ROW_NUMBER() OVER(PARTITION BY ...) preserved (BQ supports window functions)
--                    Audit table format preserved exactly.
-- Example:     CALL dv.BQ_Load_SAT_Customer(736, 'FMS_Customer')
-- History:
--  04/12/2019  P. Waldron      Routine Written
--  09/09/2020  P. Waldron      Add 3 columns: ParentId, PriceListCode and XLabelCustomer
--  17/11/2020  B. Woods        Add 1 column: TaxNumber
--  21/01/2021  B. Woods        Add 2 columns: IndustryClassifcation, IndustryClassifcationOtherDes
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE dv.BQ_Load_SAT_Customer(
    IN ProcessID    INT64,
    IN RecordSource STRING
)
BEGIN

    DECLARE DefaultValidFrom DATETIME DEFAULT DATETIME '1900-01-01 00:00:00';
    DECLARE DefaultValidTo   DATETIME DEFAULT DATETIME '9999-12-31 00:00:00';
    DECLARE Loaded           DATETIME DEFAULT CURRENT_DATETIME();

    DECLARE Component    STRING DEFAULT 'dv.Load_SAT_Customer';
    DECLARE Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING;
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64 DEFAULT 0;
    DECLARE Updated      INT64 DEFAULT 0;

    BEGIN

        -- -----------------------------------------------------------------------
        -- STEP 1: Expire changed current rows (IsCurrent=0, ValidTo=Loaded)
        -- Replicates MERGE WHEN MATCHED AND EXISTS(... EXCEPT ...) THEN UPDATE
        -- -----------------------------------------------------------------------
        MERGE dv.SAT_Customer AS Tgt
        USING (
            SELECT
                Sat.Customer_HSK,
                Stg.CustomerKey,
                Stg.RFId                                        AS RFCode,
                Stg.CustomerNumber,
                Stg.CustomerID                                  AS FMSCustomerID,
                Stg.CourierNumber,
                Stg.Active,
                Stg.DeactiveDescription,
                Stg.EnterpriseFastLabelParentId                 AS ParentId,
                Stg.BusinessName                                AS CustomerName,
                Stg.TradingName,
                TRIM(Stg.StreetAddress1)                        AS StreetAddress1,
                TRIM(Stg.StreetAddress2)                        AS StreetAddress2,
                TRIM(Stg.StreetAddress3)                        AS StreetAddress3,
                TRIM(Stg.PostalAddress1)                        AS PostalAddress1,
                TRIM(Stg.PostalAddress2)                        AS PostalAddress2,
                TRIM(Stg.PostalAddress3)                        AS PostalAddress3,
                TRIM(Stg.PostCodeStreet)                        AS PostCodeStreet,
                TRIM(Stg.PostCodePostal)                        AS PostCodePostal,
                Stg.XLabelCustomer,
                Stg.PriceListCode,
                Stg.LastPurchDate,
                Stg.StartDate,
                Stg.B2B,
                Stg.B2C,
                TRIM(Stg.TaxNumber)                             AS TaxNumber,
                TRIM(Stg.IndustryClassification)               AS IndustryClassifcation,
                TRIM(Stg.IndustryDescription)                  AS IndustryDescription,
                TRIM(Stg.IndustryClassifcationOtherDes)        AS IndustryClassifcationOtherDes,
                Stg.xLabelAlcoholDeliveries
            FROM (
                SELECT
                    CustomerKey,
                    RFId,
                    CustomerNumber,
                    CustomerID,
                    CourierNumber,
                    Active,
                    DeactiveDescription,
                    BusinessName,
                    TradingName,
                    LegalEntity,
                    LegEntOtherDes,
                    ShortName,
                    EnterpriseFastLabelParentId,
                    StreetAddress1,
                    StreetAddress2,
                    StreetAddress3,
                    PostalAddress1,
                    PostalAddress2,
                    PostalAddress3,
                    PostCodeStreet,
                    PostCodePostal,
                    XLabelCustomer,
                    PriceListCode,
                    LastPurchDate,
                    StartDate,
                    B2B,
                    B2C,
                    TaxNumber,
                    IndustryClassification,
                    IndustryDescription,
                    IndustryClassifcationOtherDes,
                    xLabelAlcoholDeliveries,
                    -- ROW_NUMBER preserved (BQ supports window functions)
                    ROW_NUMBER() OVER(PARTITION BY CustomerKey ORDER BY Active DESC, StartDate DESC) AS CustRow
                FROM Staging.FMS_Customer_Stg
            ) Stg
            LEFT JOIN dv.SAT_Customer Sat
                ON  Sat.CustomerKey = Stg.CustomerKey
                AND Sat.isCurrent   = 1
            WHERE Stg.CustRow = 1
        ) AS Src
        ON  Tgt.Customer_HSK = Src.Customer_HSK
        AND Tgt.isCurrent    = 1
        WHEN MATCHED AND (
            -- Replicate EXCEPT change detection
            IFNULL(Tgt.CustomerKey,                     '') <> IFNULL(Src.CustomerKey,                     '')
         OR IFNULL(Tgt.RFCode,                          '') <> IFNULL(Src.RFCode,                          '')
         OR IFNULL(Tgt.CustomerNumber,                  '') <> IFNULL(Src.CustomerNumber,                  '')
         OR IFNULL(CAST(Tgt.FMSCustomerID AS STRING),   '') <> IFNULL(CAST(Src.FMSCustomerID AS STRING),   '')
         OR IFNULL(CAST(Tgt.CourierNumber AS STRING),   '') <> IFNULL(CAST(Src.CourierNumber AS STRING),   '')
         OR IFNULL(CAST(Tgt.Active AS STRING),          '') <> IFNULL(CAST(Src.Active AS STRING),          '')
         OR IFNULL(Tgt.DeactiveDescription,             '') <> IFNULL(Src.DeactiveDescription,             '')
         OR IFNULL(CAST(Tgt.ParentId AS STRING),        '') <> IFNULL(CAST(Src.ParentId AS STRING),        '')
         OR IFNULL(Tgt.CustomerName,                    '') <> IFNULL(Src.CustomerName,                    '')
         OR IFNULL(Tgt.TradingName,                     '') <> IFNULL(Src.TradingName,                     '')
         OR IFNULL(Tgt.StreetAddress1,                  '') <> IFNULL(Src.StreetAddress1,                  '')
         OR IFNULL(Tgt.StreetAddress2,                  '') <> IFNULL(Src.StreetAddress2,                  '')
         OR IFNULL(Tgt.StreetAddress3,                  '') <> IFNULL(Src.StreetAddress3,                  '')
         OR IFNULL(Tgt.PostalAddress1,                  '') <> IFNULL(Src.PostalAddress1,                  '')
         OR IFNULL(Tgt.PostalAddress2,                  '') <> IFNULL(Src.PostalAddress2,                  '')
         OR IFNULL(Tgt.PostalAddress3,                  '') <> IFNULL(Src.PostalAddress3,                  '')
         OR IFNULL(Tgt.PostCodeStreet,                  '') <> IFNULL(Src.PostCodeStreet,                  '')
         OR IFNULL(Tgt.PostCodePostal,                  '') <> IFNULL(Src.PostCodePostal,                  '')
         OR IFNULL(CAST(Tgt.XLabelCustomer AS STRING),  '') <> IFNULL(CAST(Src.XLabelCustomer AS STRING),  '')
         OR IFNULL(Tgt.PriceListCode,                   '') <> IFNULL(Src.PriceListCode,                   '')
         OR IFNULL(CAST(Tgt.LastPurchDate AS STRING),   '') <> IFNULL(CAST(Src.LastPurchDate AS STRING),   '')
         OR IFNULL(CAST(Tgt.StartDate AS STRING),       '') <> IFNULL(CAST(Src.StartDate AS STRING),       '')
         OR IFNULL(CAST(Tgt.B2B AS STRING),             '') <> IFNULL(CAST(Src.B2B AS STRING),             '')
         OR IFNULL(CAST(Tgt.B2C AS STRING),             '') <> IFNULL(CAST(Src.B2C AS STRING),             '')
         OR IFNULL(Tgt.TaxNumber,                       '') <> IFNULL(Src.TaxNumber,                       '')
         OR IFNULL(Tgt.IndustryClassifcation,           '') <> IFNULL(Src.IndustryClassifcation,           '')
         OR IFNULL(Tgt.IndustryDescription,             '') <> IFNULL(Src.IndustryDescription,             '')
         OR IFNULL(Tgt.IndustryClassifcationOtherDes,   '') <> IFNULL(Src.IndustryClassifcationOtherDes,   '')
         OR IFNULL(CAST(Tgt.xLabelAlcoholDeliveries AS STRING),'') <> IFNULL(CAST(Src.xLabelAlcoholDeliveries AS STRING),'')
        )
        THEN UPDATE SET
            IsCurrent = 0,
            ValidTo   = Loaded;

        SET Updated = @@ROW_COUNT;

        -- -----------------------------------------------------------------------
        -- STEP 2: Insert new rows (WHEN NOT MATCHED BY TARGET)
        -- -----------------------------------------------------------------------
        INSERT INTO dv.SAT_Customer
        (
            Customer_HSK,
            CustomerKey,
            RFCode,
            CustomerNumber,
            FMSCustomerID,
            CourierNumber,
            Active,
            DeactiveDescription,
            ParentId,
            CustomerName,
            TradingName,
            StreetAddress1,
            StreetAddress2,
            StreetAddress3,
            PostalAddress1,
            PostalAddress2,
            PostalAddress3,
            PostCodeStreet,
            PostCodePostal,
            XLabelCustomer,
            PriceListCode,
            LastPurchDate,
            StartDate,
            B2B,
            B2C,
            TaxNumber,
            IndustryClassifcation,
            IndustryDescription,
            IndustryClassifcationOtherDes,
            xLabelAlcoholDeliveries,
            Loaded,
            ProcessId,
            RecordSource,
            RecordSourceId,
            ValidFrom,
            ValidTo,
            IsCurrent
        )
        SELECT
            IFNULL(Sat.Customer_HSK, TO_HEX(MD5(Stg.CustomerKey))) AS Customer_HSK,
            Stg.CustomerKey,
            Stg.RFId                                        AS RFCode,
            Stg.CustomerNumber,
            Stg.CustomerID                                  AS FMSCustomerID,
            Stg.CourierNumber,
            Stg.Active,
            Stg.DeactiveDescription,
            Stg.EnterpriseFastLabelParentId                 AS ParentId,
            Stg.BusinessName                                AS CustomerName,
            Stg.TradingName,
            TRIM(Stg.StreetAddress1)                        AS StreetAddress1,
            TRIM(Stg.StreetAddress2)                        AS StreetAddress2,
            TRIM(Stg.StreetAddress3)                        AS StreetAddress3,
            TRIM(Stg.PostalAddress1)                        AS PostalAddress1,
            TRIM(Stg.PostalAddress2)                        AS PostalAddress2,
            TRIM(Stg.PostalAddress3)                        AS PostalAddress3,
            TRIM(Stg.PostCodeStreet)                        AS PostCodeStreet,
            TRIM(Stg.PostCodePostal)                        AS PostCodePostal,
            Stg.XLabelCustomer,
            Stg.PriceListCode,
            Stg.LastPurchDate,
            Stg.StartDate,
            Stg.B2B,
            Stg.B2C,
            TRIM(Stg.TaxNumber)                             AS TaxNumber,
            TRIM(Stg.IndustryClassification)               AS IndustryClassifcation,
            TRIM(Stg.IndustryDescription)                  AS IndustryDescription,
            TRIM(Stg.IndustryClassifcationOtherDes)        AS IndustryClassifcationOtherDes,
            Stg.xLabelAlcoholDeliveries,
            Loaded                                          AS Loaded,
            ProcessID                                       AS ProcessId,
            RecordSource,
            Stg.CustomerID                                  AS RecordSourceId,
            DefaultValidFrom                                AS ValidFrom,
            DefaultValidTo                                  AS ValidTo,
            1                                               AS IsCurrent
        FROM (
            SELECT *,
                ROW_NUMBER() OVER(PARTITION BY CustomerKey ORDER BY Active DESC, StartDate DESC) AS CustRow
            FROM Staging.FMS_Customer_Stg
        ) Stg
        LEFT JOIN dv.SAT_Customer Sat
            ON  Sat.CustomerKey = Stg.CustomerKey
            AND Sat.isCurrent   = 1
        WHERE Stg.CustRow = 1
          AND NOT EXISTS (
            SELECT 1
            FROM dv.SAT_Customer Tgt
            WHERE Tgt.Customer_HSK = IFNULL(Sat.Customer_HSK, TO_HEX(MD5(Stg.CustomerKey)))
              AND Tgt.isCurrent    = 1
        );

        SET Inserted = @@ROW_COUNT;
        SET Result   = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed';
        SET ErrorMessage = @@error.message;

    END;

    -- -----------------------------------------------------------------------
    -- Audit counts: replicate PIVOT(IsCurrent in [0],[1]) pattern
    -- Original queries SAT_Customer where ProcessId = @ProcessID
    -- -----------------------------------------------------------------------
    SET Updated = (
        SELECT IFNULL(COUNTIF(IsCurrent = 0), 0)
        FROM dv.SAT_Customer
        WHERE ProcessId = ProcessID
    );
    SET Inserted = (
        SELECT IFNULL(COUNTIF(IsCurrent = 1), 0)
        FROM dv.SAT_Customer
        WHERE ProcessId = ProcessID
    );

    SET Ended = CURRENT_DATETIME();
    CALL Staging.SaveLog(
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
