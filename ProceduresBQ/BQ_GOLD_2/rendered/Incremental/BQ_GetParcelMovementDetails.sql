CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.sp_GetParcelMovementDetails`(
  CountryCode INT64,
  InvoiceFromDate DATE
)
BEGIN
  -- CALL example:
  -- CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.sp_GetParcelMovementDetails`(1, DATE '2022-01-01');

  DECLARE p_CountryCode INT64;
  DECLARE p_InvoiceFromDate DATE;
  DECLARE p_InvoiceToDate DATE;

  SET p_CountryCode = CountryCode;
  SET p_InvoiceFromDate = InvoiceFromDate;
  SET p_InvoiceToDate = InvoiceFromDate;

  WITH DLBSHeader AS (
    SELECT
      DeliveryRFInvoiceNo,
      DLBSBatchId,
      DeliveryRF AS InvoiceFromRF,
      PickupRF AS InvoiceToRF,
      DeliveryRFInvoiceDate AS InvoiceDate
    FROM `bq_ds_prod_euw2_oceania_cube_gold_1.dbo_DLBSInvoiceHeader`
    WHERE CountryId = p_CountryCode
      AND DATE(DeliveryRFInvoiceDate) BETWEEN p_InvoiceFromDate AND p_InvoiceToDate
  ),

  PLBSHeader AS (
    SELECT
      PickupRFInvoiceNo,
      PLBSBatchId,
      PickupRF AS InvoiceFromRF,
      DeliveryRF AS InvoiceToRF,
      PickupRFInvoiceDate AS InvoiceDate
    FROM `bq_ds_prod_euw2_oceania_cube_gold_1.dbo_PLBSInvoiceHeader`
    WHERE CountryId = p_CountryCode
      AND DATE(PickupRFInvoiceDate) BETWEEN p_InvoiceFromDate AND p_InvoiceToDate
  ),

  DLBSBatching AS (
    SELECT
      db.CountryCode,
      db.BatchId,
      DATE(DATE_SUB(db.`Date`, INTERVAL 1 MONTH)) AS InvoiceDate
    FROM `bq_ds_prod_euw2_oceania_cube_gold_1.dbo_DLBSRFBatching` AS db
    WHERE db.CountryCode = p_CountryCode
      AND DATE(DATE_SUB(db.`Date`, INTERVAL 1 MONTH)) BETWEEN p_InvoiceFromDate AND p_InvoiceToDate
  )

  -- Con Item DLBS
  SELECT
    LabelNo,
    CAST(l.CountryCode AS STRING) AS CountryCode, -- Cast to matching string structure for UNION consistency
    FromRf AS PickupRF,
    ToRf AS DeliveryRF,
    h.InvoiceFromRF,
    h.InvoiceToRF,
    h.InvoiceDate,
    l.DLBSBatchId AS BatchId,
    DLBSInvoiceNo AS InvoiceNo,
    DLBSPrice AS Price,
    'MFW DLBS' AS `Type`,
    LEFT(LabelNo, 2) AS Product,
    (CASE WHEN WeightPriced > 3 OR UPPER(SatchelSize) = 'A2' THEN 0.05 ELSE 0.025 END) AS WeightPerc,
    l.CustomerId AS FMSCustomerID,
    CAST(NULL AS INT64) AS OESCustomerID
  FROM `bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF` AS l
  INNER JOIN DLBSHeader AS h
    ON l.DLBSBatchId = h.DLBSBatchId
    AND l.DLBSInvoiceNo = h.DeliveryRFInvoiceNo
  WHERE l.CountryCode = p_CountryCode
    AND IsCurrent = 1

  UNION DISTINCT

  -- Con Item PLBS
  SELECT
    LabelNo,
    CAST(l.CountryCode AS STRING) AS CountryCode,
    FromRf,
    ToRf,
    h.InvoiceFromRF,
    h.InvoiceToRF,
    h.InvoiceDate,
    l.PLBSBatchId AS BatchId,
    PLBSInvoiceNo AS InvoiceNo,
    PLBSPrice AS Price,
    'MFW PLBS' AS `Type`,
    LEFT(LabelNo, 2) AS Product,
    0 AS WeightPerc,
    l.CustomerId AS FMSCustomerID,
    CAST(NULL AS INT64) AS OESCustomerID
  FROM `bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF` AS l
  INNER JOIN PLBSHeader AS h
    ON l.PLBSBatchId = h.PLBSBatchId
    AND l.PLBSInvoiceNo = h.PickupRFInvoiceNo
  WHERE l.CountryCode = p_CountryCode
    AND IsCurrent = 1

  UNION DISTINCT

  -- Con Item Service DLBS
  SELECT
    l.LabelNo,
    CAST(l.CountryCode AS STRING) AS CountryCode,
    m.FromRf,
    m.ToRf,
    h.InvoiceFromRF,
    h.InvoiceToRF,
    h.InvoiceDate,
    l.DLBSBatchId AS BatchId,
    l.DLBSInvoiceNo AS InvoiceNo,
    l.DLBSPrice AS Price,
    'MFW DLBS' AS `Type`,
    LEFT(l.LabelNo, 2) AS Product,
    (CASE WHEN m.WeightPriced > 3 OR UPPER(m.SatchelSize) = 'A2' THEN 0.05 ELSE 0.025 END) AS WeightPerc,
    m.CustomerId AS FMSCustomerID,
    CAST(NULL AS INT64) AS OESCustomerID
  FROM `bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Product_ServiceItem` AS l
  INNER JOIN DLBSHeader AS h
    ON l.DLBSBatchId = h.DLBSBatchId
    AND l.DLBSInvoiceNo = h.DeliveryRFInvoiceNo
  LEFT JOIN `bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF` AS m
    ON l.LabelNo = m.LabelNo
    AND m.IsCurrent = 1
  WHERE l.CountryCode = p_CountryCode
    AND l.IsCurrent = 1

  UNION DISTINCT

  -- Con Item Service PLBS
  SELECT
    l.LabelNo,
    CAST(l.CountryCode AS STRING) AS CountryCode,
    m.FromRf,
    m.ToRf,
    h.InvoiceFromRF,
    h.InvoiceToRF,
    h.InvoiceDate,
    l.PLBSBatchId AS BatchId,
    l.PLBSInvoiceNo AS InvoiceNo,
    l.PLBSPrice AS Price,
    'MFW PLBS' AS `Type`,
    LEFT(l.LabelNo, 2) AS Product,
    0 AS WeightPerc,
    m.CustomerId AS FMSCustomerID,
    CAST(NULL AS INT64) AS OESCustomerID
  FROM `bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Product_ServiceItem` AS l
  INNER JOIN PLBSHeader AS h
    ON l.PLBSBatchId = h.PLBSBatchId
    AND l.PLBSInvoiceNo = h.PickupRFInvoiceNo
  LEFT JOIN `bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF` AS m
    ON l.LabelNo = m.LabelNo
    AND m.IsCurrent = 1
  WHERE l.CountryCode = p_CountryCode
    AND l.IsCurrent = 1

  UNION DISTINCT

  -- Legacy DLBS excluding Excess and MFW
  SELECT
    i.LabelNo,
    CAST(i.CountryCode AS STRING) AS CountryCode,
    InvoiceToRF AS PickupRF,
    InvoiceFromRF AS DeliveryRF,
    InvoiceFromRF,
    InvoiceToRF,
    b.InvoiceDate,
    i.BatchId,
    InvoiceNumber AS InvoiceNo,
    (CASE WHEN UPPER(LEFT(i.LabelNo, 2)) IN ('MP', 'MS', 'MX', 'FX') THEN 0 ELSE i.Price END) AS Price,
    'Legacy DLBS' AS `Type`,
    p.Description AS Product,
    0.05 AS WeightPerc,
    l.FMSCustomerID,
    l.OESCustomerID
  FROM `bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Interbranch` AS i
  INNER JOIN DLBSBatching AS b
    ON CAST(i.CountryCode AS STRING) = CAST(b.CountryCode AS STRING)            -- Fixed potential mismatched CTE join
    AND i.BatchId = b.BatchId
  LEFT JOIN `bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Product` AS p
    ON CAST(i.ProductID AS STRING) = CAST(p.ProductId AS STRING)
    AND CAST(i.Country AS STRING) = CAST(p.Country AS STRING)
  LEFT JOIN `bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label` AS l
    ON i.LabelNo = l.LabelNo
    AND CAST(l.CountryCode AS STRING) = CAST(i.CountryCode AS STRING)
  WHERE i.LabelNo NOT IN (
      SELECT LabelNo
      FROM `bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF`
      WHERE CountryCode = p_CountryCode
        AND IsCurrent = 1
        AND (DLBSBatchId > 0 OR PLBSBatchId > 0)
    )
    AND i.LabelNo NOT IN (
      SELECT LabelNo
      FROM `bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Product_ServiceItem`
      WHERE CountryCode = p_CountryCode
        AND IsCurrent = 1
        AND (DLBSBatchId > 0 OR PLBSBatchId > 0)
    )
    AND i.ProductID NOT IN (523, 371, 598);
END;
