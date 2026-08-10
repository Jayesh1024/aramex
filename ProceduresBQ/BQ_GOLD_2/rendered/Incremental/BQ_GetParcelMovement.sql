CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.rpt_GetParcelMovement` (
    IN p_CountryCode INT64, 
    IN p_InvoiceFromDate DATE, 
    IN p_InvoiceToDate DATE
)

--DECLARE @CountryCode int = 1
--DECLARE @InvoiceFromDate date = '2022-01-01'
--DECLARE @InvoiceToDate date = '2022-08-01';
--DECLARE @InvoiceFromRF char(3) = 'SYD'
--DECLARE @InvoiceToRF char(3) = 'ADL';

BEGIN

CREATE OR REPLACE TEMP TABLE Results AS
WITH
DLBSHeader AS (
    SELECT
        DeliveryRFInvoiceNo,
        DLBSBatchId,
        DeliveryRF AS InvoiceFromRF,
        PickupRF AS InvoiceToRF,
        DeliveryRFInvoiceDate AS InvoiceDate
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_DLBSInvoiceHeader`
    WHERE CountryId = p_CountryCode
      AND DeliveryRFInvoiceDate BETWEEN p_InvoiceFromDate AND p_InvoiceToDate
      -- AND PickupRF = p_InvoiceToRF AND DeliveryRF = p_InvoiceFromRF
),

PLBSHeader AS (
    SELECT
        PickupRFInvoiceNo,
        PLBSBatchId,
        PickupRF AS InvoiceFromRF,
        DeliveryRF AS InvoiceToRF,
        PickupRFInvoiceDate AS InvoiceDate
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_PLBSInvoiceHeader`
    WHERE CountryId = p_CountryCode
      AND PickupRFInvoiceDate BETWEEN p_InvoiceFromDate AND p_InvoiceToDate
      -- AND DeliveryRF = p_InvoiceToRF AND PickupRF = p_InvoiceFromRF
),

DLBSBatching AS (
    SELECT
        CountryCode,
        BatchId,
        DATE_SUB(Date, INTERVAL 1 MONTH) AS InvoiceDate
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_DLBSRFBatching`
    WHERE CountryCode = p_CountryCode
      AND DATE_SUB(Date, INTERVAL 1 MONTH) BETWEEN p_InvoiceFromDate AND p_InvoiceToDate
),

