-- ==========================================================================================
-- Routine:		Load_LNK_Invoice_Label
-- Description: Loads Invoice-Label relationships into into [dv].[LNK_Invoice_Label]
-- Example:		Exec [dv].[Load_LNK_Invoice_Label] 123 
-- History:
--	19/11/2019  P. Waldron		Routine Written
-- ==========================================================================================

CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_LNK_Invoice_Label`(
    IN p_ProcessID INT64
)
OPTIONS(strict_mode=false)
BEGIN
    DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Component STRING DEFAULT 'dv_Load_LNK_Invoice_Label';
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;

    -- Static RecordSource as per the original T-SQL default value
    DECLARE v_RecordSource STRING DEFAULT 'FMS_InvoiceLines';

    BEGIN
        -- A MERGE statement handles the "Insert if Not Exists" Link load pattern.
        -- Identifiers use the Jinja2 template and underscore schema naming.
        MERGE INTO `{{ project_id }}.{{ target_dataset_id }}.dv_LNK_Invoice_Label` AS Tgt
        USING (
            SELECT DISTINCT
                `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(CONCAT(CAST(stg.InvoiceNumber AS STRING), '^', stg.RFCode, '^', stg.Label)) AS Invoice_Label_HSK,
                `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(CONCAT(CAST(stg.InvoiceNumber AS STRING), '^', stg.RFCode)) AS Invoice_HSK,
                `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(stg.RFCode) AS FranchiseeCode_HSK,
                `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(TRIM(stg.Label)) AS LabelNo_HSK,
                stg.InvoiceNumber,
                stg.RFCode AS FranchiseeCode,
                TRIM(stg.Label) AS LabelNo
            FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_FMS_InvoiceBooks_Stg` AS stg
            WHERE EXISTS (
                SELECT 1 
                FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_FMS_InvoiceHead_Stg` AS h 
                WHERE h.InvoiceNumber = stg.InvoiceNumber 
                  AND h.RFCode = stg.RFCode
            )
        ) AS Src
        ON Tgt.Invoice_Label_HSK = Src.Invoice_Label_HSK
        WHEN NOT MATCHED THEN
            INSERT (
                Invoice_Label_HSK, 
                Invoice_HSK,
                FranchiseeCode_HSK,
                LabelNo_HSK,
                InvoiceNumber,
                FranchiseeCode,
                LabelNo,
                Loaded,
                ProcessId,
                RecordSource,
                RecordSourceId
            )
            VALUES (
                Src.Invoice_Label_HSK,
                Src.Invoice_HSK,
                Src.FranchiseeCode_HSK,
                Src.LabelNo_HSK,
                Src.InvoiceNumber,
                Src.FranchiseeCode,
                Src.LabelNo,
                v_Loaded,
                p_ProcessID,
                v_RecordSource,
                NULL
            );

        -- Capture the number of new records inserted
        SET v_Inserted = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Final Log Call (Handles both Success and Failure metrics)
    CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
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