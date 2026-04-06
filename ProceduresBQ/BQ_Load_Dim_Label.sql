-- ==========================================================================================
-- Routine:     BQ_Load_Dim_Label
-- Description: Loads/Updates Dim_Labels data from data vault tables
--              BigQuery compatible version of dbo.Load_Dim_Label
--              Note:
--                - #LabelsToProcess temp table → BQ session temp table
--                - WHILE batch loops removed (BQ handles large inserts/updates natively)
--                - UPDATE ... FROM → MERGE (BQ requires MERGE for UPDATE with JOIN)
--                - EXIST(...EXCEPT...) change detection → column-by-column in MERGE condition
--                - WITH (TABLOCK) / WITH (INDEX(...)) removed
--                - WAITFOR DELAY removed (no equivalent in BQ procedures)
--                - GOTO RESULT → EXCEPTION block
--                - RAISERROR → removed
--                - CONVERT(varchar,x) → CAST(x AS STRING)
--                - IIF → IF
--                - ISNULL → IFNULL
--                - SYSDATETIME() → CURRENT_DATETIME()
--                - DATETIME2(3) → DATETIME
--                - Interim SaveLog calls per batch consolidated to one final call
--                - Audit table format preserved exactly.
-- Example:     CALL dbo.BQ_Load_Dim_Label(123, '2019-08-01')
--              CALL dbo.BQ_Load_Dim_Label(123, NULL)
-- History:
--  27/05/2019  P. Waldron      Routine Written
--  27/06/2019  P. Waldron      Refactor to use SAT_Label_Distribution and SAT_Label_Allocation
--  09/07/2019  P. Waldron      Add Pickup/Delivery postcode and suburb
--  10/09/2019  P. Waldron      Add PickupCF and DeliveryCF columns
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE dbo.BQ_Load_Dim_Label(
    IN ProcessID   INT64,
    IN ChangedSince DATETIME
)
BEGIN

    DECLARE Loaded      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE DefaultDate DATETIME DEFAULT DATETIME '1900-01-01 00:00:00';

    DECLARE Component    STRING DEFAULT 'dbo.Load_Dim_Label';
    DECLARE SubComponent STRING;
    DECLARE Step         STRING;
    DECLARE Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING DEFAULT 'Success';
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64 DEFAULT 0;
    DECLARE Updated      INT64 DEFAULT 0;

    /*
        Get list of LabelNos to Update or Insert rows on dbo.Dim_Label
    */
    SET Step    = 'Temp Table';
    SET Started = CURRENT_DATETIME();

    BEGIN

        -- #LabelsToProcess → BQ session temp table
        -- IIF → IF; ISNULL → IFNULL
        CREATE TEMP TABLE LabelsToProcess AS
        SELECT
            sat.LabelNo_HSK,
            sat.LabelNo,
            lnk.Pickup_Address_HSK,
            lnk.Delivery_Address_HSK,
            -- IF replaces IIF
            IF(tgt.LabelNo = sat.LabelNo,
               ROW_NUMBER() OVER(PARTITION BY IF(tgt.LabelNo = sat.LabelNo, 1, NULL) ORDER BY sat.LabelNo),
               NULL)                                                     AS UpdateId,
            IF(tgt.LabelNo IS NULL,
               ROW_NUMBER() OVER(PARTITION BY IF(tgt.LabelNo IS NULL, 1, NULL) ORDER BY sat.LabelNo),
               NULL)                                                     AS InsertId
        FROM dbo.Dim_Label AS tgt
        RIGHT JOIN (
            SELECT LabelNo_HSK, LabelNo
            FROM dv.SAT_Label_Distribution d
            -- ISNULL → IFNULL
            WHERE d.Loaded >= IFNULL(ChangedSince, DefaultDate) AND d.isCurrent = 1
            UNION DISTINCT
            SELECT LabelNo_HSK, LabelNo
            FROM dv.SAT_Label_Allocation a
            WHERE a.Loaded >= IFNULL(ChangedSince, DefaultDate) AND a.isCurrent = 1
        ) sat ON tgt.LabelNo = sat.LabelNo
        LEFT JOIN dv.LNK_Label_Address lnk ON lnk.LabelNo_HSK = sat.LabelNo_HSK;

        -- Record interim results
        SET Ended        = CURRENT_DATETIME();
        SET SubComponent = Component || ' (' || Step || ')';

        CALL Staging.SaveLog(
            SubComponent,
            ProcessID,
            Started,
            Ended,
            Result,
            ErrorMessage,
            (SELECT IFNULL(MAX(InsertId), 0) FROM LabelsToProcess),
            (SELECT IFNULL(MAX(UpdateId), 0) FROM LabelsToProcess)
        );

        /*
            Update existing Labels
            WHILE batch loop removed — BQ handles full-table MERGE natively.
            UPDATE...FROM replaced with MERGE.
            EXIST(...EXCEPT...) change detection → column-by-column comparison in MERGE condition.
        */
        SET Step    = 'Updates';
        SET Started = CURRENT_DATETIME();

        SET Loaded = CURRENT_DATETIME();

        MERGE dbo.Dim_Label AS Tgt
        USING (
            SELECT
                COALESCE(dist.LabelNo,  alloc.LabelNo)   AS LabelNo,
                COALESCE(dist.CountryCode, alloc.CountryCode) AS CountryCode,
                COALESCE(dist.Country,  alloc.Country)   AS Country,
                alloc.PickupTown,
                alloc.PickupPostcode,
                alloc.DeliveryTown,
                alloc.DeliveryPostcode,
                alloc.PickupRF,
                alloc.PickupCF,
                alloc.DeliveryRF,
                alloc.DeliveryCF,
                dist.Electronic_CustomerType,
                -- CONVERT(varchar,x) → CAST(x AS STRING)
                COALESCE(dist.Electronic_CustomerID, CAST(alloc.IFSCustomerCode AS STRING)) AS Electronic_CustomerID,
                dist.Electronic_Reference,
                dist.FastLabel_ConsignmentID,
                dist.FastLabel_DestinationRF,
                dist.Distribution_Date,
                dist.Distribution_FranchiseeCode,
                COALESCE(dist.OESCustomerID, alloc.OESCustomerID) AS OESCustomerID,
                COALESCE(dist.FMSCustomerID, alloc.FMSCustomerID) AS FMSCustomerID,
                dist.FMSRfID,
                alloc.Reference,
                alloc.LabelColour,
                alloc.NumberOfParcels,
                alloc.Price,
                COALESCE(alloc.CreateDateLocal, alloc.CreateDateUTC, dist.Distribution_Date) AS CreateDate,
                alloc.DLSInvoiceID,
                alloc.FMSInvoiceID,
                COALESCE(alloc.FMSProductID, dist.ProductId) AS FMSProductID,
                alloc.FKSource,
                alloc.ParcelLength,
                alloc.ParcelWidth,
                alloc.ParcelHeight,
                alloc.ParcelWeight,
                alloc.ParcelCubicWeight
            FROM (
                -- WITH (INDEX(...)) removed; BQ manages index access automatically
                SELECT dist.*,
                    (
                        SELECT ProductId FROM Dim_Product p
                        WHERE p.Country = dist.Country
                          AND (p.ProductCode = SUBSTR(dist.LabelNo, 1, 2) OR p.ProductCode = SUBSTR(dist.LabelNo, 1, 1))
                        ORDER BY LENGTH(ProductCode) DESC
                        LIMIT 1
                    ) AS ProductId
                FROM dv.SAT_Label_Distribution AS dist
                JOIN LabelsToProcess sel ON sel.LabelNo_HSK = dist.LabelNo_HSK
                WHERE dist.isCurrent = 1
                  AND sel.UpdateId IS NOT NULL
            ) dist
            FULL OUTER JOIN (
                SELECT al.*,
                    p.Town     AS PickupTown,
                    p.Postcode AS PickupPostcode,
                    d.Town     AS DeliveryTown,
                    d.Postcode AS DeliveryPostcode
                FROM dv.SAT_Label_Allocation AS al
                JOIN LabelsToProcess sel ON sel.LabelNo_HSK = al.LabelNo_HSK
                LEFT JOIN dv.SAT_Address p ON p.Address_HSK = sel.Pickup_Address_HSK   AND p.IsCurrent = 1
                LEFT JOIN dv.SAT_Address d ON d.Address_HSK = sel.Delivery_Address_HSK AND d.IsCurrent = 1
                WHERE al.isCurrent = 1
                  AND sel.UpdateId IS NOT NULL
            ) alloc
            ON dist.LabelNo_HSK = alloc.LabelNo_HSK
        ) AS Src
        ON Tgt.LabelNo = Src.LabelNo
        WHEN MATCHED AND (
            -- Column-by-column change detection replaces EXIST(...EXCEPT...) pattern
            IFNULL(Tgt.PickupTown,                       '') <> IFNULL(Src.PickupTown,                       '')
         OR IFNULL(Tgt.PickupPostcode,                   '') <> IFNULL(Src.PickupPostcode,                   '')
         OR IFNULL(Tgt.DeliveryTown,                     '') <> IFNULL(Src.DeliveryTown,                     '')
         OR IFNULL(Tgt.DeliveryPostcode,                 '') <> IFNULL(Src.DeliveryPostcode,                 '')
         OR IFNULL(Tgt.PickupRF,                         '') <> IFNULL(Src.PickupRF,                         '')
         OR IFNULL(Tgt.PickupCF,                         '') <> IFNULL(Src.PickupCF,                         '')
         OR IFNULL(Tgt.DeliveryRF,                       '') <> IFNULL(Src.DeliveryRF,                       '')
         OR IFNULL(Tgt.DeliveryCF,                       '') <> IFNULL(Src.DeliveryCF,                       '')
         OR IFNULL(Tgt.Electronic_CustomerType,           '') <> IFNULL(Src.Electronic_CustomerType,           '')
         OR IFNULL(Tgt.Electronic_CustomerID,             '') <> IFNULL(Src.Electronic_CustomerID,             '')
         OR IFNULL(Tgt.Electronic_Reference,              '') <> IFNULL(Src.Electronic_Reference,              '')
         OR IFNULL(CAST(Tgt.FastLabel_ConsignmentID AS STRING),'') <> IFNULL(CAST(Src.FastLabel_ConsignmentID AS STRING),'')
         OR IFNULL(Tgt.FastLabel_DestinationRF,           '') <> IFNULL(Src.FastLabel_DestinationRF,           '')
         OR IFNULL(CAST(Tgt.Distribution_Date AS STRING), '') <> IFNULL(CAST(Src.Distribution_Date AS STRING), '')
         OR IFNULL(Tgt.Distribution_FranchiseeCode,       '') <> IFNULL(Src.Distribution_FranchiseeCode,       '')
         OR IFNULL(Tgt.FKSource,                          '') <> IFNULL(Src.FKSource,                          '')
         OR IFNULL(CAST(Tgt.OESCustomerID AS STRING),     '') <> IFNULL(CAST(Src.OESCustomerID AS STRING),     '')
         OR IFNULL(CAST(Tgt.FMSCustomerID AS STRING),     '') <> IFNULL(CAST(Src.FMSCustomerID AS STRING),     '')
         OR IFNULL(Tgt.FMSRfID,                           '') <> IFNULL(Src.FMSRfID,                           '')
         OR IFNULL(Tgt.Reference,                         '') <> IFNULL(Src.Reference,                         '')
         OR IFNULL(Tgt.LabelColour,                       '') <> IFNULL(Src.LabelColour,                       '')
         OR IFNULL(CAST(Tgt.NumberOfParcels AS STRING),   '') <> IFNULL(CAST(Src.NumberOfParcels AS STRING),   '')
         OR IFNULL(CAST(Tgt.Price AS STRING),              '') <> IFNULL(CAST(Src.Price AS STRING),              '')
         OR IFNULL(CAST(Tgt.CreateDate AS STRING),         '') <> IFNULL(CAST(Src.CreateDate AS STRING),         '')
         OR IFNULL(CAST(Tgt.DLSInvoiceID AS STRING),      '') <> IFNULL(CAST(Src.DLSInvoiceID AS STRING),      '')
         OR IFNULL(CAST(Tgt.FMSInvoiceID AS STRING),      '') <> IFNULL(CAST(Src.FMSInvoiceID AS STRING),      '')
         OR IFNULL(CAST(Tgt.FMSProductID AS STRING),      '') <> IFNULL(CAST(Src.FMSProductID AS STRING),      '')
         OR IFNULL(CAST(Tgt.ParcelLength AS STRING),      '') <> IFNULL(CAST(Src.ParcelLength AS STRING),      '')
         OR IFNULL(CAST(Tgt.ParcelWidth AS STRING),       '') <> IFNULL(CAST(Src.ParcelWidth AS STRING),       '')
         OR IFNULL(CAST(Tgt.ParcelHeight AS STRING),      '') <> IFNULL(CAST(Src.ParcelHeight AS STRING),      '')
         OR IFNULL(CAST(Tgt.ParcelWeight AS STRING),      '') <> IFNULL(CAST(Src.ParcelWeight AS STRING),      '')
         OR IFNULL(CAST(Tgt.ParcelCubicWeight AS STRING), '') <> IFNULL(CAST(Src.ParcelCubicWeight AS STRING), '')
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
            ProcessId                   = ProcessID;

        SET Updated = @@ROW_COUNT;

        -- Interim SaveLog for Updates step
        SET Ended        = CURRENT_DATETIME();
        SET SubComponent = Component || ' (All Updates)';
        CALL Staging.SaveLog(SubComponent, ProcessID, Started, Ended, 'Success', ErrorMessage, Inserted, Updated);

        /*
            Insert new Labels
            WHILE batch loop removed — single INSERT handles full volume in BQ.
        */
        SET Step    = 'Inserts';
        SET Started = CURRENT_DATETIME();
        SET Loaded  = CURRENT_DATETIME();

        -- WITH (TABLOCK) removed
        INSERT INTO dbo.Dim_Label
        (
            LabelNo,
            CountryCode,
            Country,
            PickupTown,
            PickupPostcode,
            DeliveryTown,
            DeliveryPostcode,
            PickupRF,
            PickupCF,
            DeliveryRF,
            DeliveryCF,
            Electronic_CustomerType,
            Electronic_CustomerID,
            Electronic_Reference,
            FastLabel_ConsignmentID,
            FastLabel_DestinationRF,
            Distribution_Date,
            Distribution_FranchiseeCode,
            FKSource,
            OESCustomerID,
            FMSCustomerID,
            FMSRfID,
            Reference,
            LabelColour,
            NumberOfParcels,
            Price,
            CreateDate,
            DLSInvoiceID,
            FMSInvoiceID,
            FMSProductID,
            ParcelLength,
            ParcelWidth,
            ParcelHeight,
            ParcelWeight,
            ParcelCubicWeight,
            LabelPrefix,
            Created,
            Updated,
            ProcessId
        )
        SELECT
            Src.LabelNo,
            Src.CountryCode,
            Src.Country,
            Src.PickupTown,
            Src.PickupPostcode,
            Src.DeliveryTown,
            Src.DeliveryPostcode,
            Src.PickupRF,
            Src.PickupCF,
            Src.DeliveryRF,
            Src.DeliveryCF,
            Src.Electronic_CustomerType,
            Src.Electronic_CustomerID,
            Src.Electronic_Reference,
            Src.FastLabel_ConsignmentID,
            Src.FastLabel_DestinationRF,
            Src.Distribution_Date,
            Src.Distribution_FranchiseeCode,
            Src.FKSource,
            Src.OESCustomerID,
            Src.FMSCustomerID,
            Src.FMSRfID,
            Src.Reference,
            Src.LabelColour,
            Src.NumberOfParcels,
            Src.Price,
            Src.CreateDate,
            Src.DLSInvoiceID,
            Src.FMSInvoiceID,
            Src.FMSProductID,
            Src.ParcelLength,
            Src.ParcelWidth,
            Src.ParcelHeight,
            Src.ParcelWeight,
            Src.ParcelCubicWeight,
            SUBSTR(Src.LabelNo, 1, 2)  AS LabelPrefix,
            Loaded                     AS Created,
            Loaded                     AS Updated,
            ProcessID
        FROM (
            SELECT
                COALESCE(dist.LabelNo,  alloc.LabelNo)   AS LabelNo,
                COALESCE(dist.CountryCode, alloc.CountryCode) AS CountryCode,
                COALESCE(dist.Country,  alloc.Country)   AS Country,
                alloc.PickupTown,
                alloc.PickupPostcode,
                alloc.DeliveryTown,
                alloc.DeliveryPostcode,
                alloc.PickupRF,
                alloc.PickupCF,
                alloc.DeliveryRF,
                alloc.DeliveryCF,
                dist.Electronic_CustomerType,
                COALESCE(dist.Electronic_CustomerID, CAST(alloc.IFSCustomerCode AS STRING)) AS Electronic_CustomerID,
                dist.Electronic_Reference,
                dist.FastLabel_ConsignmentID,
                dist.FastLabel_DestinationRF,
                dist.Distribution_Date,
                dist.Distribution_FranchiseeCode,
                alloc.FKSource,
                COALESCE(dist.OESCustomerID, alloc.OESCustomerID) AS OESCustomerID,
                COALESCE(dist.FMSCustomerID, alloc.FMSCustomerID) AS FMSCustomerID,
                dist.FMSRfID,
                alloc.Reference,
                alloc.LabelColour,
                alloc.NumberOfParcels,
                alloc.Price,
                COALESCE(alloc.CreateDateLocal, alloc.CreateDateUTC, dist.Distribution_Date) AS CreateDate,
                alloc.DLSInvoiceID,
                alloc.FMSInvoiceID,
                alloc.FMSProductID,
                alloc.ParcelLength,
                alloc.ParcelWidth,
                alloc.ParcelHeight,
                alloc.ParcelWeight,
                alloc.ParcelCubicWeight
            FROM (
                SELECT dist.*
                FROM dv.SAT_Label_Distribution dist
                JOIN LabelsToProcess sel ON sel.LabelNo_HSK = dist.LabelNo_HSK
                WHERE sel.InsertId IS NOT NULL
                  AND dist.isCurrent = 1
            ) dist
            FULL OUTER JOIN (
                SELECT al.*,
                    p.Town     AS PickupTown,
                    p.Postcode AS PickupPostcode,
                    d.Town     AS DeliveryTown,
                    d.Postcode AS DeliveryPostcode
                FROM dv.SAT_Label_Allocation al
                JOIN LabelsToProcess sel ON sel.LabelNo_HSK = al.LabelNo_HSK
                LEFT JOIN dv.SAT_Address p ON p.Address_HSK = sel.Pickup_Address_HSK   AND p.IsCurrent = 1
                LEFT JOIN dv.SAT_Address d ON d.Address_HSK = sel.Delivery_Address_HSK AND d.IsCurrent = 1
                WHERE al.isCurrent = 1
                  AND sel.InsertId IS NOT NULL
            ) alloc
            ON dist.LabelNo_HSK = alloc.LabelNo_HSK
        ) Src
        ORDER BY Src.LabelNo;

        SET Inserted = @@ROW_COUNT;
        SET Result   = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed (' || Step || ')';
        SET ErrorMessage = @@error.message;

    END;

    /*
        Record load metrics in log — audit table format preserved exactly
    */
    SET Ended        = CURRENT_DATETIME();
    SET SubComponent = Component || ' (' || Step || ')';

    CALL Staging.SaveLog(
        SubComponent,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted,
        Updated
    );

    DROP TABLE IF EXISTS LabelsToProcess;

END;
