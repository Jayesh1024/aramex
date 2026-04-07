-- ==========================================================================================
-- Routine:     BQ_Load_SAT_Label_Allocation_Stg
-- Description: Loads attributes into SAT_Label_Allocation from 9x staging tables
--              BigQuery compatible version of Load_SAT_Label_Allocation_Stg
--              Note: #Stg_Label temp table replaced with BQ TEMP TABLE.
--                    CREATE CLUSTERED INDEX removed (BQ manages indexes automatically).
--                    WITH (TABLOCK) removed.
--                    ISNULL → IFNULL. IIF → IF.
--                    CONVERT(datetime,...) → CAST(... AS DATETIME).
--                    CONVERT(datetime2(0),...) → CAST(... AS DATETIME).
--                    CONVERT(decimal(18,2),...) → CAST(... AS FLOAT64).
--                    ISNUMERIC(x)=1 → SAFE_CAST(x AS INT64) IS NOT NULL.
--                    Try_Convert(int,x) → SAFE_CAST(x AS INT64).
--                    SET NOCOUNT ON / SET ANSI_WARNINGS OFF removed.
--                    OBJECT_SCHEMA_NAME(@@PROCID) → hardcoded string.
--                    SYSDATETIME() → CURRENT_DATETIME().
--                    DATETIME2(3) → DATETIME.
--                    All comments and history preserved.
--                    Audit table format preserved exactly.
-- Example:     CALL Staging.BQ_Load_SAT_Label_Allocation_Stg(619)
-- History:
--  29/07/2019  P. Waldron      Routine Written
--  01/11/2019  P. Waldron      Add data sources TMD, RP, TAS and EBAY
--  29/11/2019  P. Waldron      Refactor routine to use coalesce function
--  17/08/2020  P. Waldron      Add Except clause and Action column
--  10/09/2020  P. Waldron      Add PickupCF and DeliveryCF columns
--  05/05/2021  B. Woods        Changed stg1.BasePrice to BasePriceDiscounted + ExcessPriceDiscounted
--  29/06/2021  B. Woods        Add COALESCE to the Stg1 always null values in the SELECT EXCEPT clause
--                              to prevent duplicate loads
--  01/07/2021  B. Woods        Reverse COALESCE order in first select so SAT values are updated by non-null stg values.
--  11/07/2022  B. Woods        Added CONVERT to price column in SELECT...EXCEPT to eliminate duplicate rows
--  20/07/2022  B. Woods        Added CONVERT to CreateDateUTC in SELECT...EXCEPT to eliminate duplicate rows
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.BQ_Load_SAT_Label_Allocation_Stg`(
    IN ProcessID INT64
)
BEGIN

    -- SET NOCOUNT ON / SET ANSI_WARNINGS OFF removed (not applicable in BQ)

    DECLARE DefaultValidFrom DATETIME DEFAULT DATETIME '1900-01-01 00:00:00';
    DECLARE DefaultValidTo   DATETIME DEFAULT DATETIME '9999-12-31 00:00:00';
    DECLARE Loaded           DATETIME DEFAULT CURRENT_DATETIME();

    DECLARE Component    STRING DEFAULT 'Staging.Load_SAT_Label_Allocation_Stg';
    DECLARE Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING;
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64;
    DECLARE Updated      INT64;

    -- Get distinct set of Labels from Staging tables
    -- BQ TEMP TABLE replaces SQL Server #Stg_Label
    CREATE TEMP TABLE Stg_Label (
        LabelNo STRING
    );

    INSERT INTO Stg_Label
        SELECT LabelNumber AS LabelNo FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_API_RF_AdHocLabel_AllocationHistory_Stg`  UNION
        SELECT LabelNumber AS LabelNo FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_tblFastLabel_Consignment_Stg`              UNION
        SELECT result_LabelNumber AS LabelNo FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_API_Temando_RequestLabel_Stg`       UNION
        SELECT label_number AS LabelNo FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_tblOnlineEnquiry_RP_Stg`                  UNION
        SELECT LabelNo FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_HDManifests_Stg`                                          UNION
        SELECT LabelNumber AS LabelNo FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_tblTasman_Consignment_Stg`                 UNION
        SELECT LabelNumber AS LabelNo FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_ConsignmentItem_Stg`                       UNION
        SELECT Label AS LabelNo FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_fl_ConItem_Stg`                                  UNION
        SELECT LabelNumber AS LabelNo FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_Ebay_Labels_Stg`;

    -- CREATE CLUSTERED INDEX removed (BQ manages indexes automatically)

    -- WITH (TABLOCK) removed
    INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_SAT_Label_Allocation_Stg`
    (
        LabelNo_HSK,
        LabelNo,
        CountryCode,
        PickupRF,
        PickupCF,
        DeliveryRF,
        DeliveryCF,
        LabelColour,
        CreateDateUTC,
        CreateDateLocal,
        OESCustomerID,
        FMSCustomerID,
        IFSCustomerCode,
        DLSInvoiceID,
        FMSInvoiceID,
        FMSProductID,
        FKSource,
        FKID,
        Reference,
        NumberOfParcels,
        Price,
        ParcelLength,
        ParcelWidth,
        ParcelHeight,
        ParcelWeight,
        ParcelCubicWeight,
        RecordSource,
        RecordSourceID,
        Action
    )
    SELECT
        sat.LabelNo_HSK,
        stg.LabelNo,
        COALESCE(stg.CountryCode,       sat.CountryCode),
        COALESCE(stg.PickupRF,          sat.PickupRF),
        COALESCE(stg.PickupCF,          sat.PickupCF),
        COALESCE(stg.DeliveryRF,        sat.DeliveryRF),
        COALESCE(stg.DeliveryCF,        sat.DeliveryCF),
        COALESCE(stg.LabelColour,       sat.LabelColour),
        COALESCE(stg.CreateDateUTC,     sat.CreateDateUTC),
        COALESCE(stg.CreateDateLocal,   sat.CreateDateLocal),
        COALESCE(stg.OESCustomerID,     sat.OESCustomerID)     AS OESCustomerID,
        COALESCE(stg.FMSCustomerID,     sat.FMSCustomerID)     AS FMSCustomerID,
        COALESCE(stg.IFSCustomerCode,   sat.IFSCustomerCode)   AS IFSCustomerCode,
        COALESCE(stg.DLSInvoiceID,      sat.DLSInvoiceID)      AS DLSInvoiceID,
        COALESCE(stg.FMSInvoiceID,      sat.FMSInvoiceID)      AS FMSInvoiceID,
        COALESCE(stg.FMSProductID,      sat.FMSProductID),
        COALESCE(stg.FKSource,          sat.FKSource),
        COALESCE(stg.FKID,              sat.FKID),
        COALESCE(stg.Reference,         sat.Reference),
        COALESCE(stg.NumberOfParcels,   sat.NumberOfParcels),
        COALESCE(stg.price,             sat.price),
        COALESCE(stg.ParcelLength,      sat.ParcelLength),
        COALESCE(stg.ParcelWidth,       sat.ParcelWidth),
        COALESCE(stg.ParcelHeight,      sat.ParcelHeight),
        COALESCE(stg.ParcelWeight,      sat.ParcelWeight),
        COALESCE(stg.ParcelCubicWeight, sat.ParcelCubicWeight),
        stg.FKSource                                            AS RecordSource,
        NULL                                                    AS RecordSourceID,
        -- IIF → IF
        IF(sat.LabelNo IS NULL, 'Insert', 'Update')            AS Action
    FROM
    (
        SELECT
            lbl.LabelNo,
            CountryCode    = COALESCE(stg1.CountryId, stg2.CountryCode, stg3.CountryCode, stg4.CountryId, stg5.CountryCode, stg6.C_CountryCode, stg7.CountryID, stg8.Receiver_CountryCode, stg9.originCountry),
            PickupRF       = COALESCE(stg1.FromRf, stg2.Franchise, NULL, NULL, stg5.CollectionRF, stg6.C_RF, stg7.Sender_LocalRF, stg8.Origin_FranchiseeCode, stg9.originRF),
            PickupCF       = COALESCE(stg1.FromCf, NULL, NULL, NULL, NULL, NULL, stg7.PickupCourierNumber, NULL, NULL),
            DeliveryRF     = COALESCE(stg1.ToRf, NULL, stg3.destRF, stg4.DestinationRF, stg5.DeliveryRF, stg6.DeliveryRF, stg7.Receiver_LocalRF, stg8.Receiver_FranchiseeCode, stg9.destinationRF),
            DeliveryCF     = COALESCE(stg1.ToCf, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
            LabelColour    = COALESCE(NULL, stg2.LabelColour, stg3.LblColour, stg4.Colour, NULL, stg6.LabelColour, NULL, NULL, stg9.Label_Colour),
            CreateDateUTC  = COALESCE(NULL, stg2.DateAllocatedUTC, stg3.CreateDate, stg4.CreatedOn, NULL, stg6.CreatedDateUTC, stg7.CreateDateUTC, stg8.CreateDateUTC, stg9.CreateDateUTC),
            -- CONVERT(datetime,...) → CAST(... AS DATETIME)
            CreateDateLocal = COALESCE(CAST(stg1.CreatedOn AS DATETIME), stg2.DateAllocatedRelativeToRF, NULL, NULL, stg5.DateInserted, NULL, NULL, NULL, stg9.createDateLocal),
            OESCustomerID  = COALESCE(NULL, stg2.CustomerID, stg3.CustomerID, stg4.WebCustomerId, stg5.CustomerID, NULL, stg7.CustomerID, stg8.OESCustomerID, NULL),
            FMSCustomerID  = COALESCE(stg1.CustomerID, NULL, NULL, stg4.CustomerId, NULL, NULL, NULL, NULL, NULL),
            -- ISNUMERIC(x)=1 → SAFE_CAST(x AS INT64) IS NOT NULL
            IFSCustomerCode = COALESCE(NULL, NULL, stg3.ClientID, NULL, IF(SAFE_CAST(stg5.ClientId AS INT64) IS NOT NULL, stg5.ClientId, NULL), NULL, NULL, NULL, NULL),
            DLSInvoiceID   = COALESCE(NULL, stg2.FMSInvoiceID),
            FMSInvoiceID   = COALESCE(IF(stg1.Label IS NULL, NULL, stg1.FMSInvoiceNo), stg2.FMSInvoiceID, NULL, stg4.InvoiceNo, NULL, NULL, NULL, NULL, NULL),
            FMSProductID   = COALESCE(stg1.ProductID, stg2.FMSProductID, dbo.GetFmsProductIdForLabel(stg3.LabelNumber, stg3.CountryCode), NULL, NULL, NULL, NULL, NULL, NULL),

            FKSource =
                CASE
                    WHEN stg1.Label        IS NOT NULL THEN 'MyFastway'
                    WHEN stg2.LabelNumber  IS NOT NULL THEN IFNULL(stg2.FKSource, 'DynamicLabel')
                    WHEN stg3.LabelNumber  IS NOT NULL THEN 'FastLabel'
                    WHEN stg4.LabelNumber  IS NOT NULL THEN 'FastLabelEnterprise'
                    WHEN stg5.LabelNo      IS NOT NULL THEN 'HDManifests'
                    WHEN stg6.LabelNumber  IS NOT NULL THEN 'EBAY'
                    WHEN stg7.label_number IS NOT NULL THEN 'ReceiverPays'
                    WHEN stg8.LabelNumber  IS NOT NULL THEN 'Tasman'
                    WHEN stg9.result_LabelNumber IS NOT NULL THEN 'Temando'
                END,

            FKID           = COALESCE(NULL, stg2.FKID, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
            Reference      = COALESCE(stg1.Reference, stg2.ExternalReference, stg3.Reference, stg4.Reference, NULL, NULL, NULL, stg8.Reference, NULL),
            -- Try_Convert(int,x) → SAFE_CAST(x AS INT64)
            NumberOfParcels = COALESCE(stg1.Quantity, NULL, SAFE_CAST(stg3.Packaging AS INT64), stg4.ItemCount, stg5.Quantity, stg6.NoOfItems, stg7.NumberOfParcels, stg8.Packaging, NULL, 1),
            Price          = COALESCE(stg1.BasePriceDiscounted + stg1.ExcessPriceDiscounted, stg2.PriceSoldAtExGST, stg3.LblPrice, stg4.Price, NULL, stg6.LabelCost, stg7.label_cost, stg8.Price_Cost, stg9.result_Cost),
            ParcelLength   = COALESCE(stg1.Length, stg2.LengthInCm, stg3.Length, stg4.Length, stg5.Length, NULL, stg7.parcel_weight, stg8.Length, stg9.parcelLength),
            ParcelWidth    = COALESCE(stg1.Width,  stg2.WidthInCm,  stg3.Width,  stg4.Width,  stg5.Width,  NULL, stg7.parcel_width,  stg8.Width,  stg9.parcelWidth),
            ParcelHeight   = COALESCE(stg1.Height, stg2.HeightInCm, stg3.Height, stg4.Height, stg5.Height, NULL, stg7.parcel_Height, stg8.Height, stg9.parcelHeight),
            ParcelWeight   = COALESCE(stg1.WeightDead, stg2.Weight, stg3.Weight, stg4.WeightDead, stg5.Weight, NULL, stg7.parcel_Weight, stg8.Weight, stg9.parcelWeight),
            ParcelCubicWeight = COALESCE(stg1.WeightCubic, stg2.CubicWeight, NULL, stg4.WeightCubic, NULL, NULL, NULL, stg8.WeightCubic, NULL)

        FROM Stg_Label lbl
        FULL JOIN `{{ project_id }}.{{ target_dataset_id }}.Staging_fl_ConItem_Stg` stg1                        ON stg1.Label        = lbl.LabelNo
        FULL JOIN `{{ project_id }}.{{ target_dataset_id }}.Staging_API_RF_AdHocLabel_AllocationHistory_Stg` stg2 ON stg2.LabelNumber = lbl.LabelNo
        FULL JOIN `{{ project_id }}.{{ target_dataset_id }}.Staging_tblFastLabel_Consignment_Stg` stg3           ON stg3.LabelNumber  = lbl.LabelNo
        FULL JOIN `{{ project_id }}.{{ target_dataset_id }}.Staging_ConsignmentItem_Stg` stg4                    ON stg4.LabelNumber  = lbl.LabelNo
        FULL JOIN `{{ project_id }}.{{ target_dataset_id }}.Staging_HDManifests_Stg` stg5                        ON stg5.LabelNo      = lbl.LabelNo
        FULL JOIN `{{ project_id }}.{{ target_dataset_id }}.Staging_Ebay_Labels_Stg` stg6                        ON stg6.LabelNumber  = lbl.LabelNo
        FULL JOIN `{{ project_id }}.{{ target_dataset_id }}.Staging_tblOnlineEnquiry_RP_Stg` stg7                ON stg7.label_number = lbl.LabelNo
        FULL JOIN `{{ project_id }}.{{ target_dataset_id }}.Staging_tblTasman_Consignment_Stg` stg8              ON stg8.LabelNumber  = lbl.LabelNo
        FULL JOIN `{{ project_id }}.{{ target_dataset_id }}.Staging_API_Temando_RequestLabel_Stg` stg9            ON stg9.result_LabelNumber = lbl.LabelNo
    ) stg
    LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation` sat ON sat.LabelNo = stg.LabelNo AND sat.IsCurrent = 1

    WHERE stg.LabelNo IS NOT NULL
    AND (
        CASE
            WHEN sat.LabelNo IS NULL THEN 1
            WHEN EXISTS
            (
                SELECT
                    Stg.CountryCode,
                    Stg.PickupRF,
                    Stg.PickupCF,
                    Stg.DeliveryRF,
                    Stg.DeliveryCF,
                    COALESCE(Stg.LabelColour, Sat.LabelColour),
                    -- CONVERT(datetime2(0),...) → CAST(... AS DATETIME)
                    COALESCE(CAST(Stg.CreateDateUTC AS DATETIME), CAST(Sat.CreateDateUTC AS DATETIME)),
                    Stg.CreateDateLocal,
                    COALESCE(Stg.OESCustomerID,    Sat.OESCustomerID),
                    COALESCE(Stg.FMSCustomerID,    Sat.FMSCustomerID),
                    COALESCE(Stg.IFSCustomerCode,  Sat.IFSCustomerCode),
                    Stg.DLSInvoiceID,
                    Stg.FMSInvoiceID,
                    Stg.FMSProductID,
                    COALESCE(Stg.FKSource,         Sat.FKSource),
                    COALESCE(Stg.FKID,             Sat.FKID),
                    Stg.Reference,
                    Stg.NumberOfParcels,
                    -- CONVERT(decimal(18,2),...) → CAST(... AS FLOAT64)
                    CAST(stg.price AS FLOAT64)
                EXCEPT
                SELECT
                    Sat.CountryCode,
                    Sat.PickupRF,
                    Sat.PickupCF,
                    Sat.DeliveryRF,
                    Sat.DeliveryCF,
                    Sat.LabelColour,
                    -- limit to second comparison (comment preserved)
                    CAST(Sat.CreateDateUTC AS DATETIME),
                    Sat.CreateDateLocal,
                    Sat.OESCustomerID,
                    Sat.FMSCustomerID,
                    Sat.IFSCustomerCode,
                    Sat.DLSInvoiceID,
                    Sat.FMSInvoiceID,
                    Sat.FMSProductID,
                    Sat.FKSource,
                    Sat.FKID,
                    Sat.Reference,
                    Sat.NumberOfParcels,
                    Sat.Price
            )
            THEN 1

            WHEN
                LENGTH(IFNULL(CONCAT(CAST(Stg.ParcelLength AS STRING), CAST(Stg.ParcelWidth AS STRING), CAST(Stg.ParcelHeight AS STRING), CAST(Stg.ParcelWeight AS STRING), CAST(Stg.ParcelCubicWeight AS STRING)), '')) >
                LENGTH(IFNULL(CONCAT(CAST(Sat.ParcelLength AS STRING), CAST(Sat.ParcelWidth AS STRING), CAST(Sat.ParcelHeight AS STRING), CAST(Sat.ParcelWeight AS STRING), CAST(Sat.ParcelCubicWeight AS STRING)), ''))
            THEN 1

            ELSE 0
        END) = 1;

    SET Inserted = @@ROW_COUNT;
    SET Result   = 'Success';
    SET Ended    = CURRENT_DATETIME();

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

    DROP TABLE Stg_Label;

END;
