CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_SAT_Label_Allocation_FLE`(
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
        -- -----------------------------------------------------------------------
        MERGE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_FLE` AS Tgt
        USING (
            SELECT DISTINCT
                `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(CAST(Stg.LabelNumber AS STRING),'^') AS LabelNo_HSK,
                Stg.LabelNumber,
                Stg.CountryId,
                IFNULL(CAST(cty.CountryName AS STRING), 'Unknown') AS Country,
                Stg.WebCustomerId,
                Stg.CustomerId,
                Stg.ReceiverContactName,
                Stg.ReceiverAddress1,
                Stg.ReceiverAddress2,
                Stg.ReceiverSuburb,
                Stg.ReceiverPostcode,
                Stg.ReceiverPhone,
                Stg.ReceiverEmail,
                Stg.PrintedOn,
                Stg.Reference,
                Stg.SpecialInstructions,
                Stg.DestinationRF,
                Stg.ManifestId,
                Stg.Price,
                Stg.InvoiceNo,
                Stg.ItemCount,
                Stg.CreatedOn,
                Stg.WeightCubic,
                Stg.WeightDead,
                Stg.Length,
                Stg.Width,
                Stg.Height,
                Stg.Colour,
                Stg.ConsignmentItemId
            FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_ConsignmentItem_Stg` Stg
            LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Country` cty 
                ON CAST(cty.CountryCode AS STRING) = CAST(Stg.CountryId AS STRING)
        ) AS Src
        ON  Tgt.LabelNo_HSK = Src.LabelNo_HSK
        AND Tgt.IsCurrent   = 1
        WHEN MATCHED AND (
            -- Comparison logic: CAST everything to STRING for the IFNULL check
            IFNULL(CAST(Tgt.LabelNo AS STRING), '')             <> IFNULL(CAST(Src.LabelNumber AS STRING), '')
         OR IFNULL(CAST(Tgt.CountryCode AS STRING), '')         <> IFNULL(CAST(Src.CountryId AS STRING), '')
         OR IFNULL(CAST(Tgt.Country AS STRING), '')             <> IFNULL(CAST(Src.Country AS STRING), '')
         OR IFNULL(CAST(Tgt.ToContactName AS STRING), '')       <> IFNULL(CAST(Src.ReceiverContactName AS STRING), '')
         OR IFNULL(CAST(Tgt.ToAddress1 AS STRING), '')          <> IFNULL(CAST(Src.ReceiverAddress1 AS STRING), '')
         OR IFNULL(CAST(Tgt.ToAddress2 AS STRING), '')          <> IFNULL(CAST(Src.ReceiverAddress2 AS STRING), '')
         OR IFNULL(CAST(Tgt.ToSuburb AS STRING), '')            <> IFNULL(CAST(Src.ReceiverSuburb AS STRING), '')
         OR IFNULL(CAST(Tgt.ToPostcode AS STRING), '')          <> IFNULL(CAST(Src.ReceiverPostcode AS STRING), '')
         OR IFNULL(CAST(Tgt.ToPhone AS STRING), '')             <> IFNULL(CAST(Src.ReceiverPhone AS STRING), '')
         OR IFNULL(CAST(Tgt.ToEmail AS STRING), '')             <> IFNULL(CAST(Src.ReceiverEmail AS STRING), '')
         OR IFNULL(CAST(Tgt.Reference AS STRING), '')           <> IFNULL(CAST(Src.Reference AS STRING), '')
         OR IFNULL(CAST(Tgt.SpecialInstructions AS STRING), '') <> IFNULL(CAST(Src.SpecialInstructions AS STRING), '')
         OR IFNULL(CAST(Tgt.DeliveryRF AS STRING), '')          <> IFNULL(CAST(Src.DestinationRF AS STRING), '')
         OR IFNULL(CAST(Tgt.FMSInvoiceNo AS STRING), '')        <> IFNULL(CAST(Src.InvoiceNo AS STRING), '')
         OR IFNULL(CAST(Tgt.LabelColour AS STRING), '')         <> IFNULL(CAST(Src.Colour AS STRING), '')
         OR IFNULL(CAST(Tgt.OESCustomerId AS STRING), '')       <> IFNULL(CAST(Src.WebCustomerId AS STRING), '')
         OR IFNULL(CAST(Tgt.FMSCustomerID AS STRING), '')       <> IFNULL(CAST(Src.CustomerId AS STRING), '')
         OR IFNULL(CAST(Tgt.PrintedOn AS STRING), '')           <> IFNULL(CAST(Src.PrintedOn AS STRING), '')
         OR IFNULL(CAST(Tgt.ManifestId AS STRING), '')          <> IFNULL(CAST(Src.ManifestId AS STRING), '')
         OR IFNULL(CAST(Tgt.Price AS STRING), '')               <> IFNULL(CAST(Src.Price AS STRING), '')
         OR IFNULL(CAST(Tgt.ItemCount AS STRING), '')           <> IFNULL(CAST(Src.ItemCount AS STRING), '')
         OR IFNULL(CAST(Tgt.CreatedOn AS STRING), '')           <> IFNULL(CAST(Src.CreatedOn AS STRING), '')
         OR IFNULL(CAST(Tgt.DeadWeight AS STRING), '')          <> IFNULL(CAST(Src.WeightDead AS STRING), '')
         OR IFNULL(CAST(Tgt.CubicWeight AS STRING), '')         <> IFNULL(CAST(Src.WeightCubic AS STRING), '')
         OR IFNULL(CAST(Tgt.LengthInCm AS STRING), '')          <> IFNULL(CAST(Src.Length AS STRING), '')
         OR IFNULL(CAST(Tgt.WidthInCm AS STRING), '')           <> IFNULL(CAST(Src.Width AS STRING), '')
         OR IFNULL(CAST(Tgt.HeightInCm AS STRING), '')          <> IFNULL(CAST(Src.Height AS STRING), '')
         OR IFNULL(CAST(Tgt.ConsignmentItemId AS STRING), '')   <> IFNULL(CAST(Src.ConsignmentItemId AS STRING), '')
        )
        THEN UPDATE SET
            IsCurrent = 0,
            ValidTo   = Loaded;

        SET Updated = @@ROW_COUNT;

        -- -----------------------------------------------------------------------
        -- STEP 2: Insert new rows (IsCurrent=1)
        -- -----------------------------------------------------------------------
        INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_FLE`
        (
            LabelNo_HSK, LabelNo, CountryCode, Country, OESCustomerId, FMSCustomerID,
            ToContactName, ToAddress1, ToAddress2, ToSuburb, ToPostcode, ToPhone, ToEmail,
            PrintedOn, Reference, SpecialInstructions, DeliveryRF, ManifestId, Price,
            FMSInvoiceNo, ItemCount, CreatedOn, DeadWeight, CubicWeight, LengthInCm,
            WidthInCm, HeightInCm, LabelColour, ConsignmentItemId, Loaded, ProcessId,
            RecordSource, RecordSourceId, ValidFrom, ValidTo, IsCurrent
        )
        SELECT DISTINCT
            `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(CAST(Stg.LabelNumber AS STRING),'^') AS LabelNo_HSK,
            CAST(Stg.LabelNumber AS STRING)      AS LabelNo,
            Stg.CountryId, 
            IFNULL(CAST(cty.CountryName AS STRING), 'Unknown'),
            Stg.WebCustomerId,
            Stg.CustomerId,
            Stg.ReceiverContactName,
            Stg.ReceiverAddress1,
            Stg.ReceiverAddress2,
            Stg.ReceiverSuburb,
            Stg.ReceiverPostcode,
            Stg.ReceiverPhone,
            Stg.ReceiverEmail,
            Stg.PrintedOn,
            Stg.Reference,
            Stg.SpecialInstructions,
            Stg.DestinationRF,
            Stg.ManifestId,
            Stg.Price,
            Stg.InvoiceNo,
            Stg.ItemCount,
            Stg.CreatedOn,
            Stg.WeightDead,
            Stg.WeightCubic,
            Stg.Length,
            Stg.Width,
            Stg.Height,
            Stg.Colour,
            Stg.ConsignmentItemId,
            Loaded,
            ProcessID,
            RecordSource,
            Stg.ConsignmentItemId,
            Loaded,
            DefaultValidTo,
            1
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_ConsignmentItem_Stg` Stg
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Country` cty 
            ON CAST(cty.CountryCode AS STRING) = CAST(Stg.CountryId AS STRING)
        WHERE NOT EXISTS (
            SELECT 1
            FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_FLE` AS Tgt
            WHERE Tgt.LabelNo_HSK = `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(CAST(Stg.LabelNumber AS STRING),'^')
              AND Tgt.IsCurrent   = 1
        );

        SET Inserted = @@ROW_COUNT;
        SET Result   = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed';
        SET ErrorMessage = @@error.message;
    END;

    SET Ended = CURRENT_DATETIME();
    CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
        Component, ProcessID, Started, Ended, Result, ErrorMessage, Inserted, Updated, -1
    );

END;