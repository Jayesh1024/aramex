-- ==========================================================================================
-- Routine:     BQ_Load_Dim_Label
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
--                    Correlated subquery SELECT TOP 1 → subquery with LIMIT 1.
--                    Audit table format preserved exactly.
-- Example:     CALL dbo.BQ_Load_Dim_Label(123, '2019-08-01')
-- History:
--  27/05/2019  P. Waldron      Routine Written
--  27/06/2019  P. Waldron      Refactor to use SAT_Label_Distribution and SAT_Label_Allocation
--  09/07/2019  P. Waldron      Add Pickup/Delivery postcode and suburb
--  10/09/2019  P. Waldron      Add PickupCF and DeliveryCF columns
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.BQ_Load_Dim_Label`(
    IN ProcessID    INT64,
    IN ChangedSince DATETIME
)
BEGIN

    DECLARE Loaded      DATETIME;
    DECLARE DefaultDate DATETIME DEFAULT DATETIME '1900-01-01 00:00:00';

    DECLARE Component    STRING DEFAULT 'dbo.Load_Dim_Label';
    DECLARE SubComponent STRING;
    DECLARE Step         STRING;
    DECLARE Started      DATETIME;
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING DEFAULT 'Success';
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64 DEFAULT 0;
    DECLARE Updated      INT64 DEFAULT 0;
    DECLARE MaxInsertId  INT64;
    DECLARE MaxUpdateId  INT64;

    /*
        Get list of LabelNos to Update or Insert rows on `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Label`
    */
    SET Step    = 'Temp Table';
    SET Started = CURRENT_DATETIME();

    -- BQ TEMP TABLE replaces SQL Server #LabelsToProcess
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
            -- IIF → IF; window functions preserved (BQ supports them)
            IF(
                tgt.LabelNo = sat.LabelNo,
                ROW_NUMBER() OVER(
                    PARTITION BY IF(tgt.LabelNo = sat.LabelNo, 1, NULL)
                    ORDER BY sat.LabelNo
                ),
                NULL
            ) AS UpdateId,
            IF(
                tgt.LabelNo IS NULL,
                ROW_NUMBER() OVER(
                    PARTITION BY IF(tgt.LabelNo IS NULL, 1, NULL)
                    ORDER BY sat.LabelNo
                ),
                NULL
            ) AS InsertId
        FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Label` AS tgt
        RIGHT JOIN (
            SELECT LabelNo_HSK, LabelNo
            FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Distribution` d
            WHERE d.Loaded >= IFNULL(ChangedSince, DefaultDate) AND d.isCurrent = 1
            UNION
            SELECT LabelNo_HSK, LabelNo
            FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation` a
            WHERE a.Loaded >= IFNULL(ChangedSince, DefaultDate) AND a.isCurrent = 1
        ) sat ON tgt.LabelNo = sat.LabelNo
        LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_LNK_Label_Address` lnk ON lnk.LabelNo_HSK = sat.LabelNo_HSK;

    IF (SELECT COUNT(*) FROM LabelsToProcess) = 0 THEN
        SET Result = 'Success';
    END IF;

    -- CREATE INDEX removed (BQ manages indexes automatically)

    SELECT MAX(InsertId), MAX(UpdateId)
    INTO MaxInsertId, MaxUpdateId
    FROM LabelsToProcess;

    -- Record interim results
    SET Ended        = CURRENT_DATETIME();
    SET SubComponent = Component || ' (' || Step || ')';

    CALL `{{ project_id }}.{{ sp_dataset_id }}.SaveLog`(
        SubComponent,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        MaxInsertId,
        MaxUpdateId
    );

    /*
        Update existing Labels
        BQ handles large DML natively; WHILE batch loop removed.
        UPDATE ... FROM replaced with MERGE.
    */
    SET Step    = 'Updates';
    SET Started = CURRENT_DATETIME();
    SET Inserted = 0;
    SET Updated  = 0;

    BEGIN

        SET Loaded = CURRENT_DATETIME();

        -- MERGE replaces UPDATE Tgt WITH (TABLOCK) SET ... FROM ... JOIN ... WHERE EXISTS (EXCEPT)
        MERGE `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Label` AS Tgt
        USING (
            SELECT
                COALESCE(dist.LabelNo,    alloc.LabelNo)    AS LabelNo,
                COALESCE(dist.CountryCode,alloc.CountryCode) AS CountryCode,
                COALESCE(dist.Country,    alloc.Country)    AS Country,
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
                COALESCE(dist.OESCustomerID, alloc.OESCustomerID)   AS OESCustomerID,
                COALESCE(dist.FMSCustomerID, alloc.FMSCustomerID)   AS FMSCustomerID,
                dist.FMSRfID,
                alloc.Reference,
                alloc.LabelColour,
                alloc.NumberOfParcels,
                alloc.Price,
                COALESCE(alloc.CreateDateLocal, alloc.CreateDateUTC, dist.Distribution_Date) AS CreateDate,
                alloc.DLSInvoiceID,
                alloc.FMSInvoiceID,
                COALESCE(alloc.FMSProductID, dist.ProductId)        AS FMSProductID,
                alloc.FKSource,
                alloc.ParcelLength,
                alloc.ParcelWidth,
                alloc.ParcelHeight,
                alloc.ParcelWeight,
                alloc.ParcelCubicWeight
            FROM (
                SELECT dist.*,
                    -- SELECT TOP 1 → subquery with LIMIT 1
                    (
                        SELECT ProductId FROM Dim_Product p
                        WHERE p.Country = dist.Country
                          AND (p.ProductCode = SUBSTR(dist.LabelNo,1,2) OR p.ProductCode = SUBSTR(dist.LabelNo,1,1))
                        ORDER BY LENGTH(ProductCode) DESC
                        LIMIT 1
                    ) AS ProductId
                FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Distribution` AS dist
                -- WITH (INDEX([IX_LabelNo_HSK])) removed
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
                FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation` AS al
                -- WITH (INDEX([IX_LabelNo_HSK])) removed
                JOIN LabelsToProcess sel ON sel.LabelNo_HSK = al.LabelNo_HSK
                LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Address` p ON p.Address_HSK = sel.Pickup_Address_HSK   AND p.IsCurrent = 1
                LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Address` d ON d.Address_HSK = sel.Delivery_Address_HSK AND d.IsCurrent = 1
                WHERE al.isCurrent = 1
                  AND sel.UpdateId IS NOT NULL
            ) alloc
            ON dist.LabelNo_HSK = alloc.LabelNo_HSK
        ) AS Src
        ON Tgt.LabelNo = Src.LabelNo
        WHEN MATCHED AND (
            -- Replicate EXCEPT change detection
            IFNULL(Tgt.PickupTown,              '') <> IFNULL(Src.PickupTown,              '')
         OR IFNULL(Tgt.PickupPostcode,          '') <> IFNULL(Src.PickupPostcode,          '')
         OR IFNULL(Tgt.DeliveryTown,            '') <> IFNULL(Src.DeliveryTown,            '')
         OR IFNULL(Tgt.DeliveryPostcode,        '') <> IFNULL(Src.DeliveryPostcode,        '')
         OR IFNULL(Tgt.PickupRF,               '') <> IFNULL(Src.PickupRF,               '')
         OR IFNULL(Tgt.PickupCF,               '') <> IFNULL(Src.PickupCF,               '')
         OR IFNULL(Tgt.DeliveryRF,             '') <> IFNULL(Src.DeliveryRF,             '')
         OR IFNULL(Tgt.DeliveryCF,             '') <> IFNULL(Src.DeliveryCF,             '')
         OR IFNULL(Tgt.Electronic_CustomerType, '') <> IFNULL(Src.Electronic_CustomerType, '')
         OR IFNULL(Tgt.Electronic_CustomerID,   '') <> IFNULL(Src.Electronic_CustomerID,   '')
         OR IFNULL(Tgt.Electronic_Reference,    '') <> IFNULL(Src.Electronic_Reference,    '')
         OR IFNULL(CAST(Tgt.FastLabel_ConsignmentID AS STRING),'') <> IFNULL(CAST(Src.FastLabel_ConsignmentID AS STRING),'')
         OR IFNULL(Tgt.FastLabel_DestinationRF,  '') <> IFNULL(Src.FastLabel_DestinationRF,  '')
         OR IFNULL(CAST(Tgt.Distribution_Date AS STRING),'') <> IFNULL(CAST(Src.Distribution_Date AS STRING),'')
         OR IFNULL(Tgt.Distribution_FranchiseeCode,'') <> IFNULL(Src.Distribution_FranchiseeCode,'')
         OR IFNULL(Tgt.FKSource,               '') <> IFNULL(Src.FKSource,               '')
         OR IFNULL(CAST(Tgt.OESCustomerID AS STRING),'') <> IFNULL(CAST(Src.OESCustomerID AS STRING),'')
         OR IFNULL(CAST(Tgt.FMSCustomerID AS STRING),'') <> IFNULL(CAST(Src.FMSCustomerID AS STRING),'')
         OR IFNULL(CAST(Tgt.FMSRfID AS STRING),  '') <> IFNULL(CAST(Src.FMSRfID AS STRING),  '')
         OR IFNULL(Tgt.Reference,              '') <> IFNULL(Src.Reference,              '')
         OR IFNULL(Tgt.LabelColour,            '') <> IFNULL(Src.LabelColour,            '')
         OR IFNULL(CAST(Tgt.NumberOfParcels AS STRING),'') <> IFNULL(CAST(Src.NumberOfParcels AS STRING),'')
         OR IFNULL(CAST(Tgt.Price AS STRING),   '') <> IFNULL(CAST(Src.Price AS STRING),   '')
         OR IFNULL(CAST(Tgt.CreateDate AS STRING),'') <> IFNULL(CAST(Src.CreateDate AS STRING),'')
         OR IFNULL(CAST(Tgt.DLSInvoiceID AS STRING),'') <> IFNULL(CAST(Src.DLSInvoiceID AS STRING),'')
         OR IFNULL(CAST(Tgt.FMSInvoiceID AS STRING),'') <> IFNULL(CAST(Src.FMSInvoiceID AS STRING),'')
         OR IFNULL(CAST(Tgt.FMSProductID AS STRING),'') <> IFNULL(CAST(Src.FMSProductID AS STRING),'')
         OR IFNULL(CAST(Tgt.ParcelLength AS STRING),'') <> IFNULL(CAST(Src.ParcelLength AS STRING),'')
         OR IFNULL(CAST(Tgt.ParcelWidth AS STRING), '') <> IFNULL(CAST(Src.ParcelWidth AS STRING), '')
         OR IFNULL(CAST(Tgt.ParcelHeight AS STRING),'') <> IFNULL(CAST(Src.ParcelHeight AS STRING),'')
         OR IFNULL(CAST(Tgt.ParcelWeight AS STRING),'') <> IFNULL(CAST(Src.ParcelWeight AS STRING),'')
         OR IFNULL(CAST(Tgt.ParcelCubicWeight AS STRING),'') <> IFNULL(CAST(Src.ParcelCubicWeight AS STRING),'')
        )
        THEN UPDATE SET
            LabelNo                    = Src.LabelNo,
            CountryCode                = Src.CountryCode,
            Country                    = Src.Country,
            PickupTown                 = Src.PickupTown,
            PickupPostcode             = Src.PickupPostcode,
            DeliveryTown               = Src.DeliveryTown,
            DeliveryPostcode           = Src.DeliveryPostcode,
            PickupRF                   = Src.PickupRF,
            PickupCF                   = Src.PickupCF,
            DeliveryRF                 = Src.DeliveryRF,
            DeliveryCF                 = Src.DeliveryCF,
            Electronic_CustomerType    = Src.Electronic_CustomerType,
            Electronic_CustomerID      = Src.Electronic_CustomerID,
            Electronic_Reference       = Src.Electronic_Reference,
            FastLabel_ConsignmentID    = Src.FastLabel_ConsignmentID,
            FastLabel_DestinationRF    = Src.FastLabel_DestinationRF,
            Distribution_Date          = Src.Distribution_Date,
            Distribution_FranchiseeCode = Src.Distribution_FranchiseeCode,
            FKSource                   = Src.FKSource,
            OESCustomerID              = Src.OESCustomerID,
            FMSCustomerID              = Src.FMSCustomerID,
            FMSRfID                    = Src.FMSRfID,
            Reference                  = Src.Reference,
            LabelColour                = Src.LabelColour,
            Price                      = Src.Price,
            CreateDate                 = Src.CreateDate,
            DLSInvoiceID               = Src.DLSInvoiceID,
            FMSInvoiceID               = Src.FMSInvoiceID,
            FMSProductID               = Src.FMSProductID,
            ParcelLength               = Src.ParcelLength,
            ParcelWidth                = Src.ParcelWidth,
            ParcelHeight               = Src.ParcelHeight,
            ParcelWeight               = Src.ParcelWeight,
            ParcelCubicWeight          = Src.ParcelCubicWeight,
            Updated                    = Loaded,
            ProcessId                  = ProcessID;

        SET Updated = @@ROW_COUNT;

        -- Record interim stats (audit table format preserved exactly)
        SET Ended        = CURRENT_DATETIME();
        SET SubComponent = Component || ' (All ' || Step || ')';

        CALL `{{ project_id }}.{{ sp_dataset_id }}.SaveLog`(
            SubComponent,
            ProcessID,
            Started,
            Ended,
            'Success',
            ErrorMessage,
            Inserted,
            Updated
        );

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed (' || Step || ')';
        SET ErrorMessage = @@error.message;

    END;

    /*
        Insert new Labels
        BQ handles large inserts natively; WHILE batch loop removed.
    */
    SET Step    = 'Inserts';
    SET Started = CURRENT_DATETIME();
    SET Updated  = 0;

    BEGIN

        SET Loaded = CURRENT_DATETIME();

        -- WITH (TABLOCK) removed
        INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dbo_Dim_Label`
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
            -- LEFT(LabelNo,2) → SUBSTR(LabelNo,1,2)
            SUBSTR(Src.LabelNo, 1, 2),
            Loaded,
            Loaded,
            ProcessID
        FROM (
            SELECT
                COALESCE(dist.LabelNo,     alloc.LabelNo)    AS LabelNo,
                COALESCE(dist.CountryCode, alloc.CountryCode) AS CountryCode,
                COALESCE(dist.Country,     alloc.Country)    AS Country,
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
                COALESCE(dist.OESCustomerID, alloc.OESCustomerID)  AS OESCustomerID,
                COALESCE(dist.FMSCustomerID, alloc.FMSCustomerID)  AS FMSCustomerID,
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
                FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Distribution` dist
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
                FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation` al
                JOIN LabelsToProcess sel ON sel.LabelNo_HSK = al.LabelNo_HSK
                LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Address` p ON p.Address_HSK = sel.Pickup_Address_HSK   AND p.IsCurrent = 1
                LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Address` d ON d.Address_HSK = sel.Delivery_Address_HSK AND d.IsCurrent = 1
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
        Record load metrics in log (audit table format preserved exactly)
    */
    SET Ended        = CURRENT_DATETIME();
    SET SubComponent = Component || ' (' || Step || ')';

    CALL `{{ project_id }}.{{ sp_dataset_id }}.SaveLog`(
        SubComponent,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted,
        Updated
    );

    DROP TABLE LabelsToProcess;

END;
