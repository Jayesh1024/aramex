CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.rpt_GetParcelMovement`(
  IN p_CountryCode      INT64,
  IN p_InvoiceFromDate  DATE,
  IN p_InvoiceToDate    DATE
)
BEGIN

  -- DECLARE p_CountryCode INT64 = 1;
  -- DECLARE p_InvoiceFromDate DATE = '2022-01-01';
  -- DECLARE p_InvoiceToDate   DATE = '2022-08-01';
  -- DECLARE p_InvoiceFromRF STRING = 'SYD';
  -- DECLARE p_InvoiceToRF   STRING = 'ADL';

  CREATE TEMP TABLE Results AS

  WITH

  DLBSHeader AS (
    SELECT
      DeliveryRFInvoiceNo,
      DLBSBatchId,
      DeliveryRF          AS InvoiceFromRF,
      PickupRF            AS InvoiceToRF,
      DeliveryRFInvoiceDate AS InvoiceDate
    FROM `{{ project_id }}.{{ target_dataset_id }}.rpt_DLBSInvoiceHeader`
    WHERE CountryId    = p_CountryCode
      AND DeliveryRFInvoiceDate BETWEEN p_InvoiceFromDate AND p_InvoiceToDate
    -- AND PickupRF = p_InvoiceToRF AND DeliveryRF = p_InvoiceFromRF
  ),

  PLBSHeader AS (
    SELECT
      PickupRFInvoiceNo,
      PLBSBatchId,
      PickupRF            AS InvoiceFromRF,
      DeliveryRF          AS InvoiceToRF,
      PickupRFInvoiceDate AS InvoiceDate
    FROM `{{ project_id }}.{{ target_dataset_id }}.rpt_PLBSInvoiceHeader`
    WHERE CountryId    = p_CountryCode
      AND PickupRFInvoiceDate BETWEEN p_InvoiceFromDate AND p_InvoiceToDate
    -- AND DeliveryRF = p_InvoiceToRF AND PickupRF = p_InvoiceFromRF
  ),

  DLBSBatching AS (
    SELECT
      CountryCode,
      BatchId,
      DATE_SUB(Date, INTERVAL 1 MONTH) AS InvoiceDate
    FROM `{{ project_id }}.{{ target_dataset_id }}.rpt_DLBSRFBatching`
    WHERE CountryCode = p_CountryCode
      AND DATE_SUB(Date, INTERVAL 1 MONTH) BETWEEN p_InvoiceFromDate AND p_InvoiceToDate
  ),

  ParcelMovement AS (

    -- Con Item DLBS
    SELECT
      l.LabelNo,
      l.CountryCode,
      h.InvoiceFromRF,
      h.InvoiceToRF,
      h.InvoiceDate,
      l.DLBSprice                                                               AS Price,
      (CASE WHEN l.WeightPriced > 3 OR l.SatchelSize = 'A2' THEN 0.05 ELSE 0.025 END)
        * l.DLBSPrice                                                           AS Bonus,
      l.CustomerId                                                              AS FMSCustomerID,
      CAST(NULL AS STRING)                                                      AS OESCustomerID,
      'MFW DLBS'                                                                AS Type
    FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF` l
    INNER JOIN DLBSHeader h
      ON  l.DLBSBatchId   = h.DLBSBatchId
      AND l.DLBSInvoiceNo = h.DeliveryRFInvoiceNo
    WHERE l.CountryCode = p_CountryCode
      AND l.IsCurrent   = 1

    UNION

    -- Con Item PLBS
    SELECT
      l.LabelNo,
      l.CountryCode,
      h.InvoiceFromRF,
      h.InvoiceToRF,
      h.InvoiceDate,
      l.PLBSprice                         AS Price,
      0                                   AS Bonus,
      l.CustomerId                        AS FMSCustomerID,
      CAST(NULL AS STRING)                AS OESCustomerID,
      'MFW PLBS'                          AS Type
    FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF` l
    INNER JOIN PLBSHeader h
      ON  l.PLBSBatchId   = h.PLBSBatchId
      AND l.PLBSInvoiceNo = h.PickupRFInvoiceNo
    WHERE l.CountryCode = p_CountryCode
      AND l.IsCurrent   = 1

    UNION

    -- Con Item Service DLBS
    SELECT
      l.LabelNo,
      l.CountryCode,
      h.InvoiceFromRF,
      h.InvoiceToRF,
      h.InvoiceDate,
      l.DLBSPrice                                                               AS Price,
      (CASE WHEN m.WeightPriced > 3 OR m.SatchelSize = 'A2' THEN 0.05 ELSE 0.025 END)
        * l.DLBSPrice                                                           AS Bonus,
      m.CustomerId                                                              AS FMSCustomerID,
      CAST(NULL AS STRING)                                                      AS OESCustomerID,
      'MFW DLBS'                                                                AS Type
    FROM `{{ project_id }}.{{ target_dataset_id }}.dv_LSAT_Label_Product_ServiceItem` l
    INNER JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF` m
      ON  l.LabelNo   = m.LabelNo
      AND m.IsCurrent = 1
    INNER JOIN DLBSHeader h
      ON  l.DLBSBatchId   = h.DLBSBatchId
      AND l.DLBSInvoiceNo = h.DeliveryRFInvoiceNo
    WHERE l.CountryCode = p_CountryCode
      AND l.IsCurrent   = 1

    UNION

    -- Con Item Service PLBS
    SELECT
      l.LabelNo,
      l.CountryCode,
      h.InvoiceFromRF,
      h.InvoiceToRF,
      h.InvoiceDate,
      l.PLBSPrice                         AS Price,
      0                                   AS Bonus,
      m.CustomerId                        AS FMSCustomerID,
      CAST(NULL AS STRING)                AS OESCustomerID,
      'MFW PLBS'                          AS Type
    FROM `{{ project_id }}.{{ target_dataset_id }}.dv_LSAT_Label_Product_ServiceItem` l
    INNER JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF` m
      ON  l.LabelNo   = m.LabelNo
      AND m.IsCurrent = 1
    INNER JOIN PLBSHeader h
      ON  l.PLBSBatchId   = h.PLBSBatchId
      AND l.PLBSInvoiceNo = h.PickupRFInvoiceNo
    WHERE l.CountryCode = p_CountryCode
      AND l.IsCurrent   = 1

    UNION

    -- Legacy DLBS excluding Excess and MFW
    SELECT
      i.LabelNo,
      i.CountryCode,
      i.InvoiceFromRF,
      i.InvoiceToRF,
      b.InvoiceDate,
      CASE
        WHEN SUBSTR(i.LabelNo, 1, 2) IN ('MP','MS','MX','FX') THEN 0
        ELSE i.Price
      END                                 AS Price,
      0.05 * CASE
        WHEN SUBSTR(i.LabelNo, 1, 2) IN ('MP','MS','MX','FX') THEN 0
        ELSE i.Price
      END                                 AS Bonus,
      l.FMSCustomerID,
      l.OESCustomerID,
      'Legacy DLBS'                       AS Type
    FROM `{{ project_id }}.{{ target_dataset_id }}.rpt_Fact_Interbranch` i
    INNER JOIN DLBSBatching b
      ON  i.CountryCode = b.CountryCode
      AND i.BatchId     = b.BatchId
    LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.rpt_Dim_Label` l
      ON  i.LabelNo     = l.LabelNo
      AND l.CountryCode = i.CountryCode
    WHERE i.LabelNo NOT IN (
      SELECT LabelNo
      FROM `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF`
      WHERE CountryCode = p_CountryCode
        AND IsCurrent   = 1
        AND (DLBSBatchId > 0 OR PLBSBatchId > 0)
    )
    AND i.LabelNo NOT IN (
      SELECT LabelNo
      FROM `{{ project_id }}.{{ target_dataset_id }}.dv_LSAT_Label_Product_ServiceItem`
      WHERE CountryCode = p_CountryCode
        AND IsCurrent   = 1
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
    COUNT(DISTINCT LabelNo)   AS LabelCount,
    SUM(Price)                AS Price,
    SUM(Bonus)                AS Bonus
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