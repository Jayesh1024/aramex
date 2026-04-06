-- ==========================================================================================
-- Routine:     BQ_Load_SAT_Label_Allocation_Stg2
-- Description: Loads attributes into SAT_Label_Allocation from 9x staging tables
--              BigQuery compatible version of Staging.Load_SAT_Label_Allocation_Stg2
--              Note: Same conversion rules as BQ_Load_SAT_Label_Allocation_Stg.
--                    Key differences from Stg version:
--                      - COALESCE order reversed (sat values take priority over stg)
--                      - DLSInvoiceID column removed from this version
--                      - EXCEPT clause simpler (no COALESCE wrappers, no CONVERT on price/UTC)
--                      - stg1null typo in original preserved as NULL (original bug preserved)
--                    CREATE CLUSTERED INDEX removed (not supported in BQ)
--                    WITH (TABLOCK) removed
--                    SET NOCOUNT ON / SET ANSI_WARNINGS OFF removed
--                    IIF → IF; ISNUMERIC → SAFE_CAST; LEN → LENGTH; ISNULL → IFNULL
--                    CONVERT(datetime,x) → CAST(x AS DATETIME)
--                    Audit table format preserved exactly.
-- Example:     CALL Staging.BQ_Load_SAT_Label_Allocation_Stg2(619)
-- History:
--  29/07/2019  P. Waldron      Routine Written
--  01/11/2019  P. Waldron      Add data sources TMD, RP, TAS and EBAY
--  29/11/2019  P. Waldron      Refactor routine to use coalesce function
--  17/08/2020  P. Waldron      Add Except clause and Action column
--  10/09/2020  P. Waldron      Add PickupCF and DeliveryCF columns
--  05/05/2021  B. Woods        Changed stg1.BasePrice to BasePriceDiscounted + ExcessPriceDiscounted
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE Staging.BQ_Load_SAT_Label_Allocation_Stg2(
    IN ProcessID INT64
)
BEGIN

    DECLARE DefaultValidFrom DATETIME DEFAULT DATETIME '1900-01-01 00:00:00';
    DECLARE DefaultValidTo   DATETIME DEFAULT DATETIME '9999-12-31 00:00:00';
    DECLARE Loaded           DATETIME DEFAULT CURRENT_DATETIME();

    DECLARE Component    STRING DEFAULT 'Staging.Load_SAT_Label_Allocation_Stg2';
    DECLARE Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING;
    DECLARE ErrorMessage STRING;
    DECLARE Inserted     INT64 DEFAULT 0;
    DECLARE Updated      INT64 DEFAULT 0;

    BEGIN

        -- Get distinct set of Labels from Staging tables
        -- #Stg_Label → BQ session-scoped temp table
        -- CREATE CLUSTERED INDEX removed (not supported in BQ)
        CREATE TEMP TABLE Stg_Label AS
        SELECT LabelNumber AS LabelNo FROM Staging.API_RF_AdHocLabel_AllocationHistory_Stg  UNION DISTINCT
        SELECT LabelNumber AS LabelNo FROM Staging.tblFastLabel_Consignment_Stg             UNION DISTINCT
        SELECT result_LabelNumber AS LabelNo FROM Staging.API_Temando_RequestLabel_Stg      UNION DISTINCT
        SELECT label_number AS LabelNo FROM Staging.tblOnlineEnquiry_RP_Stg                 UNION DISTINCT
        SELECT LabelNo FROM Staging.HDManifests_Stg                                         UNION DISTINCT
        SELECT LabelNumber AS LabelNo FROM Staging.tblTasman_Consignment_Stg                UNION DISTINCT
        SELECT LabelNumber AS LabelNo FROM Staging.ConsignmentItem_Stg                      UNION DISTINCT
        SELECT Label AS LabelNo FROM Staging.fl_ConItem_Stg                                 UNION DISTINCT
        SELECT LabelNumber AS LabelNo FROM Staging.Ebay_Labels_Stg;

        -- WITH (TABLOCK) removed
        INSERT INTO Staging.SAT_Label_Allocation_Stg
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
            -- Note: COALESCE order reversed vs Stg version (sat takes priority)
            COALESCE(sat.CountryCode,      stg.CountryCode),
            COALESCE(sat.PickupRF,         stg.PickupRF),
            COALESCE(sat.PickupCF,         stg.PickupCF),
            COALESCE(sat.DeliveryRF,       stg.DeliveryRF),
            COALESCE(sat.DeliveryCF,       stg.DeliveryCF),
            COALESCE(sat.LabelColour,      stg.LabelColour),
            COALESCE(sat.CreateDateUTC,    stg.CreateDateUTC),
            COALESCE(sat.CreateDateLocal,  stg.CreateDateLocal),
            COALESCE(sat.OESCustomerID,    stg.OESCustomerID),
            COALESCE(sat.FMSCustomerID,    stg.FMSCustomerID),
            COALESCE(sat.IFSCustomerCode,  stg.IFSCustomerCode),
            COALESCE(sat.FMSInvoiceID,     stg.FMSInvoiceID),
            COALESCE(sat.FMSProductID,     stg.FMSProductID),
            COALESCE(sat.FKSource,         stg.FKSource),
            COALESCE(sat.FKID,             stg.FKID),
            COALESCE(sat.Reference,        stg.Reference),
            COALESCE(sat.NumberOfParcels,  stg.NumberOfParcels),
            COALESCE(stg.Price,            sat.Price),       -- stg price takes priority (as per original)
            COALESCE(sat.ParcelLength,     stg.ParcelLength),
            COALESCE(sat.ParcelWidth,      stg.ParcelWidth),
            COALESCE(sat.ParcelHeight,     stg.ParcelHeight),
            COALESCE(sat.ParcelWeight,     stg.ParcelWeight),
            COALESCE(sat.ParcelCubicWeight,stg.ParcelCubicWeight),
            stg.FKSource                                        AS RecordSource,
            NULL                                               AS RecordSourceID,
            -- IIF → IF
            IF(sat.LabelNo IS NULL, 'Insert', 'Update')        AS Action
        FROM
        (
            SELECT
                lbl.LabelNo,
                CountryCode     = COALESCE(stg1.CountryId, stg2.CountryCode, stg3.CountryCode, stg4.CountryId, stg5.CountryCode, stg6.C_CountryCode, stg7.CountryID, stg8.Receiver_CountryCode, stg9.originCountry),
                PickupRF        = COALESCE(stg1.FromRf, stg2.Franchise, NULL, NULL, stg5.CollectionRF, stg6.C_RF, NULL, stg7.Receiver_LocalRF, stg8.Origin_FranchiseeCode, stg9.originRF),
                PickupCF        = COALESCE(stg1.FromCf, NULL, NULL, NULL, NULL, NULL, stg7.PickupCourierNumber, NULL, NULL),
                DeliveryRF      = COALESCE(stg1.ToRf, NULL, stg3.destRF, stg4.DestinationRF, stg5.DeliveryRF, stg6.DeliveryRF, stg7.Receiver_LocalRF, stg8.Receiver_FranchiseeCode, stg9.destinationRF),
                DeliveryCF      = COALESCE(stg1.ToCf, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
                LabelColour     = COALESCE(NULL, stg2.LabelColour, stg3.LblColour, stg4.Colour, NULL, stg6.LabelColour, NULL, NULL, stg9.Label_Colour),
                CreateDateUTC   = COALESCE(NULL, stg2.DateAllocatedUTC, stg3.CreateDate, stg4.CreatedOn, NULL, stg6.CreatedDateUTC, stg7.CreateDateUTC, stg8.CreateDateUTC, stg9.CreateDateUTC),
                -- CONVERT(datetime,x) → CAST(x AS DATETIME)
                CreateDateLocal = COALESCE(CAST(stg1.CreatedOn AS DATETIME), stg2.DateAllocatedRelativeToRF, NULL, NULL, stg5.DateInserted, NULL, NULL, NULL, stg9.createDateLocal),
                -- stg1null typo preserved from original source as NULL
                OESCustomerID   = COALESCE(NULL, stg2.CustomerID, stg3.CustomerID, stg4.WebCustomerId, stg5.CustomerID, NULL, stg7.CustomerID, stg8.OESCustomerID, NULL),
                FMSCustomerID   = COALESCE(stg1.CustomerID, NULL, NULL, stg4.CustomerId, NULL, NULL, NULL, NULL, NULL),
                -- ISNUMERIC → SAFE_CAST(x AS FLOAT64) IS NOT NULL
                IFSCustomerCode = COALESCE(NULL, NULL, stg3.ClientID, NULL, IF(SAFE_CAST(stg5.ClientId AS FLOAT64) IS NOT NULL, stg5.ClientId, NULL), NULL, NULL, NULL, NULL),
                FMSInvoiceID    = COALESCE(stg1.FMSInvoiceNo, stg2.FMSInvoiceID, NULL, stg4.InvoiceNo, NULL, NULL, NULL, NULL, NULL),
                FMSProductID    = COALESCE(stg1.ProductID, stg2.FMSProductID, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
                FKSource        = CASE
                                    WHEN stg1.Label IS NOT NULL        THEN 'MyFastway'
                                    WHEN stg2.LabelNumber IS NOT NULL  THEN IFNULL(stg2.FKSource, 'DynamicLabel')
                                    WHEN stg3.LabelNumber IS NOT NULL  THEN 'FastLabel'
                                    WHEN stg4.LabelNumber IS NOT NULL  THEN 'FastLabelEnterprise'
                                    WHEN stg5.LabelNo IS NOT NULL      THEN 'HDManifests'
                                    WHEN stg6.LabelNumber IS NOT NULL  THEN 'EBAY'
                                    WHEN stg7.label_number IS NOT NULL THEN 'ReceiverPays'
                                    WHEN stg8.LabelNumber IS NOT NULL  THEN 'Tasman'
                                    WHEN stg9.result_LabelNumber IS NOT NULL THEN 'Temando'
                                  END,
                FKID            = COALESCE(NULL, stg2.FKID, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
                Reference       = COALESCE(stg1.Reference, stg2.ExternalReference, stg3.Reference, stg4.Reference, NULL, NULL, NULL, stg8.Reference, NULL),
                -- SAFE_CAST replaces TRY_CONVERT
                NumberOfParcels = COALESCE(stg1.Quantity, NULL, SAFE_CAST(stg3.Packaging AS INT64), stg4.ItemCount, stg5.Quantity, stg6.NoOfItems, stg7.NumberOfParcels, stg8.Packaging, NULL, 1),
                Price           = COALESCE(stg1.BasePriceDiscounted + stg1.ExcessPriceDiscounted, stg2.PriceSoldAtExGST, stg3.LblPrice, stg4.Price, NULL, stg6.LabelCost, stg7.label_cost, stg8.Price_Cost, stg9.result_Cost),
                ParcelLength    = COALESCE(stg1.Length, stg2.LengthInCm, stg3.Length, stg4.Length, stg5.Length, NULL, stg7.parcel_weight, stg8.Length, stg9.parcelLength),
                ParcelWidth     = COALESCE(stg1.Width, stg2.WidthInCm, stg3.Width, stg4.Width, stg5.Width, NULL, stg7.parcel_width, stg8.Width, stg9.parcelLength),
                ParcelHeight    = COALESCE(stg1.Height, stg2.HeightInCm, stg3.Height, stg4.Height, stg5.Height, NULL, stg7.parcel_Height, stg8.Height, stg9.parcelHeight),
                ParcelWeight    = COALESCE(stg1.WeightDead, stg2.Weight, stg3.Weight, stg4.WeightDead, stg5.Weight, NULL, stg7.parcel_Weight, stg8.Weight, stg9.parcelLength),
                ParcelCubicWeight = COALESCE(stg1.WeightCubic, stg2.CubicWeight, NULL, stg4.WeightCubic, NULL, NULL, NULL, stg8.WeightCubic, NULL)

            FROM Stg_Label lbl
            FULL JOIN Staging.API_RF_AdHocLabel_AllocationHistory_Stg stg2 ON stg2.LabelNumber = lbl.LabelNo
            FULL JOIN Staging.tblFastLabel_Consignment_Stg stg3            ON stg3.LabelNumber = lbl.LabelNo
            FULL JOIN Staging.API_Temando_RequestLabel_Stg stg9            ON stg9.result_LabelNumber = lbl.LabelNo
            FULL JOIN Staging.tblOnlineEnquiry_RP_Stg stg7                 ON stg7.label_number = lbl.LabelNo
            FULL JOIN Staging.HDManifests_Stg stg5                         ON stg5.LabelNo = lbl.LabelNo
            FULL JOIN Staging.tblTasman_Consignment_Stg stg8               ON stg8.LabelNumber = lbl.LabelNo
            FULL JOIN Staging.ConsignmentItem_Stg stg4                     ON stg4.LabelNumber = lbl.LabelNo
            FULL JOIN Staging.fl_ConItem_Stg stg1                          ON stg1.Label = lbl.LabelNo
            FULL JOIN Staging.Ebay_Labels_Stg stg6                         ON stg6.LabelNumber = lbl.LabelNo
        ) stg
        LEFT JOIN dv.SAT_Label_Allocation sat
            ON  sat.LabelNo   = stg.LabelNo
            AND sat.IsCurrent = 1

        WHERE stg.LabelNo IS NOT NULL
        AND (
            CASE
                WHEN sat.LabelNo IS NULL THEN 1
                WHEN EXISTS (
                    SELECT
                        stg.CountryCode,
                        stg.PickupRF,
                        stg.PickupCF,
                        stg.DeliveryRF,
                        stg.DeliveryCF,
                        stg.LabelColour,
                        stg.CreateDateUTC,
                        stg.CreateDateLocal,
                        stg.OESCustomerID,
                        stg.FMSCustomerID,
                        stg.IFSCustomerCode,
                        stg.FMSInvoiceID,
                        stg.FMSProductID,
                        stg.FKSource,
                        stg.FKID,
                        stg.Reference,
                        stg.NumberOfParcels,
                        stg.Price
                    EXCEPT DISTINCT
                    SELECT
                        sat.CountryCode,
                        sat.PickupRF,
                        sat.PickupCF,
                        sat.DeliveryRF,
                        sat.DeliveryCF,
                        sat.LabelColour,
                        sat.CreateDateUTC,
                        sat.CreateDateLocal,
                        sat.OESCustomerID,
                        sat.FMSCustomerID,
                        sat.IFSCustomerCode,
                        sat.FMSInvoiceID,
                        sat.FMSProductID,
                        sat.FKSource,
                        sat.FKID,
                        sat.Reference,
                        sat.NumberOfParcels,
                        sat.Price
                ) THEN 1
                -- LEN → LENGTH; ISNULL(CONCAT(...)) → IFNULL(CONCAT(...))
                WHEN LENGTH(IFNULL(CONCAT(stg.ParcelLength, stg.ParcelWidth, stg.ParcelHeight, stg.ParcelWeight, stg.ParcelCubicWeight), '')) >
                     LENGTH(IFNULL(CONCAT(sat.ParcelLength, sat.ParcelWidth, sat.ParcelHeight, sat.ParcelWeight, sat.ParcelCubicWeight), ''))
                THEN 1
                ELSE 0
            END
        ) = 1;

        SET Inserted = @@ROW_COUNT;
        SET Result   = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed';
        SET ErrorMessage = @@error.message;

    END;

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

    DROP TABLE IF EXISTS Stg_Label;

END;