ParcelMovement AS (
    -- Con Item DLBS
    SELECT
        l.LabelNo,
        CAST(l.CountryCode AS STRING) AS CountryCode,
        h.InvoiceFromRF,
        h.InvoiceToRF,
        h.InvoiceDate,
        l.DLBSprice AS Price,
        (CASE WHEN l.WeightPriced > 3 OR UPPER(l.SatchelSize) = 'A2' THEN 0.05 ELSE 0.025 END) * l.DLBSPrice AS Bonus,
        l.CustomerId AS FMSCustomerID,
        CAST(NULL AS STRING) AS OESCustomerID,
        'MFW DLBS' AS Type
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF` l
    INNER JOIN DLBSHeader h
        ON l.DLBSBatchId = h.DLBSBatchId
        AND l.DLBSInvoiceNo = h.DeliveryRFInvoiceNo
    WHERE l.CountryCode = p_CountryCode
      AND l.IsCurrent = 1

    UNION DISTINCT

    -- Con Item PLBS
    SELECT
        l.LabelNo,
        CAST(l.CountryCode AS STRING) AS CountryCode,
        h.InvoiceFromRF,
        h.InvoiceToRF,
        h.InvoiceDate,
        l.PLBSprice AS Price,
        0 AS Bonus,
        l.CustomerId AS FMSCustomerID,
        CAST(NULL AS STRING) AS OESCustomerID,
        'MFW PLBS' AS Type
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF` l
    INNER JOIN PLBSHeader h
        ON l.PLBSBatchId = h.PLBSBatchId
        AND l.PLBSInvoiceNo = h.PickupRFInvoiceNo
    WHERE l.CountryCode = p_CountryCode
      AND l.IsCurrent = 1

    UNION DISTINCT

    -- Con Item Service DLBS
    SELECT
        l.LabelNo,
        CAST(l.CountryCode AS STRING) AS CountryCode,
        h.InvoiceFromRF,
        h.InvoiceToRF,
        h.InvoiceDate,
        l.DLBSPrice AS Price,
        (CASE WHEN m.WeightPriced > 3 OR UPPER(m.SatchelSize) = 'A2' THEN 0.05 ELSE 0.025 END) * l.DLBSPrice AS Bonus,
        m.CustomerId AS FMSCustomerID,
        CAST(NULL AS STRING) AS OESCustomerID,
        'MFW DLBS' AS Type
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Product_ServiceItem` l
    INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF` m
        ON l.LabelNo = m.LabelNo
        AND m.IsCurrent = 1
    INNER JOIN DLBSHeader h
        ON l.DLBSBatchId = h.DLBSBatchId
        AND l.DLBSInvoiceNo = h.DeliveryRFInvoiceNo
    WHERE l.CountryCode = p_CountryCode
      AND l.IsCurrent = 1

    UNION DISTINCT

    -- Con Item Service PLBS
    SELECT
        l.LabelNo,
        CAST(l.CountryCode AS STRING) AS CountryCode,
        h.InvoiceFromRF,
        h.InvoiceToRF,
        h.InvoiceDate,
        l.PLBSPrice AS Price,
        0 AS Bonus,
        m.CustomerId AS FMSCustomerID,
        CAST(NULL AS STRING) AS OESCustomerID,
        'MFW PLBS' AS Type
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Product_ServiceItem` l
    INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF` m
        ON l.LabelNo = m.LabelNo
        AND m.IsCurrent = 1
    INNER JOIN PLBSHeader h
        ON l.PLBSBatchId = h.PLBSBatchId
        AND l.PLBSInvoiceNo = h.PickupRFInvoiceNo
    WHERE l.CountryCode = p_CountryCode
      AND l.IsCurrent = 1

    UNION DISTINCT

    -- Legacy DLBS excluding Excess and MFW
    SELECT
        i.LabelNo,
        CAST(i.CountryCode AS STRING) AS CountryCode,
        i.InvoiceFromRF,
        i.InvoiceToRF,
        b.InvoiceDate,
        CASE WHEN UPPER(SUBSTR(i.LabelNo, 1, 2)) IN ('MP', 'MS', 'MX', 'FX') THEN 0 ELSE i.Price END AS Price,
        0.05 * CASE WHEN UPPER(SUBSTR(i.LabelNo, 1, 2)) IN ('MP', 'MS', 'MX', 'FX') THEN 0 ELSE i.Price END AS Bonus,
        l.FMSCustomerID,
        CAST(l.OESCustomerID AS STRING) AS OESCustomerID,
        'Legacy DLBS' AS Type
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Interbranch` i
    INNER JOIN DLBSBatching b
        ON CAST(i.CountryCode AS INT64) = b.CountryCode
        AND i.BatchId = b.BatchId
    -- Changed LEFT JOIN to INNER JOIN. In SQL Server, filtering on '1.LabelNo NOT IN' 
    -- implicitly forced this to act as an INNER JOIN by stripping out NULLs from unmatched rows.
    INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label` l
        ON i.LabelNo = l.LabelNo
        AND CAST(l.CountryCode AS STRING) = CAST(i.CountryCode AS STRING)

    -- alias targeting of SQL Server's '1.LabelNo'. 
    WHERE l.LabelNo NOT IN (
        SELECT LabelNo
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF`
        WHERE CountryCode = p_CountryCode
          AND IsCurrent = 1
          AND (DLBSBatchId > 0 OR PLBSBatchId > 0)
    )
    AND l.LabelNo NOT IN (
        SELECT LabelNo
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Product_ServiceItem`
        WHERE CountryCode = p_CountryCode
          AND IsCurrent = 1
          AND (DLBSBatchId > 0 OR PLBSBatchId > 0)
    )
    AND CAST(i.ProductID AS STRING) NOT IN ('523', '371', '598')
    -- AND InvoiceFromRF = p_InvoiceFromRF AND InvoiceToRF = p_InvoiceToRF
)

SELECT
    CountryCode,
    InvoiceFromRF,
    InvoiceToRF,
    InvoiceDate,
    FMSCustomerID,
    OESCustomerID,
    Type,
    COUNT(DISTINCT LabelNo) AS LabelCount,
    SUM(Price) AS Price,
    SUM(Bonus) AS Bonus
FROM ParcelMovement
GROUP BY
    CountryCode,
    InvoiceFromRF,
    InvoiceToRF,
    InvoiceDate,
    FMSCustomerID,
    OESCustomerID,
    Type;

END;