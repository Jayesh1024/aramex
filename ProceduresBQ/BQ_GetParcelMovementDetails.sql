-- ==========================================================================================
-- Routine:     BQ_GetParcelMovementDetails
-- Description: Gets parcel movement details by country and invoice date
--              BigQuery compatible version of GetParcelMovementDetails
--              Note: CREATE PROCEDURE replaced with CREATE OR REPLACE PROCEDURE.
--                    Parameters use IN syntax.
--                    DATEADD(MONTH,-1,x) → DATE_SUB(x, INTERVAL 1 MONTH).
--                    WITH (NOLOCK) hints removed.
--                    LEFT(str,n) → SUBSTR(str,1,n).
--                    BETWEEN preserved (BQ supports it).
--                    UNION preserved (BQ supports it).
--                    Commented-out lines preserved as-is.
-- Example:     CALL rpt.BQ_GetParcelMovementDetails(1, '2022-01-01')
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.BQ_GetParcelMovementDetails`(
    IN CountryCode INT64,
    IN InvoiceFromDate DATE
)
BEGIN

    -- DECLARE @InvoiceToDate date = @InvoiceFromDate  →  same value
    DECLARE InvoiceToDate DATE DEFAULT InvoiceFromDate;
    --DECLARE InvoiceFromRF STRING DEFAULT 'SYD';
    --DECLARE InvoiceToRF   STRING DEFAULT 'ADL';

    -- BQ does not support standalone CTEs outside of a SELECT.
    -- The WITH ... SELECT pattern is preserved inside the final SELECT statement.

    -- Con Item DLBS
    SELECT
        LabelNo,
        l.CountryCode,
        FromRf                                              AS PickupRF,
        ToRf                                               AS DeliveryRF,
        h.InvoiceFromRF,
        h.InvoiceToRF,
        h.InvoiceDate,
        l.DLBSBatchId                                      AS BatchId,
        DLBSInvoiceNo                                      AS InvoiceNo,
        DLBSprice                                          AS Price,
        'MFW DLBS'                                         AS Type,
        SUBSTR(LabelNo, 1, 2)                              AS Product,
        IF(WeightPriced > 3 OR SatchelSize = 'A2', 0.05, 0.025) AS WeightPerc,
        l.CustomerId                                       AS FMSCustomerID,
        NULL                                               AS OESCustomerID
        --, DLBSTax AS Tax, DLBSTotal AS Total
    FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF` l
    -- WITH (NOLOCK) removed
    INNER JOIN (
        SELECT DeliveryRFInvoiceNo, DLBSBatchId,
               DeliveryRF AS InvoiceFromRF,
               PickupRF   AS InvoiceToRF,
               DeliveryRFInvoiceDate AS InvoiceDate
        FROM DLBSInvoiceHeader
        WHERE CountryId = CountryCode
          AND DeliveryRFInvoiceDate BETWEEN InvoiceFromDate AND InvoiceToDate
        --AND PickupRF = InvoiceToRF AND DeliveryRF = InvoiceFromRF
    ) h ON l.DLBSBatchId = h.DLBSBatchId AND l.DLBSInvoiceNo = h.DeliveryRFInvoiceNo
    WHERE l.CountryCode = CountryCode AND IsCurrent = 1

    UNION ALL

    -- Con Item PLBS
    SELECT
        LabelNo,
        l.CountryCode,
        FromRf,
        ToRf,
        h.InvoiceFromRF,
        h.InvoiceToRF,
        h.InvoiceDate,
        l.PLBSBatchId                                      AS BatchId,
        PLBSInvoiceNo                                      AS InvoiceNo,
        PLBSprice                                          AS Price,
        'MFW PLBS'                                        AS Type,
        SUBSTR(LabelNo, 1, 2)                              AS Product,
        0,
        l.CustomerId,
        NULL
    FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF` l
    -- WITH (NOLOCK) removed
    INNER JOIN (
        SELECT PickupRFInvoiceNo, PLBSBatchId,
               PickupRF   AS InvoiceFromRF,
               DeliveryRF AS InvoiceToRF,
               PickupRFInvoiceDate AS InvoiceDate
        FROM PLBSInvoiceHeader
        WHERE CountryId = CountryCode
          AND PickupRFInvoiceDate BETWEEN InvoiceFromDate AND InvoiceToDate
        --AND DeliveryRF = InvoiceToRF AND PickupRF = InvoiceFromRF
    ) h ON l.PLBSBatchId = h.PLBSBatchId AND l.PLBSInvoiceNo = h.PickupRFInvoiceNo
    WHERE l.CountryCode = CountryCode AND IsCurrent = 1

    UNION ALL

    -- Con Item Service DLBS
    SELECT
        l.LabelNo,
        l.CountryCode,
        FromRf,
        ToRf,
        h.InvoiceFromRF,
        h.InvoiceToRF,
        h.InvoiceDate,
        l.DLBSBatchId                                      AS BatchId,
        l.DLBSInvoiceNo                                    AS InvoiceNo,
        l.DLBSPrice                                        AS Price,
        'MFW DLBS'                                        AS Type,
        SUBSTR(l.LabelNo, 1, 2)                            AS Product,
        IF(WeightPriced > 3 OR SatchelSize = 'A2', 0.05, 0.025),
        m.CustomerId,
        NULL
    FROM `{{ project_id }}.{{ target_dataset_id }}.dv_LSAT_Label_Product_ServiceItem` l
    -- WITH (NOLOCK) removed
    INNER JOIN (
        SELECT DeliveryRFInvoiceNo, DLBSBatchId,
               DeliveryRF AS InvoiceFromRF,
               PickupRF   AS InvoiceToRF,
               DeliveryRFInvoiceDate AS InvoiceDate
        FROM DLBSInvoiceHeader
        WHERE CountryId = CountryCode
          AND DeliveryRFInvoiceDate BETWEEN InvoiceFromDate AND InvoiceToDate
    ) h ON l.DLBSBatchId = h.DLBSBatchId AND l.DLBSInvoiceNo = h.DeliveryRFInvoiceNo
    LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF` m
        -- WITH (NOLOCK) removed
        ON l.LabelNo = m.LabelNo AND m.IsCurrent = 1
    WHERE l.CountryCode = CountryCode AND l.IsCurrent = 1

    UNION ALL

    -- Con Item Service PLBS
    SELECT
        l.LabelNo,
        l.CountryCode,
        FromRf,
        ToRf,
        h.InvoiceFromRF,
        h.InvoiceToRF,
        h.InvoiceDate,
        l.PLBSBatchId                                      AS BatchId,
        l.PLBSInvoiceNo                                    AS InvoiceNo,
        l.PLBSPrice                                        AS Price,
        'MFW PLBS'                                        AS Type,
        SUBSTR(l.LabelNo, 1, 2)                            AS Product,
        0,
        m.CustomerId,
        NULL
    FROM `{{ project_id }}.{{ target_dataset_id }}.dv_LSAT_Label_Product_ServiceItem` l
    -- WITH (NOLOCK) removed
    INNER JOIN (
        SELECT PickupRFInvoiceNo, PLBSBatchId,
               PickupRF   AS InvoiceFromRF,
               DeliveryRF AS InvoiceToRF,
               PickupRFInvoiceDate AS InvoiceDate
        FROM PLBSInvoiceHeader
        WHERE CountryId = CountryCode
          AND PickupRFInvoiceDate BETWEEN InvoiceFromDate AND InvoiceToDate
    ) h ON l.PLBSBatchId = h.PLBSBatchId AND l.PLBSInvoiceNo = h.PickupRFInvoiceNo
    LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF` m
        -- WITH (NOLOCK) removed
        ON l.LabelNo = m.LabelNo AND m.IsCurrent = 1
    WHERE l.CountryCode = CountryCode AND l.IsCurrent = 1

    UNION ALL

    -- Legacy DLBS excluding Excess and MFW
    SELECT
        i.LabelNo,
        i.CountryCode,
        InvoiceToRF                                        AS PickupRF,
        InvoiceFromRF                                      AS DeliveryRF,
        InvoiceFromRF,
        InvoiceToRF,
        b.InvoiceDate,
        i.BatchId,
        InvoiceNumber                                      AS InvoiceNo,
        IF(SUBSTR(i.LabelNo, 1, 2) IN ('MP','MS','MX','FX'), 0, i.Price) AS Price,
        'Legacy DLBS'                                     AS Type,
        p.Description                                      AS Product,
        0.05,
        l.FMSCustomerID,
        l.OESCustomerID
    FROM Fact_Interbranch i
    -- WITH (NOLOCK) removed
    INNER JOIN (
        -- DLBSBatching CTE inlined:
        -- DATEADD(MONTH,-1,Date) → DATE_SUB(Date, INTERVAL 1 MONTH)
        SELECT
            CountryCode,
            BatchId,
            DATE_SUB(Date, INTERVAL 1 MONTH) AS InvoiceDate
        FROM DLBSRFBatching
        WHERE CountryCode = CountryCode
          AND DATE_SUB(Date, INTERVAL 1 MONTH) BETWEEN InvoiceFromDate AND InvoiceToDate
    ) b ON i.CountryCode = b.CountryCode AND i.BatchId = b.BatchId
    LEFT JOIN Dim_Product p
        -- WITH (NOLOCK) removed
        ON i.ProductID = p.ProductId AND i.Country = p.Country
    LEFT JOIN Dim_Label l
        -- WITH (NOLOCK) removed
        ON i.LabelNo = l.LabelNo AND l.CountryCode = i.CountryCode
    WHERE i.LabelNo NOT IN (
        SELECT LabelNo FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF`
        WHERE CountryCode = CountryCode AND IsCurrent = 1 AND (DLBSBatchId > 0 OR PLBSBatchId > 0)
    )
    AND i.LabelNo NOT IN (
        SELECT LabelNo FROM `{{ project_id }}.{{ target_dataset_id }}.dv_LSAT_Label_Product_ServiceItem`
        WHERE CountryCode = CountryCode AND IsCurrent = 1 AND (DLBSBatchId > 0 OR PLBSBatchId > 0)
    )
    AND i.ProductID NOT IN ('523','371','598'); -- remove the products as requested by Finance team
    --AND InvoiceFromRF = InvoiceFromRF AND InvoiceToRF = InvoiceToRF

END;
