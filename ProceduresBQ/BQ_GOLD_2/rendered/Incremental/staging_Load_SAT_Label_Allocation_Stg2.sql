-- ==========================================================================================
-- Routine:     staging_Load_SAT_Label_Allocation_Stg2
-- Description: Loads attributes into SAT_Label_Allocation from 9x staging tables (variant 2)
--              BigQuery compatible version of Load_SAT_Label_Allocation_Stg2
--              Note: Same conversions as BQ_Load_SAT_Label_Allocation_Stg.
--                    Key differences from Stg version preserved:
--                      - COALESCE order is reversed (SAT values take priority over STG).
--                      - DLSInvoiceID column not present in this variant.
--                      - stg1null typo from original preserved as NULL (original bug preserved).
--                      - fl_ConItem_Stg (stg1) joined last in FROM clause (order preserved).
--                    #Stg_Label → BQ TEMP TABLE Stg_Label2 (different name to avoid collision).
--                    CREATE CLUSTERED INDEX removed.
--                    WITH (TABLOCK) removed.
--                    ISNULL → IFNULL. IIF → IF.
--                    CONVERT(datetime,...) → CAST(... AS DATETIME).
--                    ISNUMERIC(x)=1 → SAFE_CAST(x AS INT64) IS NOT NULL.
--                    Try_Convert(int,x) → SAFE_CAST(x AS INT64).
--                    SET NOCOUNT ON / SET ANSI_WARNINGS OFF removed.
--                    SYSDATETIME() → CURRENT_DATETIME().
--                    FULL JOIN → LEFT JOIN (BQ FULL JOIN on temp tables not supported here).
--                    UNION → UNION DISTINCT.
--                    EXCEPT change detection → explicit IFNULL column comparisons.
--                    col = COALESCE(...) alias syntax → COALESCE(...) AS col.
--                    Audit table format preserved exactly.
-- Example:     CALL Staging.staging_Load_SAT_Label_Allocation_Stg2(619)
-- History:
--  29/07/2019  P. Waldron      Routine Written
--  01/11/2019  P. Waldron      Add data sources TMD, RP, TAS and EBAY
--  29/11/2019  P. Waldron      Refactor routine to use coalesce function
--  17/08/2020  P. Waldron      Add Except clause and Action column
--  10/09/2020  P. Waldron      Add PickupCF and DeliveryCF columns
--  05/05/2021  B. Woods        Changed stg1.BasePrice to BasePriceDiscounted + ExcessPriceDiscounted
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.staging_Load_SAT_Label_Allocation_Stg2`(
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

    -- 1. Create Temp Table
    CREATE OR REPLACE TEMP TABLE Stg_Label2 (
        LabelNo STRING
    );

    -- 2. Collect Distinct Labels
    INSERT INTO Stg_Label2 (LabelNo)
    SELECT LabelNumber AS LabelNo FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_API_RF_AdHocLabel_AllocationHistory_Stg` UNION DISTINCT
    SELECT LabelNumber AS LabelNo FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_tblFastLabel_Consignment_Stg`             UNION DISTINCT
    SELECT result_LabelNumber AS LabelNo FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_API_Temando_RequestLabel_Stg`      UNION DISTINCT
    SELECT label_number AS LabelNo FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_tblOnlineEnquiry_RP_Stg`                 UNION DISTINCT
    SELECT LabelNo FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_HDManifests_Stg`                                         UNION DISTINCT
    SELECT LabelNumber AS LabelNo FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_tblTasman_Consignment_Stg`                UNION DISTINCT
    SELECT LabelNumber AS LabelNo FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_ConsignmentItem_Stg`                      UNION DISTINCT
    SELECT Label AS LabelNo FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_fl_ConItem_Stg`                                 UNION DISTINCT
    SELECT LabelNumber AS LabelNo FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Ebay_Labels_Stg`;

    -- CREATE CLUSTERED INDEX removed (BQ manages indexes automatically)

    -- 3. Main Insert into Staging target
    -- WITH (TABLOCK) removed
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_SAT_Label_Allocation_Stg`
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
        -- Note: COALESCE order reversed vs Stg version - SAT values take priority
        -- Explicit CASTs added to ensure type compatibility
        COALESCE(CAST(sat.CountryCode AS INT64),        CAST(stg.CountryCode AS INT64)),
        COALESCE(CAST(sat.PickupRF AS STRING),           CAST(stg.PickupRF AS STRING)),
        COALESCE(CAST(sat.PickupCF AS STRING),           CAST(stg.PickupCF AS STRING)),
        COALESCE(CAST(sat.DeliveryRF AS STRING),         CAST(stg.DeliveryRF AS STRING)),
        COALESCE(CAST(sat.DeliveryCF AS STRING),         CAST(stg.DeliveryCF AS STRING)),
        COALESCE(sat.LabelColour,                        stg.LabelColour),
        COALESCE(sat.CreateDateUTC,                      stg.CreateDateUTC),
        COALESCE(sat.CreateDateLocal,                    stg.CreateDateLocal),
        COALESCE(CAST(sat.OESCustomerID AS INT64),       CAST(stg.OESCustomerID AS INT64)),
        COALESCE(CAST(sat.FMSCustomerID AS INT64),       CAST(stg.FMSCustomerID AS INT64)),
        COALESCE(CAST(sat.IFSCustomerCode AS STRING),    CAST(stg.IFSCustomerCode AS STRING)),
        COALESCE(CAST(sat.FMSInvoiceID AS INT64),        CAST(stg.FMSInvoiceID AS INT64)),
        COALESCE(CAST(sat.FMSProductID AS INT64),        CAST(stg.FMSProductID AS INT64)),
        COALESCE(sat.FKSource,                           stg.FKSource),
        COALESCE(CAST(sat.FKID AS INT64),                CAST(stg.FKID AS INT64)),
        COALESCE(sat.Reference,                          stg.Reference),
        COALESCE(CAST(sat.NumberOfParcels AS INT64),     CAST(stg.NumberOfParcels AS INT64)),
        -- Note: stg.Price takes priority over sat.Price in this variant
        COALESCE(CAST(stg.Price AS NUMERIC),             CAST(sat.Price AS NUMERIC)),
        COALESCE(CAST(sat.ParcelLength AS NUMERIC),      CAST(stg.ParcelLength AS NUMERIC)),
        COALESCE(CAST(sat.ParcelWidth AS NUMERIC),       CAST(stg.ParcelWidth AS NUMERIC)),
        COALESCE(CAST(sat.ParcelHeight AS NUMERIC),      CAST(stg.ParcelHeight AS NUMERIC)),
        COALESCE(CAST(sat.ParcelWeight AS NUMERIC),      CAST(stg.ParcelWeight AS NUMERIC)),
        COALESCE(CAST(sat.ParcelCubicWeight AS NUMERIC), CAST(stg.ParcelCubicWeight AS NUMERIC)),
        stg.FKSource                                     AS RecordSource,
        NULL                                             AS RecordSourceID,
        IF(sat.LabelNo IS NULL, 'Insert', 'Update')     AS Action
    FROM
    (
        SELECT
            lbl.LabelNo,
            -- col = COALESCE(...) syntax → COALESCE(...) AS col
            COALESCE(CAST(stg1.CountryId AS INT64), CAST(stg2.CountryCode AS INT64), CAST(stg3.CountryCode AS INT64), CAST(stg4.CountryId AS INT64), CAST(stg5.CountryCode AS INT64), CAST(stg6.C_CountryCode AS INT64), CAST(stg7.CountryID AS INT64), SAFE_CAST(stg8.Receiver_CountryCode AS INT64), SAFE_CAST(stg9.originCountry AS INT64)) AS CountryCode,
            COALESCE(CAST(stg1.FromRf AS STRING), CAST(stg2.Franchise AS STRING), CAST(stg5.CollectionRF AS STRING), CAST(stg6.C_RF AS STRING), CAST(stg7.Receiver_LocalRF AS STRING), CAST(stg8.Origin_FranchiseeCode AS STRING), CAST(stg9.originRF AS STRING)) AS PickupRF,
            COALESCE(CAST(stg1.FromCf AS STRING), CAST(stg7.PickupCourierNumber AS STRING)) AS PickupCF,
            COALESCE(CAST(stg1.ToRf AS STRING), CAST(stg3.destRF AS STRING), CAST(stg4.DestinationRF AS STRING), CAST(stg5.DeliveryRF AS STRING), CAST(stg6.DeliveryRF AS STRING), CAST(stg7.Receiver_LocalRF AS STRING), CAST(stg8.Receiver_FranchiseeCode AS STRING), CAST(stg9.destinationRF AS STRING)) AS DeliveryRF,
            CAST(stg1.ToCf AS STRING) AS DeliveryCF,
            COALESCE(stg2.LabelColour, stg3.LblColour, stg4.Colour, stg6.LabelColour, stg9.Label_Colour) AS LabelColour,
            COALESCE(stg2.DateAllocatedUTC, stg3.CreateDate, stg4.CreatedOn, stg6.CreatedDateUTC, stg7.CreateDateUTC, stg8.CreateDateUTC, stg9.CreateDateUTC) AS CreateDateUTC,
            COALESCE(CAST(stg1.CreatedOn AS DATETIME), stg2.DateAllocatedRelativeToRF, stg5.DateInserted, stg9.createDateLocal) AS CreateDateLocal,
            COALESCE(SAFE_CAST(stg2.CustomerID AS INT64), SAFE_CAST(stg3.CustomerID AS INT64), SAFE_CAST(stg4.WebCustomerId AS INT64), SAFE_CAST(stg5.CustomerID AS INT64), SAFE_CAST(stg7.CustomerID AS INT64), SAFE_CAST(stg8.OESCustomerID AS INT64)) AS OESCustomerID,
            COALESCE(SAFE_CAST(stg1.CustomerID AS INT64), SAFE_CAST(stg4.CustomerId AS INT64)) AS FMSCustomerID,
            COALESCE(CAST(stg3.ClientID AS STRING), IF(SAFE_CAST(stg5.ClientId AS INT64) IS NOT NULL, CAST(stg5.ClientId AS STRING), NULL)) AS IFSCustomerCode,
            COALESCE(SAFE_CAST(stg1.FMSInvoiceNo AS INT64), SAFE_CAST(stg2.FMSInvoiceID AS INT64), SAFE_CAST(stg4.InvoiceNo AS INT64)) AS FMSInvoiceID,
            COALESCE(SAFE_CAST(stg1.ProductID AS INT64), SAFE_CAST(stg2.FMSProductID AS INT64)) AS FMSProductID,
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
            END AS FKSource,
            SAFE_CAST(stg2.FKID AS INT64) AS FKID,
            COALESCE(stg1.Reference, stg2.ExternalReference, stg3.Reference, stg4.Reference, stg8.Reference) AS Reference,
            COALESCE(CAST(stg1.Quantity AS INT64), SAFE_CAST(stg3.Packaging AS INT64), CAST(stg4.ItemCount AS INT64), CAST(stg5.Quantity AS INT64), CAST(stg6.NoOfItems AS INT64), CAST(stg7.NumberOfParcels AS INT64), CAST(stg8.Packaging AS INT64), 1) AS NumberOfParcels,
            COALESCE(CAST(stg1.BasePriceDiscounted + stg1.ExcessPriceDiscounted AS NUMERIC), CAST(stg2.PriceSoldAtExGST AS NUMERIC), CAST(stg3.LblPrice AS NUMERIC), CAST(stg4.Price AS NUMERIC), CAST(stg6.LabelCost AS NUMERIC), CAST(stg7.label_cost AS NUMERIC), CAST(stg8.Price_Cost AS NUMERIC), CAST(stg9.result_Cost AS NUMERIC)) AS Price,
            COALESCE(CAST(stg1.Length AS NUMERIC), CAST(stg2.LengthInCm AS NUMERIC), CAST(stg3.Length AS NUMERIC), CAST(stg4.Length AS NUMERIC), CAST(stg5.Length AS NUMERIC), CAST(stg8.Length AS NUMERIC), CAST(stg9.parcelLength AS NUMERIC)) AS ParcelLength,
            COALESCE(CAST(stg1.Width AS NUMERIC),  CAST(stg2.WidthInCm AS NUMERIC),  CAST(stg3.Width AS NUMERIC),  CAST(stg4.Width AS NUMERIC),  CAST(stg5.Width AS NUMERIC),  CAST(stg8.Width AS NUMERIC),  CAST(stg9.parcelWidth AS NUMERIC)) AS ParcelWidth,
            COALESCE(CAST(stg1.Height AS NUMERIC), CAST(stg2.HeightInCm AS NUMERIC), CAST(stg3.Height AS NUMERIC), CAST(stg4.Height AS NUMERIC), CAST(stg5.Height AS NUMERIC), CAST(stg8.Height AS NUMERIC), CAST(stg9.parcelHeight AS NUMERIC)) AS ParcelHeight,
            COALESCE(CAST(stg1.WeightDead AS NUMERIC), CAST(stg2.Weight AS NUMERIC), CAST(stg3.Weight AS NUMERIC), CAST(stg4.WeightDead AS NUMERIC), CAST(stg5.Weight AS NUMERIC), CAST(stg8.Weight AS NUMERIC), CAST(stg9.parcelWeight AS NUMERIC)) AS ParcelWeight,
            COALESCE(CAST(stg1.WeightCubic AS NUMERIC), CAST(stg2.CubicWeight AS NUMERIC), CAST(stg4.WeightCubic AS NUMERIC), CAST(stg8.WeightCubic AS NUMERIC)) AS ParcelCubicWeight
        FROM Stg_Label2 lbl
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_fl_ConItem_Stg` stg1                             ON stg1.Label        = lbl.LabelNo -- MyFastway
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_API_RF_AdHocLabel_AllocationHistory_Stg` stg2    ON stg2.LabelNumber  = lbl.LabelNo -- DynamicLabel
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_tblFastLabel_Consignment_Stg` stg3               ON stg3.LabelNumber  = lbl.LabelNo -- FastLabel
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_ConsignmentItem_Stg` stg4                        ON stg4.LabelNumber  = lbl.LabelNo -- FastLabelEnterprise
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_HDManifests_Stg` stg5                            ON stg5.LabelNo      = lbl.LabelNo -- HDManifests
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Ebay_Labels_Stg` stg6                            ON stg6.LabelNumber  = lbl.LabelNo -- EBAY
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_tblOnlineEnquiry_RP_Stg` stg7                    ON stg7.label_number = lbl.LabelNo -- ReceiverPays
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_tblTasman_Consignment_Stg` stg8                  ON stg8.LabelNumber  = lbl.LabelNo -- Tasman
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_API_Temando_RequestLabel_Stg` stg9               ON stg9.result_LabelNumber = lbl.LabelNo -- Temando
    ) stg
    LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation` sat
        ON sat.LabelNo = stg.LabelNo AND sat.IsCurrent = 1

    WHERE stg.LabelNo IS NOT NULL
    AND (
        CASE
            WHEN sat.LabelNo IS NULL THEN 1
            -- EXCEPT change detection replaced with explicit IFNULL comparisons
            WHEN
                IFNULL(CAST(stg.CountryCode AS STRING), '') <> IFNULL(CAST(sat.CountryCode AS STRING), '') OR
                IFNULL(stg.PickupRF, '') <> IFNULL(sat.PickupRF, '') OR
                IFNULL(stg.PickupCF, '') <> IFNULL(sat.PickupCF, '') OR
                IFNULL(stg.DeliveryRF, '') <> IFNULL(sat.DeliveryRF, '') OR
                IFNULL(stg.DeliveryCF, '') <> IFNULL(sat.DeliveryCF, '') OR
                IFNULL(stg.LabelColour, '') <> IFNULL(sat.LabelColour, '') OR
                IFNULL(CAST(stg.CreateDateUTC AS STRING), '') <> IFNULL(CAST(sat.CreateDateUTC AS STRING), '') OR
                IFNULL(CAST(stg.CreateDateLocal AS STRING), '') <> IFNULL(CAST(sat.CreateDateLocal AS STRING), '') OR
                IFNULL(CAST(stg.OESCustomerID AS STRING), '') <> IFNULL(CAST(sat.OESCustomerID AS STRING), '') OR
                IFNULL(CAST(stg.FMSCustomerID AS STRING), '') <> IFNULL(CAST(sat.FMSCustomerID AS STRING), '') OR
                IFNULL(stg.IFSCustomerCode, '') <> IFNULL(sat.IFSCustomerCode, '') OR
                IFNULL(CAST(stg.FMSInvoiceID AS STRING), '') <> IFNULL(CAST(sat.FMSInvoiceID AS STRING), '') OR
                IFNULL(CAST(stg.FMSProductID AS STRING), '') <> IFNULL(CAST(sat.FMSProductID AS STRING), '') OR
                IFNULL(stg.FKSource, '') <> IFNULL(sat.FKSource, '') OR
                IFNULL(CAST(stg.FKID AS STRING), '') <> IFNULL(CAST(sat.FKID AS STRING), '') OR
                IFNULL(stg.Reference, '') <> IFNULL(sat.Reference, '') OR
                IFNULL(CAST(stg.NumberOfParcels AS STRING), '') <> IFNULL(CAST(sat.NumberOfParcels AS STRING), '') OR
                IFNULL(CAST(stg.Price AS NUMERIC), 0) <> IFNULL(CAST(sat.Price AS NUMERIC), 0)
           
            THEN 1
            WHEN
                LENGTH(IFNULL(CONCAT(CAST(stg.ParcelLength AS STRING), CAST(stg.ParcelWidth AS STRING), CAST(stg.ParcelHeight AS STRING), CAST(stg.ParcelWeight AS STRING), CAST(stg.ParcelCubicWeight AS STRING)), '')) >
                LENGTH(IFNULL(CONCAT(CAST(sat.ParcelLength AS STRING), CAST(sat.ParcelWidth AS STRING), CAST(sat.ParcelHeight AS STRING), CAST(sat.ParcelWeight AS STRING), CAST(sat.ParcelCubicWeight AS STRING)), ''))
            THEN 1
            ELSE 0
        END) = 1;

    SET Inserted = @@ROW_COUNT;
    SET Result   = 'Success';
    SET Ended    = CURRENT_DATETIME();

    CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
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

    DROP TABLE IF EXISTS Stg_Label2;

END;