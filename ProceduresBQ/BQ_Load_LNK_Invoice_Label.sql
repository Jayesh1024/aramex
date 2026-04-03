CREATE OR REPLACE PROCEDURE `dv.Load_LNK_Invoice_Label`(
    IN p_ProcessID INT64,
    IN p_RecordSource STRING
)
BEGIN
    DECLARE v_Loaded TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Component STRING DEFAULT 'dv.Load_LNK_Invoice_Label';
    DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;

    -- Handle default parameter value from T-SQL signature
    IF p_RecordSource IS NULL THEN
        SET p_RecordSource = 'FMS_InvoiceLines';
    END IF;

    BEGIN
        -- A MERGE statement efficiently handles the "Insert if Not Exists" Link load pattern,
        -- collapsing the multiple CTEs from the SQL Server version into a single optimized operation.
        MERGE INTO `dv.LNK_Invoice_Label` AS Tgt
        USING (
            SELECT DISTINCT
                `dbo.GetHashKey`(CONCAT(CAST(stg.InvoiceNumber AS STRING), '^', stg.RFCode, '^', stg.Label)) AS Invoice_Label_HSK,
                `dbo.GetHashKey`(CONCAT(CAST(stg.InvoiceNumber AS STRING), '^', stg.RFCode)) AS Invoice_HSK,
                `dbo.GetHashKey`(stg.RFCode) AS FranchiseeCode_HSK,
                `dbo.GetHashKey`(TRIM(stg.Label)) AS LabelNo_HSK,
                stg.InvoiceNumber,
                stg.RFCode AS FranchiseeCode,
                TRIM(stg.Label) AS LabelNo
            FROM `Staging.FMS_InvoiceBooks_Stg` AS stg
            WHERE EXISTS (
                SELECT 1 
                FROM `Staging.FMS_InvoiceHead_Stg` AS h 
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
                p_RecordSource,
                NULL -- Replaces the NULL as RecordSourceId from the T-SQL static SELECT
            );

        -- Capture the number of new records inserted
        SET v_Inserted = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Final Log Call (Handles both Success and Failure metrics)
    CALL `Staging.SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,
        CURRENT_TIMESTAMP(),
        v_Result,
        v_ErrorMessage,
        v_Inserted,
        v_Updated,
        -1
    );
END;