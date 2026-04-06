-- ==========================================================================================
-- Routine:     BQ_GetParcelMovementDetails
-- Description: Returns parcel movement details by country and invoice date
--              BigQuery compatible version of GetParcelMovementDetails
--              Note: CREATE PROCEDURE with parameters preserved using BQ syntax.
--                    DECLARE @var = @param replaced with DECLARE var DEFAULT param.
--                    DATEADD(MONTH,-1,x) → DATE_ADD(x, INTERVAL -1 MONTH).
--                    BETWEEN preserved (BQ supports it).
--                    WITH (NOLOCK) removed.
--                    dbo.GetFmsProductIdForLabel → user-defined function call preserved as-is
--                      (must exist as BQ UDF or be replaced with equivalent logic).
--                    LEFT(x, n) → SUBSTR(x, 1, n).
--                    Commented-out filter lines preserved as comments.
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE rpt.BQ_GetParcelMovementDetails(
    IN CountryCode INT64,
    IN InvoiceFromDate DATE
)
BEGIN

    DECLARE InvoiceToDate DATE DEFAULT InvoiceFromDate;
    -- DECLARE InvoiceFromRF STRING DEFAULT 'SYD';
    -- DECLARE InvoiceToRF   STRING DEFAULT 'ADL';

    -- CTE: DLBS Invoice headers for the given country and date range
    -- DATEADD(MONTH,-1,Date) → DATE_ADD(Date, INTERVAL -1 MONTH)
    -- WITH (NOLOCK) removed throughout
    SELECT
        LabelNo,
        src.CountryCode,
        FromRf                                          AS PickupRF,
        ToRf                                           AS DeliveryRF,
        h_dlbs.InvoiceFromRF,
        h_dlbs.InvoiceToRF,
        h_dlbs.InvoiceDate,
        l.DLBSBatchId                                  AS BatchId,
        l.DLBSInvoiceNo                                AS InvoiceNo,
        l.DLBSprice                                    AS Price,
        'MFW DLBS'                                     AS Type,
        SUBSTR(LabelNo, 1, 2)                          AS Product,
        CASE WHEN WeightPriced > 3 OR SatchelSize = 'A2' THEN 0.05 ELSE 0.025 END AS WeightPerc,
        l.CustomerId                                   AS FMSCustomerID,
        NULL                                           AS OESCustomerID
    FROM dv.SAT_Label_Allocation_MF l
    -- WITH (NOLOCK) removed
    INNER JOIN (
        -- Inline DLBSHeader CTE
        SELECT DeliveryRFInvoiceNo, DLBSBatchId,
               DeliveryRF AS InvoiceFromRF,
               PickupRF   AS InvoiceToRF,
               DeliveryRFInvoiceDate AS InvoiceDate
        FROM DLBSInvoiceHeader
        WHERE CountryId = CountryCode
          AND DeliveryRFInvoiceDate BETWEEN InvoiceFromDate AND InvoiceToDate
        -- AND PickupRF = InvoiceToRF AND DeliveryRF = InvoiceFromRF
    ) h_dlbs
        ON l.DLBSBatchId = h_dlbs.DLBSBatchId
       AND l.DLBSInvoiceNo = h_dlbs.DeliveryRFInvoiceNo
    CROSS JOIN (SELECT CountryCode) src
    WHERE l.CountryCode = CountryCode
      AND l.IsCurrent   = 1

    UNION ALL

    -- Con Item PLBS
    SELECT
        LabelNo,
        l.CountryCode,
        FromRf,
        ToRf,
        h_plbs.InvoiceFromRF,
        h_plbs.InvoiceToRF,
        h_plbs.InvoiceDate,
        l.PLBSBatchId   AS BatchId,
        l.PLBSInvoiceNo AS InvoiceNo,
        l.PLBSprice     AS Price,
        'MFW PLBS'      AS Type,
        SUBSTR(LabelNo, 1, 2) AS Product,
        0,
        l.CustomerId,
        NULL
    FROM dv.SAT_Label_Allocation_MF l
    INNER JOIN (
        -- Inline PLBSHeader CTE
        SELECT PickupRFInvoiceNo, PLBSBatchId,
               PickupRF   AS InvoiceFromRF,
               DeliveryRF AS InvoiceToRF,
               PickupRFInvoiceDate AS InvoiceDate
        FROM PLBSInvoiceHeader
        WHERE CountryId = CountryCode
          AND PickupRFInvoiceDate BETWEEN InvoiceFromDate AND InvoiceToDate
        -- AND DeliveryRF = InvoiceToRF AND PickupRF = InvoiceFromRF
    ) h_plbs
        ON l.PLBSBatchId = h_plbs.PLBSBatchId
       AND l.PLBSInvoiceNo = h_plbs.PickupRFInvoiceNo
    WHERE l.CountryCode = CountryCode
      AND l.IsCurrent   = 1

    UNION ALL

    -- Con Item Service DLBS
    SELECT
        l.LabelNo,
        l.CountryCode,
        FromRf,
        ToRf,
        h_dlbs2.InvoiceFromRF,
        h_dlbs2.InvoiceToRF,
        h_dlbs2.InvoiceDate,
        l.DLBSBatchId   AS BatchId,
        l.DLBSInvoiceNo AS InvoiceNo,
        l.DLBSPrice     AS Price,
        'MFW DLBS'      AS Type,
        SUBSTR(l.LabelNo, 1, 2) AS Product,
        CASE WHEN WeightPriced > 3 OR SatchelSize = 'A2' THEN 0.05 ELSE 0.025 END,
        m.CustomerId,
        NULL
    FROM dv.LSAT_Label_Product_ServiceItem l
    INNER JOIN (
        -- Inline DLBSHeader CTE (reused)
        SELECT DeliveryRFInvoiceNo, DLBSBatchId,
               DeliveryRF AS InvoiceFromRF,
               PickupRF   AS InvoiceToRF,
               DeliveryRFInvoiceDate AS InvoiceDate
        FROM DLBSInvoiceHeader
        WHERE CountryId = CountryCode
          AND DeliveryRFInvoiceDate BETWEEN InvoiceFromDate AND InvoiceToDate
    ) h_dlbs2
        ON l.DLBSBatchId = h_dlbs2.DLBSBatchId
       AND l.DLBSInvoiceNo = h_dlbs2.DeliveryRFInvoiceNo
    LEFT JOIN dv.SAT_Label_Allocation_MF m
        ON l.LabelNo = m.LabelNo AND m.IsCurrent = 1
    WHERE l.CountryCode = CountryCode
      AND l.IsCurrent   = 1

    UNION ALL

    -- Con Item Service PLBS
    SELECT
        l.LabelNo,
        l.CountryCode,
        FromRf,
        ToRf,
        h_plbs2.InvoiceFromRF,
        h_plbs2.InvoiceToRF,
        h_plbs2.InvoiceDate,
        l.PLBSBatchId   AS BatchId,
        l.PLBSInvoiceNo AS InvoiceNo,
        l.PLBSPrice     AS Price,
        'MFW PLBS'      AS Type,
        SUBSTR(l.LabelNo, 1, 2) AS Product,
        0,
        m.CustomerId,
        NULL
    FROM dv.LSAT_Label_Product_ServiceItem l
    INNER JOIN (
        -- Inline PLBSHeader CTE (reused)
        SELECT PickupRFInvoiceNo, PLBSBatchId,
               PickupRF   AS InvoiceFromRF,
               DeliveryRF AS InvoiceToRF,
               PickupRFInvoiceDate AS InvoiceDate
        FROM PLBSInvoiceHeader
        WHERE CountryId = CountryCode
          AND PickupRFInvoiceDate BETWEEN InvoiceFromDate AND InvoiceToDate
    ) h_plbs2
        ON l.PLBSBatchId = h_plbs2.PLBSBatchId
       AND l.PLBSInvoiceNo = h_plbs2.PickupRFInvoiceNo
    LEFT JOIN dv.SAT_Label_Allocation_MF m
        ON l.LabelNo = m.LabelNo AND m.IsCurrent = 1
    WHERE l.CountryCode = CountryCode
      AND l.IsCurrent   = 1

    UNION ALL

    -- Legacy DLBS excluding Excess and MFW
    -- DATE_ADD(Date, INTERVAL -1 MONTH) replaces DATEADD(MONTH,-1,Date)
    SELECT
        i.LabelNo,
        i.CountryCode,
        InvoiceToRF     AS PickupRF,
        InvoiceFromRF   AS DeliveryRF,
        b_dlbs.InvoiceFromRF,
        b_dlbs.InvoiceToRF,
        b_dlbs.InvoiceDate,
        i.BatchId,
        InvoiceNumber   AS InvoiceNo,
        CASE WHEN SUBSTR(i.LabelNo, 1, 2) IN ('MP','MS','MX','FX') THEN 0 ELSE i.Price END AS Price,
        'Legacy DLBS'   AS Type,
        p.Description   AS Product,
        0.05,
        l.FMSCustomerID,
        l.OESCustomerID
    FROM Fact_Interbranch i
    INNER JOIN (
        -- Inline DLBSBatching CTE
        SELECT CountryCode, BatchId,
               DATE_ADD(Date, INTERVAL -1 MONTH) AS InvoiceDate
        FROM DLBSRFBatching
        WHERE CountryCode = CountryCode
          AND DATE_ADD(Date, INTERVAL -1 MONTH) BETWEEN InvoiceFromDate AND InvoiceToDate
    ) b_dlbs
        ON i.CountryCode = b_dlbs.CountryCode
       AND i.BatchId     = b_dlbs.BatchId
    LEFT JOIN Dim_Product p
        ON i.ProductID = p.ProductId AND i.Country = p.Country
    LEFT JOIN Dim_Label l
        ON i.LabelNo = l.LabelNo AND l.CountryCode = i.CountryCode
    WHERE i.LabelNo NOT IN (
        SELECT LabelNo FROM dv.SAT_Label_Allocation_MF
        WHERE CountryCode = CountryCode
          AND IsCurrent   = 1
          AND (DLBSBatchId > 0 OR PLBSBatchId > 0)
    )
    AND i.LabelNo NOT IN (
        SELECT LabelNo FROM dv.LSAT_Label_Product_ServiceItem
        WHERE CountryCode = CountryCode
          AND IsCurrent   = 1
          AND (DLBSBatchId > 0 OR PLBSBatchId > 0)
    )
    AND i.ProductID NOT IN ('523','371','598'); -- remove the products as requested by Finance team
    -- AND InvoiceFromRF = InvoiceFromRF AND InvoiceToRF = InvoiceToRF

END;
