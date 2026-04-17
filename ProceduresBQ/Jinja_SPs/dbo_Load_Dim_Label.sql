-- ==========================================================================================
-- Routine:     dbo_Load_Dim_Label
-- Description: Loads/Updates Dim_Labels data from data vault tables
--              BigQuery compatible version of Load_Dim_Label
--              Note: Temp table (#LabelsToProcess) replaced with BQ TEMP TABLE.
--                    WHILE batch loops removed - BQ handles large DML natively.
--                    UPDATE ... FROM replaced with MERGE (BQ requires MERGE for UPDATE with JOIN).
--                    EXCEPT change detection preserved via explicit column comparisons in MERGE.
--                    WITH (TABLOCK) / WITH (INDEX ...) hints removed.
--                    IIF → IF. ISNULL → IFNULL. CONVERT(varchar,...) → CAST(... AS STRING).
--                    RAISERROR / WAITFOR DELAY removed.
--                    GOTO replaced with EXCEPTION block.
--                    BEGIN/COMMIT TRANSACTION removed.
--                    SYSDATETIME() → CURRENT_DATETIME().
--                    DATETIME2(3) → DATETIME.
--                    OBJECT_SCHEMA_NAME(@@PROCID) → hardcoded string.
--                    LEFT(str,2) → SUBSTR(str,1,2).
--                    Correlated subquery SELECT TOP 1 → pre-computed TEMP TABLE.
--                    Audit table format preserved exactly.
-- Example:     CALL dbo.dbo_Load_Dim_Label(123, '2019-08-01')
-- History:
--  27/05/2019  P. Waldron      Routine Written
--  27/06/2019  P. Waldron      Refactor to use SAT_Label_Distribution and SAT_Label_Allocation
--  09/07/2019  P. Waldron      Add Pickup/Delivery postcode and suburb
--  10/09/2019  P. Waldron      Add PickupCF and DeliveryCF columns
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dbo_Load_Dim_Label`(
    IN ProcessID    INT64,
    IN ChangedSince DATETIME
)
BEGIN

    DECLARE Loaded      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE DefaultDate DATETIME DEFAULT DATETIME '1900-01-01 00:00:00';

    DECLARE Component    STRING DEFAULT 'dbo.Load_Dim_Label';
    DECLARE Step         STRING;
    DECLARE Started      DATETIME;
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING DEFAULT 'Success';
    DECLARE ErrorMessage STRING DEFAULT '';
    DECLARE Inserted     INT64 DEFAULT 0;
    DECLARE Updated      INT64 DEFAULT 0;
    DECLARE MaxInsertId  INT64 DEFAULT 0;
    DECLARE MaxUpdateId  INT64 DEFAULT 0;

    -- -----------------------------------------------------------------------
    -- Step 1: Identify Labels to Process
    -- -----------------------------------------------------------------------
    SET Step    = 'Setup';
    SET Started = CURRENT_DATETIME();

    CREATE TEMP TABLE LabelsToProcess (
        LabelNo_HSK          BYTES,
        LabelNo              STRING,
        Pickup_Address_HSK   BYTES,
        Delivery_Address_HSK BYTES,
        UpdateId             INT64,
        InsertId             INT64
    );

    INSERT INTO LabelsToProcess (LabelNo_HSK, LabelNo, Pickup_Address_HSK, Delivery_Address_HSK, UpdateId, InsertId)
    SELECT
        sat.LabelNo_HSK,
        sat.LabelNo,
        lnk.Pickup_Address_HSK,
        lnk.Delivery_Address_HSK,
        IF(tgt.LabelNo IS NOT NULL, ROW_NUMBER() OVER(PARTITION BY IF(tgt.LabelNo IS NOT NULL, 1, NULL) ORDER BY sat.LabelNo), NULL) AS UpdateId,
        IF(tgt.LabelNo IS NULL, ROW_NUMBER() OVER(PARTITION BY IF(tgt.LabelNo IS NULL, 1, NULL) ORDER BY sat.LabelNo), NULL) AS InsertId
    FROM (
        SELECT LabelNo_HSK, LabelNo
        FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Distribution` d
        WHERE d.Loaded >= IFNULL(ChangedSince, DefaultDate) AND d.isCurrent = 1
        UNION DISTINCT
        SELECT LabelNo_HSK, LabelNo
        FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation` a
        WHERE a.Loaded >= IFNULL(ChangedSince, DefaultDate) AND a.isCurrent = 1
    ) sat
    LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Label` AS tgt
        ON tgt.LabelNo = sat.LabelNo
    LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_LNK_Label_Address` lnk
        ON lnk.LabelNo_HSK = sat.LabelNo_HSK;

    -- Pre-calculate Product Mapping to avoid correlated subquery errors
    CREATE TEMP TABLE LabelProductMapping AS
    WITH RawMatches AS (
        SELECT
            dist.LabelNo_HSK,
            prod.ProductId,
            ROW_NUMBER() OVER (PARTITION BY dist.LabelNo_HSK ORDER BY LENGTH(prod.ProductCode) DESC) AS rank
        FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Distribution` dist
        JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Product` prod
            ON dist.Country = prod.Country
            AND (prod.ProductCode = SUBSTR(dist.LabelNo, 1, 2) OR prod.ProductCode = SUBSTR(dist.LabelNo, 1, 1))
        INNER JOIN LabelsToProcess sel ON dist.LabelNo_HSK = sel.LabelNo_HSK
        WHERE dist.isCurrent = 1
    )
    SELECT LabelNo_HSK, ProductId FROM RawMatches WHERE rank = 1;

    SET (MaxInsertId, MaxUpdateId) = (SELECT AS STRUCT IFNULL(MAX(InsertId), 0), IFNULL(MAX(UpdateId), 0) FROM LabelsToProcess);

    SET Ended = CURRENT_DATETIME();
    CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
        Component || ' (Setup)',
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        MaxInsertId,
        MaxUpdateId,
        -1
    );

    -- -----------------------------------------------------------------------
    -- Step 2: MERGE (Update existing and Insert new)
    -- -----------------------------------------------------------------------
    SET Step    = 'Merge';
    SET Started = CURRENT_DATETIME();

    BEGIN
        MERGE `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Label` AS Tgt
        USING (
            WITH CombinedSats AS (
                SELECT
                    COALESCE(dist.LabelNo, alloc.LabelNo) AS LabelNo,
                    COALESCE(dist.CountryCode, alloc.CountryCode) AS CountryCode,
                    COALESCE(dist.Country, alloc.Country) AS Country,
                    alloc.PickupTown, alloc.PickupPostcode, alloc.DeliveryTown, alloc.DeliveryPostcode,
                    alloc.PickupRF, alloc.PickupCF, alloc.DeliveryRF, alloc.DeliveryCF,
                    dist.Electronic_CustomerType,
                    COALESCE(dist.Electronic_CustomerID, CAST(alloc.IFSCustomerCode AS STRING)) AS Electronic_CustomerID,
                    dist.Electronic_Reference, dist.FastLabel_ConsignmentID, dist.FastLabel_DestinationRF,
                    dist.Distribution_Date, dist.Distribution_FranchiseeCode,
                    COALESCE(dist.OESCustomerID, alloc.OESCustomerID) AS OESCustomerID,
                    COALESCE(dist.FMSCustomerID, alloc.FMSCustomerID) AS FMSCustomerID,
                    dist.FMSRfID, alloc.Reference, alloc.LabelColour, alloc.NumberOfParcels, alloc.Price,
                    COALESCE(alloc.CreateDateLocal, alloc.CreateDateUTC, dist.Distribution_Date) AS CreateDate,
                    alloc.DLSInvoiceID, alloc.FMSInvoiceID,
                    COALESCE(alloc.FMSProductID, dist.ProductId) AS FMSProductID,
                    alloc.FKSource, alloc.ParcelLength, alloc.ParcelWidth, alloc.ParcelHeight,
                    alloc.ParcelWeight, alloc.ParcelCubicWeight
                FROM (
                    SELECT d.*, m.ProductId
                    FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Distribution` d
                    INNER JOIN LabelsToProcess sel ON d.LabelNo_HSK = sel.LabelNo_HSK
                    LEFT JOIN LabelProductMapping m ON d.LabelNo_HSK = m.LabelNo_HSK
                    WHERE d.isCurrent = 1
                ) dist
                FULL OUTER JOIN (
                    SELECT al.*, p.Town AS PickupTown, p.Postcode AS PickupPostcode,
                           d.Town AS DeliveryTown, d.Postcode AS DeliveryPostcode
                    FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation` al
                    INNER JOIN LabelsToProcess sel ON al.LabelNo_HSK = sel.LabelNo_HSK
                    LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Address` p
                        ON p.Address_HSK = sel.Pickup_Address_HSK AND p.IsCurrent = 1
                    LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Address` d
                        ON d.Address_HSK = sel.Delivery_Address_HSK AND d.IsCurrent = 1
                    WHERE al.isCurrent = 1
                ) alloc ON dist.LabelNo_HSK = alloc.LabelNo_HSK
            )
            SELECT * FROM CombinedSats
            QUALIFY ROW_NUMBER() OVER(PARTITION BY LabelNo ORDER BY CreateDate DESC) = 1
        ) AS Src
        ON Tgt.LabelNo = Src.LabelNo

        WHEN MATCHED AND (
               IFNULL(CAST(Tgt.PickupTown              AS STRING), '') <> IFNULL(CAST(Src.PickupTown              AS STRING), '')
            OR IFNULL(CAST(Tgt.PickupPostcode          AS STRING), '') <> IFNULL(CAST(Src.PickupPostcode          AS STRING), '')
            OR IFNULL(CAST(Tgt.DeliveryTown            AS STRING), '') <> IFNULL(CAST(Src.DeliveryTown            AS STRING), '')
            OR IFNULL(CAST(Tgt.DeliveryPostcode        AS STRING), '') <> IFNULL(CAST(Src.DeliveryPostcode        AS STRING), '')
            OR IFNULL(CAST(Tgt.PickupRF                AS STRING), '') <> IFNULL(CAST(Src.PickupRF                AS STRING), '')
            OR IFNULL(CAST(Tgt.PickupCF                AS STRING), '') <> IFNULL(CAST(Src.PickupCF                AS STRING), '')
            OR IFNULL(CAST(Tgt.DeliveryRF              AS STRING), '') <> IFNULL(CAST(Src.DeliveryRF              AS STRING), '')
            OR IFNULL(CAST(Tgt.DeliveryCF              AS STRING), '') <> IFNULL(CAST(Src.DeliveryCF              AS STRING), '')
            OR IFNULL(CAST(Tgt.Electronic_CustomerType AS STRING), '') <> IFNULL(CAST(Src.Electronic_CustomerType AS STRING), '')
            OR IFNULL(CAST(Tgt.Electronic_CustomerID   AS STRING), '') <> IFNULL(CAST(Src.Electronic_CustomerID   AS STRING), '')
            OR IFNULL(CAST(Tgt.Electronic_Reference    AS STRING), '') <> IFNULL(CAST(Src.Electronic_Reference    AS STRING), '')
            OR IFNULL(CAST(Tgt.FastLabel_ConsignmentID AS STRING), '') <> IFNULL(CAST(Src.FastLabel_ConsignmentID AS STRING), '')
            OR IFNULL(CAST(Tgt.FastLabel_DestinationRF AS STRING), '') <> IFNULL(CAST(Src.FastLabel_DestinationRF AS STRING), '')
            OR IFNULL(CAST(Tgt.Distribution_Date       AS STRING), '') <> IFNULL(CAST(Src.Distribution_Date       AS STRING), '')
            OR IFNULL(CAST(Tgt.Distribution_FranchiseeCode AS STRING), '') <> IFNULL(CAST(Src.Distribution_FranchiseeCode AS STRING), '')
            OR IFNULL(CAST(Tgt.FKSource                AS STRING), '') <> IFNULL(CAST(Src.FKSource                AS STRING), '')
            OR IFNULL(CAST(Tgt.OESCustomerID           AS STRING), '') <> IFNULL(CAST(Src.OESCustomerID           AS STRING), '')
            OR IFNULL(CAST(Tgt.FMSCustomerID           AS STRING), '') <> IFNULL(CAST(Src.FMSCustomerID           AS STRING), '')
            OR IFNULL(CAST(Tgt.FMSRfID                 AS STRING), '') <> IFNULL(CAST(Src.FMSRfID                 AS STRING), '')
            OR IFNULL(CAST(Tgt.Reference               AS STRING), '') <> IFNULL(CAST(Src.Reference               AS STRING), '')
            OR IFNULL(CAST(Tgt.LabelColour             AS STRING), '') <> IFNULL(CAST(Src.LabelColour             AS STRING), '')
            OR IFNULL(CAST(Tgt.NumberOfParcels         AS STRING), '') <> IFNULL(CAST(Src.NumberOfParcels         AS STRING), '')
            OR IFNULL(CAST(Tgt.Price                   AS STRING), '') <> IFNULL(CAST(Src.Price                   AS STRING), '')
            OR IFNULL(CAST(Tgt.CreateDate              AS STRING), '') <> IFNULL(CAST(Src.CreateDate              AS STRING), '')
            OR IFNULL(CAST(Tgt.DLSInvoiceID            AS STRING), '') <> IFNULL(CAST(Src.DLSInvoiceID            AS STRING), '')
            OR IFNULL(CAST(Tgt.FMSInvoiceID            AS STRING), '') <> IFNULL(CAST(Src.FMSInvoiceID            AS STRING), '')
            OR IFNULL(CAST(Tgt.FMSProductID            AS STRING), '') <> IFNULL(CAST(Src.FMSProductID            AS STRING), '')
            OR IFNULL(CAST(Tgt.ParcelLength            AS STRING), '') <> IFNULL(CAST(Src.ParcelLength            AS STRING), '')
            OR IFNULL(CAST(Tgt.ParcelWidth             AS STRING), '') <> IFNULL(CAST(Src.ParcelWidth             AS STRING), '')
            OR IFNULL(CAST(Tgt.ParcelHeight            AS STRING), '') <> IFNULL(CAST(Src.ParcelHeight            AS STRING), '')
            OR IFNULL(CAST(Tgt.ParcelWeight            AS STRING), '') <> IFNULL(CAST(Src.ParcelWeight            AS STRING), '')
            OR IFNULL(CAST(Tgt.ParcelCubicWeight       AS STRING), '') <> IFNULL(CAST(Src.ParcelCubicWeight       AS STRING), '')
        )
        THEN UPDATE SET
            LabelNo                     = Src.LabelNo,
            CountryCode                 = Src.CountryCode,
            Country                     = Src.Country,
            PickupTown                  = Src.PickupTown,
            PickupPostcode              = Src.PickupPostcode,
            DeliveryTown                = Src.DeliveryTown,
            DeliveryPostcode            = Src.DeliveryPostcode,
            PickupRF                    = Src.PickupRF,
            PickupCF                    = Src.PickupCF,
            DeliveryRF                  = Src.DeliveryRF,
            DeliveryCF                  = Src.DeliveryCF,
            Electronic_CustomerType     = Src.Electronic_CustomerType,
            Electronic_CustomerID       = Src.Electronic_CustomerID,
            Electronic_Reference        = Src.Electronic_Reference,
            FastLabel_ConsignmentID     = Src.FastLabel_ConsignmentID,
            FastLabel_DestinationRF     = Src.FastLabel_DestinationRF,
            Distribution_Date           = Src.Distribution_Date,
            Distribution_FranchiseeCode = Src.Distribution_FranchiseeCode,
            FKSource                    = Src.FKSource,
            OESCustomerID               = Src.OESCustomerID,
            FMSCustomerID               = Src.FMSCustomerID,
            FMSRfID                     = Src.FMSRfID,
            Reference                   = Src.Reference,
            LabelColour                 = Src.LabelColour,
            Price                       = Src.Price,
            CreateDate                  = Src.CreateDate,
            DLSInvoiceID                = Src.DLSInvoiceID,
            FMSInvoiceID                = Src.FMSInvoiceID,
            FMSProductID                = Src.FMSProductID,
            ParcelLength                = Src.ParcelLength,
            ParcelWidth                 = Src.ParcelWidth,
            ParcelHeight                = Src.ParcelHeight,
            ParcelWeight                = Src.ParcelWeight,
            ParcelCubicWeight           = Src.ParcelCubicWeight,
            Updated                     = Loaded,
            ProcessId                   = ProcessID

        WHEN NOT MATCHED THEN
        INSERT (
            LabelNo, CountryCode, Country, PickupTown, PickupPostcode, DeliveryTown, DeliveryPostcode,
            PickupRF, PickupCF, DeliveryRF, DeliveryCF, Electronic_CustomerType, Electronic_CustomerID,
            Electronic_Reference, FastLabel_ConsignmentID, FastLabel_DestinationRF, Distribution_Date,
            Distribution_FranchiseeCode, FKSource, OESCustomerID, FMSCustomerID, FMSRfID, Reference,
            LabelColour, NumberOfParcels, Price, CreateDate, DLSInvoiceID, FMSInvoiceID, FMSProductID,
            ParcelLength, ParcelWidth, ParcelHeight, ParcelWeight, ParcelCubicWeight, LabelPrefix,
            Created, Updated, ProcessId
        )
        VALUES (
            Src.LabelNo, Src.CountryCode, Src.Country, Src.PickupTown, Src.PickupPostcode,
            Src.DeliveryTown, Src.DeliveryPostcode, Src.PickupRF, Src.PickupCF, Src.DeliveryRF,
            Src.DeliveryCF, Src.Electronic_CustomerType, Src.Electronic_CustomerID,
            Src.Electronic_Reference, Src.FastLabel_ConsignmentID, Src.FastLabel_DestinationRF,
            Src.Distribution_Date, Src.Distribution_FranchiseeCode, Src.FKSource,
            Src.OESCustomerID, Src.FMSCustomerID, Src.FMSRfID, Src.Reference,
            Src.LabelColour, Src.NumberOfParcels, Src.Price, Src.CreateDate,
            Src.DLSInvoiceID, Src.FMSInvoiceID, Src.FMSProductID,
            Src.ParcelLength, Src.ParcelWidth, Src.ParcelHeight, Src.ParcelWeight, Src.ParcelCubicWeight,
            SUBSTR(Src.LabelNo, 1, 2), Loaded, Loaded, ProcessID
        );

        -- Record counts for log
        SET Inserted = (SELECT COUNT(*) FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Label` WHERE Created = Loaded);
        SET Updated  = (SELECT COUNT(*) FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Label` WHERE Updated = Loaded AND Created <> Loaded);

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed';
        SET ErrorMessage = @@error.message;
    END;

    -- -----------------------------------------------------------------------
    -- Final Logging and cleanup
    -- -----------------------------------------------------------------------
    SET Ended = CURRENT_DATETIME();
    CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
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

    DROP TABLE IF EXISTS LabelsToProcess;
    DROP TABLE IF EXISTS LabelProductMapping;

END;