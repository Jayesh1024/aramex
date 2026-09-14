CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.rpt_GetParcelMovementDetailsAll`(
  IN p_CountryCode      INT64,
  IN p_InvoiceFromDate  DATE
)
BEGIN
  DECLARE v_InvoiceToDate DATE DEFAULT p_InvoiceFromDate;

  CREATE TEMP TABLE Results AS
  WITH DLBSHeader AS (
    SELECT
      CAST(DeliveryRFInvoiceNo AS STRING) AS DeliveryRFInvoiceNo,
      SAFE_CAST(DLBSBatchId AS INT64)     AS DLBSBatchId,
      DeliveryRF                          AS InvoiceFromRF,
      PickupRF                            AS InvoiceToRF,
      DeliveryRFInvoiceDate               AS InvoiceDate
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_DLBSInvoiceHeader`
    -- Use SAFE_CAST to ignore non-numeric garbage data
    WHERE SAFE_CAST(CountryId AS INT64) = p_CountryCode
      AND DeliveryRFInvoiceDate BETWEEN p_InvoiceFromDate AND v_InvoiceToDate
  ),

  PLBSHeader AS (
    SELECT
      CAST(PickupRFInvoiceNo AS STRING) AS PickupRFInvoiceNo,
      SAFE_CAST(PLBSBatchId AS INT64)   AS PLBSBatchId,
      PickupRF                          AS InvoiceFromRF,
      DeliveryRF                        AS InvoiceToRF,
      PickupRFInvoiceDate               AS InvoiceDate
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_PLBSInvoiceHeader`
    WHERE SAFE_CAST(CountryId AS INT64) = p_CountryCode
      AND PickupRFInvoiceDate BETWEEN p_InvoiceFromDate AND v_InvoiceToDate
  ),

  DLBSBatching AS (
    SELECT
      SAFE_CAST(CountryCode AS INT64) AS CountryCode,
      SAFE_CAST(BatchId AS INT64)     AS BatchId,
      DATE_SUB(Date, INTERVAL 1 MONTH) AS InvoiceDate
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_DLBSRFBatching`
    WHERE SAFE_CAST(CountryCode AS INT64) = p_CountryCode
      AND DATE_SUB(Date, INTERVAL 1 MONTH) BETWEEN p_InvoiceFromDate AND v_InvoiceToDate
  )

  -- Block 1: Con Item DLBS
  SELECT
    CAST(l.LabelNo AS STRING)       AS LabelNo,
    SAFE_CAST(l.CountryCode AS INT64) AS CountryCode,
    l.FromRf                        AS PickupRF,
    l.ToRf                          AS DeliveryRF,
    h.InvoiceFromRF,
    h.InvoiceToRF,
    h.InvoiceDate,
    SAFE_CAST(l.DLBSBatchId AS INT64) AS BatchId,
    CAST(l.DLBSInvoiceNo AS STRING) AS InvoiceNo,
    CAST(l.DLBSprice AS FLOAT64)    AS InterbranchPrice,
    'MFW DLBS'                      AS Type,
    SUBSTR(l.LabelNo, 1, 2)         AS Prefix,
    CAST(l.Height AS FLOAT64)       AS ParcelHeight,
    CAST(l.Length AS FLOAT64)       AS ParcelLength,
    CAST(l.Width AS FLOAT64)        AS ParcelWidth,
    CAST(l.WeightPriced AS FLOAT64) AS ParcelWeight,
    CAST(l.WeightCubic AS FLOAT64)  AS ParcelCubicWeight,
    CAST(l.ItemPrice AS FLOAT64)    AS SalePrice,
    CAST(l.CustomerId AS STRING)    AS FMSCustomerID,
    CAST(NULL AS STRING)            AS OESCustomerID
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF` l
  INNER JOIN DLBSHeader h
    ON SAFE_CAST(l.DLBSBatchId AS INT64)   = h.DLBSBatchId
   AND CAST(l.DLBSInvoiceNo AS STRING)    = h.DeliveryRFInvoiceNo
  WHERE SAFE_CAST(l.CountryCode AS INT64) = p_CountryCode
    AND l.IsCurrent = 1

  UNION DISTINCT

  -- Block 2: Con Item PLBS
  SELECT
    CAST(l.LabelNo AS STRING),
    SAFE_CAST(l.CountryCode AS INT64),
    l.FromRf,
    l.ToRf,
    h.InvoiceFromRF,
    h.InvoiceToRF,
    h.InvoiceDate,
    SAFE_CAST(l.PLBSBatchId AS INT64),
    CAST(l.PLBSInvoiceNo AS STRING),
    CAST(l.PLBSprice AS FLOAT64),
    'MFW PLBS',
    SUBSTR(l.LabelNo, 1, 2),
    CAST(l.Height AS FLOAT64),
    CAST(l.Length AS FLOAT64),
    CAST(l.Width AS FLOAT64),
    CAST(l.WeightPriced AS FLOAT64),
    CAST(l.WeightCubic AS FLOAT64),
    CAST(l.ItemPrice AS FLOAT64),
    CAST(l.CustomerId AS STRING),
    CAST(NULL AS STRING)
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF` l
  INNER JOIN PLBSHeader h
    ON SAFE_CAST(l.PLBSBatchId AS INT64)   = h.PLBSBatchId
   AND CAST(l.PLBSInvoiceNo AS STRING)    = h.PickupRFInvoiceNo
  WHERE SAFE_CAST(l.CountryCode AS INT64) = p_CountryCode
    AND l.IsCurrent = 1

  UNION DISTINCT

  -- Block 3: Con Item Service DLBS
  SELECT
    CAST(l.LabelNo AS STRING),
    SAFE_CAST(l.CountryCode AS INT64),
    m.FromRf,
    m.ToRf,
    h.InvoiceFromRF,
    h.InvoiceToRF,
    h.InvoiceDate,
    SAFE_CAST(l.DLBSBatchId AS INT64),
    CAST(l.DLBSInvoiceNo AS STRING),
    CAST(l.DLBSPrice AS FLOAT64),
    'MFW DLBS Service',
    SUBSTR(l.LabelNo, 1, 2),
    0.0, 0.0, 0.0, 0.0, 0.0,
    CAST(l.Price AS FLOAT64),
    CAST(m.CustomerId AS STRING),
    CAST(NULL AS STRING)
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Product_ServiceItem` l
  INNER JOIN DLBSHeader h
    ON SAFE_CAST(l.DLBSBatchId AS INT64)   = h.DLBSBatchId
   AND CAST(l.DLBSInvoiceNo AS STRING)    = h.DeliveryRFInvoiceNo
  LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF` m
    ON l.LabelNo   = m.LabelNo
   AND m.IsCurrent = 1
  WHERE SAFE_CAST(l.CountryCode AS INT64) = p_CountryCode
    AND l.IsCurrent = 1

  UNION DISTINCT

  -- Block 4: Con Item Service PLBS
  SELECT
    CAST(l.LabelNo AS STRING),
    SAFE_CAST(l.CountryCode AS INT64),
    m.FromRf,
    m.ToRf,
    h.InvoiceFromRF,
    h.InvoiceToRF,
    h.InvoiceDate,
    SAFE_CAST(l.PLBSBatchId AS INT64),
    CAST(l.PLBSInvoiceNo AS STRING),
    CAST(l.PLBSPrice AS FLOAT64),
    'MFW PLBS Service',
    SUBSTR(l.LabelNo, 1, 2),
    0.0, 0.0, 0.0, 0.0, 0.0,
    CAST(l.Price AS FLOAT64),
    CAST(m.CustomerId AS STRING),
    CAST(NULL AS STRING)
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Product_ServiceItem` l
  INNER JOIN PLBSHeader h
    ON SAFE_CAST(l.PLBSBatchId AS INT64)   = h.PLBSBatchId
   AND CAST(l.PLBSInvoiceNo AS STRING)    = h.PickupRFInvoiceNo
  LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF` m
    ON l.LabelNo   = m.LabelNo
   AND m.IsCurrent = 1
  WHERE SAFE_CAST(l.CountryCode AS INT64) = p_CountryCode
    AND l.IsCurrent = 1

  UNION DISTINCT

  -- Block 5: Legacy DLBS
  SELECT
    CAST(i.LabelNo AS STRING),
    SAFE_CAST(i.CountryCode AS INT64),
    i.InvoiceToRF,
    i.InvoiceFromRF,
    i.InvoiceFromRF,
    i.InvoiceToRF,
    b.InvoiceDate,
    SAFE_CAST(i.BatchId AS INT64),
    CAST(i.InvoiceNumber AS STRING),
    CASE
      WHEN SUBSTR(i.LabelNo, 1, 2) IN ('MP','MS','MX','FX') THEN 0.0
      ELSE CAST(i.Price AS FLOAT64)
    END,
    'Legacy DLBS',
    SUBSTR(i.LabelNo, 1, 2),
    CAST(l.ParcelHeight AS FLOAT64),
    CAST(l.ParcelLength AS FLOAT64),
    CAST(l.ParcelWidth AS FLOAT64),
    CAST(l.ParcelWeight AS FLOAT64),
    CAST(l.ParcelCubicWeight AS FLOAT64),
    CAST(l.Price AS FLOAT64),
    CAST(l.FMSCustomerID AS STRING),
    CAST(l.OESCustomerID AS STRING)
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Interbranch_All` i
  INNER JOIN DLBSBatching b
    ON SAFE_CAST(i.CountryCode AS INT64) = b.CountryCode
   AND SAFE_CAST(i.BatchId AS INT64)     = b.BatchId
  LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label` l
    ON i.LabelNo                    = l.LabelNo
   AND SAFE_CAST(i.CountryCode AS INT64) = SAFE_CAST(l.CountryCode AS INT64)
  WHERE i.LabelNo NOT IN (
    SELECT LabelNo
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF`
    WHERE SAFE_CAST(CountryCode AS INT64) = p_CountryCode
      AND IsCurrent = 1
      AND (SAFE_CAST(DLBSBatchId AS INT64) > 0 OR SAFE_CAST(PLBSBatchId AS INT64) > 0)
  )
  AND i.LabelNo NOT IN (
    SELECT LabelNo
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Product_ServiceItem`
    WHERE SAFE_CAST(CountryCode AS INT64) = p_CountryCode
      AND IsCurrent = 1
      AND (SAFE_CAST(DLBSBatchId AS INT64) > 0 OR SAFE_CAST(PLBSBatchId AS INT64) > 0)
  );
END;