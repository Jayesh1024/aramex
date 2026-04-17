-- ==========================================================================================
-- Routine:     dv_Load_SAT_Customer
-- Description: Loads attributes into SAT_Customer
--              BigQuery compatible version of Load_SAT_Customer
-- Example:     CALL dv.dv_Load_SAT_Customer(736, 'FMS_Customer')
-- History:
--  04/12/2019  P. Waldron      Routine Written
--  09/09/2020  P. Waldron      Add 3 columns: ParentId, PriceListCode and XLabelCustomer
--  17/11/2020  B. Woods        Add 1 column: TaxNumber
--  21/01/2021  B. Woods        Add 2 columns: IndustryClassifcation, IndustryClassifcationOtherDes
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_SAT_Customer`(
    IN p_ProcessID    INT64,
    IN p_RecordSource STRING
)
BEGIN

    -- Use v_ prefix to distinguish Variables from Column names
    DECLARE v_DefaultValidFrom DATETIME DEFAULT DATETIME '1900-01-01 00:00:00';
    DECLARE v_DefaultValidTo   DATETIME DEFAULT DATETIME '9999-12-31 00:00:00';
    DECLARE v_Loaded           DATETIME DEFAULT CURRENT_DATETIME();

    DECLARE v_Component    STRING DEFAULT 'dv.Load_SAT_Customer';
    DECLARE v_Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Ended        DATETIME;
    DECLARE v_Result       STRING;
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted     INT64;
    DECLARE v_Updated      INT64;

    -- SET NOCOUNT ON removed. SET ANSI_WARNINGS OFF removed.
    -- MERGE with OUTPUT $action not supported in BQ.
    -- Replaced with:
    --   STEP 1: MERGE to expire changed current rows (IsCurrent=0, ValidTo=v_Loaded)
    --   STEP 2: INSERT new rows (IsCurrent=1)
    -- dbo.GetHashKey → MD5(CAST(... AS STRING)) returning BYTES directly.
    -- LTRIM(RTRIM(x)) → TRIM(x).
    -- ROW_NUMBER() OVER(...) preserved (BQ supports it).
    -- PIVOT for audit counts → COUNTIF.
    -- BEGIN TRANSACTION / COMMIT / ROLLBACK removed.
    -- v_ prefix on all variables to avoid ambiguity with column names.

    BEGIN

        -- -----------------------------------------------------------------------
        -- STEP 1: Expire changed current rows (IsCurrent=0, ValidTo=v_Loaded)
        -- -----------------------------------------------------------------------
        MERGE `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Customer` AS Tgt
        USING (
            SELECT
                Sat.Customer_HSK,
                Stg.*
            FROM (
                SELECT
                    CustomerKey, RFId, CustomerNumber, CustomerID, CourierNumber,
                    Active, DeactiveDescription, BusinessName, TradingName,
                    LegalEntity, LegEntOtherDes, ShortName,
                    EnterpriseFastLabelParentId,
                    StreetAddress1, StreetAddress2, StreetAddress3,
                    PostalAddress1, PostalAddress2, PostalAddress3,
                    PostCodeStreet, PostCodePostal,
                    XLabelCustomer, PriceListCode, LastPurchDate, StartDate,
                    B2B, B2C, TaxNumber,
                    IndustryClassification, IndustryDescription, IndustryClassifcationOtherDes,
                    xLabelAlcoholDeliveries,
                    -- ROW_NUMBER preserved (BQ supports OVER/PARTITION BY)
                    ROW_NUMBER() OVER(PARTITION BY CustomerKey ORDER BY Active DESC, StartDate DESC) AS CustRow
                FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_FMS_Customer_Stg`
            ) Stg
            LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Customer` Sat
                ON Sat.CustomerKey = Stg.CustomerKey AND Sat.isCurrent = 1
            WHERE Stg.CustRow = 1
        ) AS Src
        ON  Tgt.Customer_HSK = Src.Customer_HSK
        AND Tgt.isCurrent    = 1
        -- EXCEPT change-detection replaced with uniform CAST(... AS STRING) IFNULL comparisons
        WHEN MATCHED AND (
            IFNULL(CAST(Tgt.CustomerKey                      AS STRING), '') <> IFNULL(CAST(Src.CustomerKey                      AS STRING), '')
         OR IFNULL(CAST(Tgt.RFCode                           AS STRING), '') <> IFNULL(CAST(Src.RFId                             AS STRING), '')
         OR IFNULL(CAST(Tgt.CustomerNumber                   AS STRING), '') <> IFNULL(CAST(Src.CustomerNumber                   AS STRING), '')
         OR IFNULL(CAST(Tgt.FMSCustomerID                    AS STRING), '') <> IFNULL(CAST(Src.CustomerID                       AS STRING), '')
         OR IFNULL(CAST(Tgt.CourierNumber                    AS STRING), '') <> IFNULL(CAST(Src.CourierNumber                     AS STRING), '')
         OR IFNULL(CAST(Tgt.Active                           AS STRING), '') <> IFNULL(CAST(Src.Active                           AS STRING), '')
         OR IFNULL(CAST(Tgt.DeactiveDescription              AS STRING), '') <> IFNULL(CAST(Src.DeactiveDescription              AS STRING), '')
         OR IFNULL(CAST(Tgt.ParentId                         AS STRING), '') <> IFNULL(CAST(Src.EnterpriseFastLabelParentId      AS STRING), '')
         OR IFNULL(CAST(Tgt.CustomerName                     AS STRING), '') <> IFNULL(CAST(Src.BusinessName                     AS STRING), '')
         OR IFNULL(CAST(Tgt.TradingName                      AS STRING), '') <> IFNULL(CAST(Src.TradingName                      AS STRING), '')
         OR IFNULL(CAST(Tgt.StreetAddress1                   AS STRING), '') <> IFNULL(CAST(Src.StreetAddress1                   AS STRING), '')
         OR IFNULL(CAST(Tgt.StreetAddress2                   AS STRING), '') <> IFNULL(CAST(Src.StreetAddress2                   AS STRING), '')
         OR IFNULL(CAST(Tgt.StreetAddress3                   AS STRING), '') <> IFNULL(CAST(Src.StreetAddress3                   AS STRING), '')
         OR IFNULL(CAST(Tgt.PostalAddress1                   AS STRING), '') <> IFNULL(CAST(Src.PostalAddress1                   AS STRING), '')
         OR IFNULL(CAST(Tgt.PostalAddress2                   AS STRING), '') <> IFNULL(CAST(Src.PostalAddress2                   AS STRING), '')
         OR IFNULL(CAST(Tgt.PostalAddress3                   AS STRING), '') <> IFNULL(CAST(Src.PostalAddress3                   AS STRING), '')
         OR IFNULL(CAST(Tgt.PostCodeStreet                   AS STRING), '') <> IFNULL(CAST(Src.PostCodeStreet                   AS STRING), '')
         OR IFNULL(CAST(Tgt.PostCodePostal                   AS STRING), '') <> IFNULL(CAST(Src.PostCodePostal                   AS STRING), '')
         OR IFNULL(CAST(Tgt.XLabelCustomer                   AS STRING), '') <> IFNULL(CAST(Src.XLabelCustomer                   AS STRING), '')
         OR IFNULL(CAST(Tgt.PriceListCode                    AS STRING), '') <> IFNULL(CAST(Src.PriceListCode                    AS STRING), '')
         OR IFNULL(CAST(Tgt.LastPurchDate                    AS STRING), '') <> IFNULL(CAST(Src.LastPurchDate                    AS STRING), '')
         OR IFNULL(CAST(Tgt.StartDate                        AS STRING), '') <> IFNULL(CAST(Src.StartDate                        AS STRING), '')
         OR IFNULL(CAST(Tgt.B2B                              AS STRING), '') <> IFNULL(CAST(Src.B2B                              AS STRING), '')
         OR IFNULL(CAST(Tgt.B2C                              AS STRING), '') <> IFNULL(CAST(Src.B2C                              AS STRING), '')
         OR IFNULL(CAST(Tgt.TaxNumber                        AS STRING), '') <> IFNULL(CAST(Src.TaxNumber                        AS STRING), '')
         OR IFNULL(CAST(Tgt.IndustryClassifcation            AS STRING), '') <> IFNULL(CAST(Src.IndustryClassification           AS STRING), '')
         OR IFNULL(CAST(Tgt.IndustryDescription              AS STRING), '') <> IFNULL(CAST(Src.IndustryDescription              AS STRING), '')
         OR IFNULL(CAST(Tgt.IndustryClassifcationOtherDes    AS STRING), '') <> IFNULL(CAST(Src.IndustryClassifcationOtherDes    AS STRING), '')
         OR IFNULL(CAST(Tgt.xLabelAlcoholDeliveries          AS STRING), '') <> IFNULL(CAST(Src.xLabelAlcoholDeliveries          AS STRING), '')
        )
        THEN UPDATE SET
            IsCurrent = 0,
            ValidTo   = v_Loaded;

        -- -----------------------------------------------------------------------
        -- STEP 2: Insert new rows for unmatched source records (IsCurrent=1)
        -- -----------------------------------------------------------------------
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Customer`
        (
            Customer_HSK, CustomerKey, RFCode, CustomerNumber, FMSCustomerID,
            CourierNumber, Active, DeactiveDescription, ParentId,
            CustomerName, TradingName,
            StreetAddress1, StreetAddress2, StreetAddress3,
            PostalAddress1, PostalAddress2, PostalAddress3,
            PostCodeStreet, PostCodePostal,
            XLabelCustomer, PriceListCode, LastPurchDate, StartDate, B2B, B2C,
            TaxNumber, IndustryClassifcation, IndustryDescription, IndustryClassifcationOtherDes,
            xLabelAlcoholDeliveries,
            Loaded, ProcessId, RecordSource, RecordSourceId,
            ValidFrom, ValidTo, IsCurrent
        )
        SELECT
            -- MD5 returns BYTES directly (no TO_HEX needed)
            IFNULL(Sat.Customer_HSK, MD5(CAST(Stg.CustomerKey AS STRING))) AS Customer_HSK,
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
            TRIM(Stg.StreetAddress1), TRIM(Stg.StreetAddress2), TRIM(Stg.StreetAddress3),
            TRIM(Stg.PostalAddress1), TRIM(Stg.PostalAddress2), TRIM(Stg.PostalAddress3),
            TRIM(Stg.PostCodeStreet), TRIM(Stg.PostCodePostal),
            Stg.XLabelCustomer, Stg.PriceListCode,
            Stg.LastPurchDate, Stg.StartDate,
            Stg.B2B, Stg.B2C,
            TRIM(Stg.TaxNumber),
            TRIM(Stg.IndustryClassification),
            TRIM(Stg.IndustryDescription),
            TRIM(Stg.IndustryClassifcationOtherDes),
            Stg.xLabelAlcoholDeliveries,
            v_Loaded, p_ProcessID, p_RecordSource,
            Stg.CustomerID                                  AS RecordSourceId,
            v_DefaultValidFrom, v_DefaultValidTo, 1         AS IsCurrent
        FROM (
            SELECT *, ROW_NUMBER() OVER(PARTITION BY CustomerKey ORDER BY Active DESC, StartDate DESC) AS CustRow
            FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_FMS_Customer_Stg`
        ) Stg
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Customer` Sat
            ON Sat.CustomerKey = Stg.CustomerKey AND Sat.isCurrent = 1
        WHERE Stg.CustRow = 1
          AND NOT EXISTS (
            SELECT 1 FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Customer` Tgt
            WHERE Tgt.Customer_HSK = IFNULL(Sat.Customer_HSK, MD5(CAST(Stg.CustomerKey AS STRING)))
              AND Tgt.isCurrent    = 1
        );

        SET v_Result = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET v_Result       = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    /*
        Record load metrics in log — audit table format preserved exactly
        PIVOT(IsCurrent in [0],[1]) → COUNTIF
    */
    SET v_Updated = (
        SELECT IFNULL(COUNTIF(IsCurrent = 0 AND ProcessId = p_ProcessID), 0)
        FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Customer`
    );
    SET v_Inserted = (
        SELECT IFNULL(COUNTIF(IsCurrent = 1 AND ProcessId = p_ProcessID), 0)
        FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Customer`
    );

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