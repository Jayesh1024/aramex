-- ==========================================================================================
-- Routine:		Load_LNK_InvoiceLine
-- Description: Loads Invoice Lines into into [dv].[LNK_InvoiceLine]
-- Example:		Exec [dv].[Load_LNK_InvoiceLine] 123 
-- History:
--	19/11/2019  P. Waldron		Routine Written
--	24/02/2020  P. Waldron		Add RFCode to the Staging.FMS_InvoiceLines_Stg Join 
-- ==========================================================================================

CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_LNK_InvoiceLine`(
    IN p_ProcessID INT64,
    IN p_RecordSource STRING
)
OPTIONS(strict_mode=false)
BEGIN
    DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Component STRING DEFAULT 'dv_Load_LNK_InvoiceLine';
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;

    BEGIN
        -- A MERGE statement efficiently handles the "Insert if Not Exists" Link load pattern.
        -- Identifiers use the Jinja2 template for project/dataset and underscore schema naming.
        MERGE INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_InvoiceLine` AS Tgt
        USING (
            SELECT
                `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_GetHashKey`(CONCAT(CAST(dl.InvoiceNumber AS STRING), '^', dl.FranchiseeCode, '^', dl.CourierNumber, '^', dl.CustomerKey, '^', dl.ProductCode, '^', dl.Country), '^') AS InvoiceLine_HSK,
                `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_GetHashKey`(CONCAT(CAST(dl.InvoiceNumber AS STRING), '^', dl.FranchiseeCode), '^') AS Invoice_HSK,
                `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_GetHashKey`(dl.FranchiseeCode, '^') AS FranchiseeCode_HSK,
                `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_GetHashKey`(CONCAT(dl.FranchiseeCode, '^', dl.CourierNumber), '^') AS Courier_HSK,
                `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_GetHashKey`(dl.CustomerKey, '^') AS Customer_HSK,
                `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_GetHashKey`(CONCAT(dl.Country, '^', dl.ProductCode), '^') AS Product_HSK,
                dl.InvoiceNumber,
                dl.FranchiseeCode,
                dl.CourierNumber,
                dl.CustomerKey,
                dl.ProductCode,
                dl.Country
            FROM (
                SELECT DISTINCT
                    ih.InvoiceNumber,
                    ih.RFCode AS FranchiseeCode,
                    ih.CourierInvoiceBelongsTo AS CourierNumber,
                    cust.CustomerKey,
                    ps.Code AS ProductCode,
                    c.CountryName AS Country
                FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_FMS_InvoiceHead_Stg` AS ih
                JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_FMS_InvoiceLines_Stg` AS il 
                    ON il.InvoiceNumber = ih.InvoiceNumber AND ih.RFCode = il.RFId
                JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Country` AS c 
                    ON c.CountryCode = il.NMId 
                JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Product_Stg` AS ps 
                    ON ps.ProductId = il.ProductId AND ps.Country = c.CountryName 
                -- Optimized subquery replacing CROSS APPLY
                JOIN (
                    SELECT CustomerKey, CustomerID, RFId
                    FROM (
                        SELECT 
                            cs.CustomerKey, 
                            cs.CustomerID, 
                            cs.RFId,
                            ROW_NUMBER() OVER(PARTITION BY cs.CustomerID, cs.RFId ORDER BY cs.Active DESC) AS rn
                        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_FMS_Customer_Stg` AS cs
                    )
                    WHERE rn = 1
                ) AS cust 
                    ON cust.CustomerID = ih.CustomerId AND cust.RFId = il.RFId
            ) AS dl
        ) AS Src
        ON Tgt.InvoiceLine_HSK = Src.InvoiceLine_HSK
        WHEN NOT MATCHED THEN
            INSERT (
                InvoiceLine_HSK, 
                Invoice_HSK,
                FranchiseeCode_HSK,
                Courier_HSK,
                Customer_HSK,
                Product_HSK,
                InvoiceNumber,
                FranchiseeCode,
                CourierNumber,
                CustomerKey,
                ProductCode,
                Country,
                Loaded,
                ProcessId,
                RecordSource,
                RecordSourceId
            )
            VALUES (
                Src.InvoiceLine_HSK,
                Src.Invoice_HSK,
                Src.FranchiseeCode_HSK,
                Src.Courier_HSK,
                Src.Customer_HSK,
                Src.Product_HSK,
                Src.InvoiceNumber,
                Src.FranchiseeCode,
                Src.CourierNumber,
                Src.CustomerKey,
                Src.ProductCode,
                Src.Country,
                v_Loaded,
                p_ProcessID,
                p_RecordSource,
                NULL
            );

        -- Capture total affected rows (Inserted)
        SET v_Inserted = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Final Log Call (Handles Success and Failure metrics)
    CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,
        CURRENT_DATETIME(),
        v_Result,
        v_ErrorMessage,
        v_Inserted,
        v_Updated,
        -1
    );
END;