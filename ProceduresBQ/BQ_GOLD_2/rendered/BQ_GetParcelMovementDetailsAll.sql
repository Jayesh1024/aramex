CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.rpt_GetParcelMovementDetailsAll`(
  IN p_CountryCode      INT64,
  IN p_InvoiceFromDate  DATE
)
BEGIN

  -- DECLARE p_CountryCode INT64 = 6;
  -- DECLARE p_InvoiceFromDate DATE = '2023-04-01';
  -- DECLARE p_InvoiceFromRF STRING = 'SYD';
  -- DECLARE p_InvoiceToRF   STRING = 'ADL';

  DECLARE v_InvoiceToDate DATE DEFAULT p_InvoiceFromDate;

  CREATE TEMP TABLE Results AS
  
  WITH DLBSHeader AS (
    SELECT
      DeliveryRFInvoiceNo,
      DLBSBatchId,
      DeliveryRF  AS InvoiceFromRF,
      PickupRF    AS InvoiceToRF,
      DeliveryRFInvoiceDate AS InvoiceDate
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_DLBSInvoiceHeader`
    WHERE CountryId = p_CountryCode
      AND DeliveryRFInvoiceDate BETWEEN p_InvoiceFromDate AND v_InvoiceToDate
    -- AND PickupRF = p_InvoiceToRF AND DeliveryRF = p_InvoiceFromRF
  ),

  PLBSHeader AS (
    SELECT
      PickupRFInvoiceNo,
      PLBSBatchId,
      PickupRF    AS InvoiceFromRF,
      DeliveryRF  AS InvoiceToRF,
      PickupRFInvoiceDate AS InvoiceDate
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_PLBSInvoiceHeader`
    WHERE CountryId = p_CountryCode
      AND PickupRFInvoiceDate BETWEEN p_InvoiceFromDate AND v_InvoiceToDate
    -- AND DeliveryRF = p_InvoiceToRF AND PickupRF = p_InvoiceFromRF
  ),

  DLBSBatching AS (
    SELECT
      CountryCode,
      BatchId,
      DATE_SUB(Date, INTERVAL 1 MONTH) AS InvoiceDate
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_DLBSRFBatching`
    WHERE CountryCode = p_CountryCode
      AND DATE_SUB(Date, INTERVAL 1 MONTH) BETWEEN p_InvoiceFromDate AND v_InvoiceToDate
  )

  -- Con Item DLBS
  SELECT
    l.LabelNo,
    l.CountryCode,
    l.FromRf                  AS PickupRF,
    l.ToRf                    AS DeliveryRF,
    h.InvoiceFromRF,
    h.InvoiceToRF,
    h.InvoiceDate,
    l.DLBSBatchId             AS BatchId,
    l.DLBSInvoiceNo           AS InvoiceNo,
    l.DLBSprice               AS InterbranchPrice,
    'MFW DLBS'                AS Type,
    SUBSTR(l.LabelNo, 1, 2)   AS Prefix,
    l.Height                  AS ParcelHeight,
    l.Length                  AS ParcelLength,
    l.Width                   AS ParcelWidth,
    l.WeightPriced            AS ParcelWeight,
    l.WeightCubic             AS ParcelCubicWeight,
    l.ItemPrice               AS SalePrice,
    l.CustomerId              AS FMSCustomerID,
    CAST(NULL AS STRING)      AS OESCustomerID
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF` l
  INNER JOIN DLBSHeader h
    ON l.DLBSBatchId   = h.DLBSBatchId
   AND l.DLBSInvoiceNo = h.DeliveryRFInvoiceNo
  WHERE l.CountryCode = p_CountryCode
    AND l.IsCurrent = 1

  UNION DISTINCT

  -- Con Item PLBS
  SELECT
    l.LabelNo,
    l.CountryCode,
    l.FromRf,
    l.ToRf,
    h.InvoiceFromRF,
    h.InvoiceToRF,
    h.InvoiceDate,
    l.PLBSBatchId             AS BatchId,
    l.PLBSInvoiceNo           AS InvoiceNo,
    l.PLBSprice               AS InterbranchPrice,
    'MFW PLBS'                AS Type,
    SUBSTR(l.LabelNo, 1, 2)   AS Prefix,
    l.Height                  AS ParcelHeight,
    l.Length                  AS ParcelLength,
    l.Width                   AS ParcelWidth,
    l.WeightPriced            AS ParcelWeight,
    l.WeightCubic             AS ParcelCubicWeight,
    l.ItemPrice               AS SalePrice,
    l.CustomerId              AS FMSCustomerID,
    CAST(NULL AS STRING)      AS OESCustomerID
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF` l
  INNER JOIN PLBSHeader h
    ON l.PLBSBatchId   = h.PLBSBatchId
   AND l.PLBSInvoiceNo = h.PickupRFInvoiceNo
  WHERE l.CountryCode = p_CountryCode
    AND l.IsCurrent = 1

  UNION DISTINCT

  -- Con Item Service DLBS
  SELECT
    l.LabelNo,
    l.CountryCode,
    m.FromRf,
    m.ToRf,
    h.InvoiceFromRF,
    h.InvoiceToRF,
    h.InvoiceDate,
    l.DLBSBatchId             AS BatchId,
    l.DLBSInvoiceNo           AS InvoiceNo,
    l.DLBSPrice               AS InterbranchPrice,
    'MFW DLBS Service'        AS Type,
    SUBSTR(l.LabelNo, 1, 2)   AS Prefix,
    0                         AS ParcelHeight,
    0                         AS ParcelLength,
    0                         AS ParcelWidth,
    0                         AS ParcelWeight,
    0                         AS ParcelCubicWeight,
    l.Price                   AS SalePrice,
    m.CustomerId              AS FMSCustomerID,
    CAST(NULL AS STRING)      AS OESCustomerID
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Product_ServiceItem` l
  INNER JOIN DLBSHeader h
    ON l.DLBSBatchId   = h.DLBSBatchId
   AND l.DLBSInvoiceNo = h.DeliveryRFInvoiceNo
  LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF` m
    ON l.LabelNo    = m.LabelNo
   AND m.IsCurrent  = 1
  WHERE l.CountryCode = p_CountryCode
    AND l.IsCurrent = 1

  UNION DISTINCT

  -- Con Item Service PLBS
  SELECT
    l.LabelNo,
    l.CountryCode,
    m.FromRf,
    m.ToRf,
    h.InvoiceFromRF,
    h.InvoiceToRF,
    h.InvoiceDate,
    l.PLBSBatchId             AS BatchId,
    l.PLBSInvoiceNo           AS InvoiceNo,
    l.PLBSPrice               AS InterbranchPrice,
    'MFW PLBS Service'        AS Type,
    SUBSTR(l.LabelNo, 1, 2)   AS Prefix,
    0                         AS ParcelHeight,
    0                         AS ParcelLength,
    0                         AS ParcelWidth,
    0                         AS ParcelWeight,
    0                         AS ParcelCubicWeight,
    l.Price                   AS SalePrice,
    m.CustomerId              AS FMSCustomerID,
    CAST(NULL AS STRING)      AS OESCustomerID
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Product_ServiceItem` l
  INNER JOIN PLBSHeader h
    ON l.PLBSBatchId   = h.PLBSBatchId
   AND l.PLBSInvoiceNo = h.PickupRFInvoiceNo
  LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF` m
    ON l.LabelNo   = m.LabelNo
   AND m.IsCurrent = 1
  WHERE l.CountryCode = p_CountryCode
    AND l.IsCurrent = 1

  UNION DISTINCT

  -- Legacy DLBS excluding Excess and MFW
  SELECT
    i.LabelNo,
    i.CountryCode,
    i.InvoiceToRF             AS PickupRF,
    i.InvoiceFromRF           AS DeliveryRF,
    i.InvoiceFromRF,
    i.InvoiceToRF,
    b.InvoiceDate,
    i.BatchId,
    i.InvoiceNumber           AS InvoiceNo,
    CASE
      WHEN SUBSTR(i.LabelNo, 1, 2) IN ('MP','MS','MX','FX') THEN 0
      ELSE i.Price
    END                       AS InterbranchPrice,
    'Legacy DLBS'             AS Type,
    SUBSTR(i.LabelNo, 1, 2)   AS Prefix,
    l.ParcelHeight,
    l.ParcelLength,
    l.ParcelWidth,
    l.ParcelWeight,
    l.ParcelCubicWeight,
    l.Price                   AS SalePrice,
    l.FMSCustomerID,
    l.OESCustomerID
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Interbranch_All` i
  INNER JOIN DLBSBatching b
    ON i.CountryCode = b.CountryCode
   AND i.BatchId     = b.BatchId
  LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label` l
    ON i.LabelNo     = l.LabelNo
   AND l.CountryCode = CAST(i.CountryCode AS INT64)
  WHERE i.LabelNo NOT IN (
    SELECT LabelNo
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF`
    WHERE CountryCode = p_CountryCode
      AND IsCurrent = 1
      AND (DLBSBatchId > 0 OR PLBSBatchId > 0)
  )
  AND i.LabelNo NOT IN (
    SELECT LabelNo
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Product_ServiceItem`
    WHERE CountryCode = p_CountryCode
      AND IsCurrent = 1
      AND (DLBSBatchId > 0 OR PLBSBatchId > 0)
  );
  -- AND InvoiceFromRF = p_InvoiceFromRF AND InvoiceToRF = p_InvoiceToRF

END;