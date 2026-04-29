-- ==========================================================================================
-- Routine:     Load_LNK_Label_InterBranch
-- Description: Loads LNK_Label_InterBranch from Staging.Label_Interbranch_Stg for a country
-- Example:     Exec [dv].[Load_LNK_Label_InterBranch] 659,  'InterBranchAU' 
-- History:
--  15/08/2020  P. Waldron      Routine Written
--  21/06/2022  B. Woods         Cloned
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_LNK_Label_InterBranch`(
    IN p_ProcessID INT64,
    IN p_RecordSource STRING
)
OPTIONS(strict_mode=false)
BEGIN
    -- 1. All DECLARE statements must be at the very top of the BEGIN...END block
    DECLARE v_Component STRING DEFAULT 'dv_Load_LNK_Label_InterBranch';
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;
    
    DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_DefaultValidFrom TIMESTAMP DEFAULT TIMESTAMP('1900-01-01');
    DECLARE v_DefaultValidTo TIMESTAMP DEFAULT TIMESTAMP('9999-12-31');

    BEGIN
        -- Using MERGE to handle the "Insert if Not Exists" logic in a single scan.
        -- All table and function identifiers use Jinja2 templates and underscore schema naming.
        MERGE INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Label_Interbranch_Deprecated` AS Tgt
        USING (
            SELECT 
                `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_GetHashKey`(
                    CONCAT(
                        Country, '^', 
                        LabelNo, '^', 
                        CAST(BatchId AS STRING), '^', 
                        InvoiceFromRF, '^', 
                        InvoiceToRF
                    ),
                    '^'
                ) AS Label_InterBranch_HSK,
                `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_GetHashKey`(CONCAT(Country, '^', LabelNo), '^') AS LabelNo_HSK,
                LabelNo,
                Country,
                InvoiceFromRF,
                InvoiceToRF,
                BatchId
            FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Label_Interbranch_Stg`
        ) AS Src
        ON Tgt.Label_InterBranch_HSK = Src.Label_InterBranch_HSK
        WHEN NOT MATCHED THEN
            INSERT (
                Label_InterBranch_HSK,
                LabelNo_HSK,
                LabelNo,
                Country,
                InvoiceFromRF,
                InvoiceToRF,
                BatchId,
                Loaded,
                ProcessID,
                RecordSource,
                RecordSourceId
            )
            VALUES (
                Src.Label_InterBranch_HSK,
                Src.LabelNo_HSK,
                Src.LabelNo,
                Src.Country,
                Src.InvoiceFromRF,
                Src.InvoiceToRF,
                Src.BatchId,
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

    -- Final Log Call (Handles both Success and Failure metrics)
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