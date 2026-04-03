CREATE OR REPLACE PROCEDURE `dv.Load_LNK_Label_InterBranch`(
    IN p_ProcessID INT64,
    IN p_RecordSource STRING
)
BEGIN
    -- All DECLARE statements must be at the very top of the BEGIN...END block
    DECLARE v_Component STRING DEFAULT 'dv.Load_LNK_Label_InterBranch';
    DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;
    
    DECLARE v_Loaded TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_DefaultValidFrom TIMESTAMP DEFAULT TIMESTAMP('1900-01-01');
    DECLARE v_DefaultValidTo TIMESTAMP DEFAULT TIMESTAMP('9999-12-31');

    -- Handle default parameter logic if p_RecordSource is passed as NULL
    SET p_RecordSource = IFNULL(p_RecordSource, 'InterBranchAU');

    BEGIN
        -- Using MERGE to handle the "Insert if Not Exists" logic in a single scan.
        -- This replaces the INSERT...WHERE NOT EXISTS pattern for better slot efficiency.
        MERGE INTO `dv.LNK_Label_InterBranch` AS Tgt
        USING (
            SELECT 
                -- Hashing logic: BigQuery CONCAT replaces the '+' operator.
                -- Assuming GetHashKey is migrated as a BigQuery UDF.
                `dbo.GetHashKey`(
                    CONCAT(
                        Country, '^', 
                        LabelNo, '^', 
                        CAST(BatchId AS STRING), '^', 
                        InvoiceFromRF, '^', 
                        InvoiceToRF
                    )
                ) AS Label_InterBranch_HSK,
                `dbo.GetHashKey`(CONCAT(Country, '^', LabelNo)) AS LabelNo_HSK,
                LabelNo,
                Country,
                InvoiceFromRF,
                InvoiceToRF,
                BatchId
            FROM `Staging.Label_InterBranch_Stg`
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
                NULL -- Replaces the static NULL for RecordSourceID
            );

        -- Capture total affected rows
        SET v_Inserted = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Final Log Call (Handles both Success and Failure)
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