CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_FMS_Book_Labels_Hist`(
    IN p_ProcessID  INT64
)
BEGIN

    DECLARE v_Component    STRING DEFAULT 'dv_Load_FMS_Book_Labels_Hist';
    DECLARE v_Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Ended        DATETIME;
    DECLARE v_Result       STRING DEFAULT '';
    DECLARE v_ErrorMessage STRING DEFAULT NULL;
    DECLARE v_Inserted     INT64 DEFAULT 0;
    DECLARE v_Updated      INT64 DEFAULT 0;

    BEGIN

        INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label` (
            LabelNo,
            CountryCode,
            Country,
            FMSInvoiceID,
            FMSProductID,
            FMSCustomerID,
            FMSRfID,
            FKSource,
            LabelPrefix,
            CreateDate,
            Created,
            Updated,
            ProcessId
        )
        WITH InvLabel AS (
            SELECT
                L.LabelNo,
                L.LabelNo AS FirstLabelNo,
                SUBSTR(L.LabelNo, 1, 2) AS LabelPrefix,
                SAFE_CAST(RIGHT(L.LabelNo, 10) AS INT64) AS IntLabelNo,
                SAFE_CAST(RIGHT(L.LabelNo, 10) AS INT64) + P.LabelsPerBook AS EndIntLabelNo,
                L.InvoiceNumber,
                L.FranchiseeCode,
                P.LabelsPerBook,
                P.ProductCode,
                P.ProductId,
                LI.Country,
                SAFE_CAST(RIGHT(LI.CustomerKey, 4) AS INT64) AS FMSCustomerID
            FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Invoice_Label` AS L
            JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_InvoiceLine` AS LI
                ON LI.InvoiceNumber = L.InvoiceNumber
                AND LI.FranchiseeCode = L.FranchiseeCode
                AND LI.ProductCode = SUBSTR(L.LabelNo, 1, LENGTH(LI.ProductCode))
            JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Product` AS P
                ON P.ProductCode = LI.ProductCode
                AND P.IsCurrent = 1
                AND P.Country = LI.Country
            WHERE P.LabelsPerBook > 1
        ),
        -- GENERATE_ARRAY correctly produces offsets 0 through (LabelsPerBook - 1)
        MissingLabels AS (
            SELECT
                CONCAT(
                    Inv.LabelPrefix,
                    LPAD(CAST(Inv.IntLabelNo + Offs AS STRING), 10, '0')
                ) AS LabelNo,
                Inv.IntLabelNo + Offs AS IntLabelNo,
                Inv.FirstLabelNo,
                Inv.EndIntLabelNo,
                Inv.Country,
                Inv.LabelPrefix,
                Inv.LabelsPerBook,
                Inv.InvoiceNumber,
                Inv.FranchiseeCode,
                Inv.ProductId,
                Inv.FMSCustomerID
            FROM InvLabel AS Inv
            CROSS JOIN UNNEST(GENERATE_ARRAY(0, Inv.LabelsPerBook - 1)) AS Offs
        ),
        D AS (
            SELECT
                D.LabelNo
            FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label` AS D
        )
        SELECT
            M.LabelNo,
            CASE
                WHEN M.Country = 'Australia' THEN 1
                WHEN M.Country = 'New Zealand' THEN 6
                WHEN M.Country = 'South Africa' THEN 24
                ELSE NULL
            END AS CountryCode,
            M.Country,
            M.InvoiceNumber,
            M.ProductId,
            M.FMSCustomerID,
            M.FranchiseeCode,
            'GeneratedBookLabel',
            M.LabelPrefix,
            v_Started,
            v_Started,
            v_Started,
            p_ProcessID
        FROM MissingLabels AS M
        LEFT JOIN D
            ON D.LabelNo = M.LabelNo
        WHERE D.LabelNo IS NULL
          AND M.LabelNo >= M.FirstLabelNo;

        SET v_Inserted = @@row_count;
        SET v_Result = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Record load metrics in log
    SET v_Ended = CURRENT_DATETIME();
    CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,
        v_Ended,
        v_Result,
        v_ErrorMessage,
        v_Inserted,
        v_Updated,
        -1
    );

END;
