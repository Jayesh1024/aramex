CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Aging2`
AS
SELECT
  a_1.LabelNo,
  a_1.LastScanDate,
  a_1.LastScanRF,
  a_1.LastScanCF,
  a_1.LastScanType,
  a_1.LastScanStatus,
  a_1.PickupDate,
  a_1.PickupRF,
  a_1.PickupCF,
  a_1.FirstDepartedDate,
  a_1.FirstDepartedRF,
  a_1.LastDepartedDate,
  a_1.LastDepartedRF,
  a_1.FirstArrivedRF,
  a_1.LastArrivedRF,
  a_1.OutDate,
  a_1.OutRF,
  a_1.OutCF,
  a_1.DestRF,
  a_1.DeliveryTown,
  a_1.DeliveryPostcode,
  a_1.OESCustomerID,
  a_1.FMSCustomerID,
  a_1.CFDeliveryString,
  a_1.ToBlu,
  m.Days AS KPI,
  a_1.CountryCode,
  a_1.ParcelWeight,
  a_1.DeliveryAddress
FROM
  (
    SELECT
      s.LabelNo,
      s.LastScanDate,
      s.LastScanRF,
      s.LastScanCF,
      s.LastScanType,
      s.LastScanStatus,
      s.PickupDate,
      s.PickupRF,
      s.PickupCF,
      s.FirstDepartedDate,
      s.FirstDepartedRF,
      s.LastDepartedDate,
      s.LastDepartedRF,
      s.FirstArrivedRF,
      s.LastArrivedRF,
      s.OutDate,
      s.OutRF,
      s.OutCF,
      (
        CASE
          WHEN FastLabel_DestinationRF IS NOT NULL THEN FastLabel_DestinationRF
          WHEN DeedRF IS NOT NULL
            THEN DeedRF
          WHEN
            (LastSortedScanStatus IS NOT NULL)
            AND (UPPER(LastSortedScanStatus) NOT IN ('UNW', 'MIX'))
            THEN LastSortedScanStatus
          WHEN FirstOutRF IS NOT NULL THEN FirstOutRF
          ELSE ''
          END) AS DestRF,
      COALESCE(UPPER(TRIM(l.DeliveryTown)), a.DelTown) AS DeliveryTown,
      COALESCE(l.DeliveryPostcode, a.DelPostcode) AS DeliveryPostcode,
      l.OESCustomerID,
      l.FMSCustomerID,
      p.CFDeliveryString,
      l.CountryCode,
      l.ParcelWeight,
      a.DeliveryAddress,
      (
        SELECT COUNT(1) AS Expr1
        FROM
          `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Scan`
        WHERE
          (LabelNo = s.LabelNo)
          AND (UPPER(ScanStatus) IN ('BBD', 'BB1', 'BB2', 'BB3'))
      ) AS ToBlu
    FROM
      (
        SELECT
          k.LabelNo,
          k.LastScanDate,
          k.LastScanRF,
          k.LastScanCF,
          k.LastScanType,
          k.LastScanStatus,
          k.FirstReceivedDate AS PickupDate,
          k.FirstReceivedRF AS PickupRF,
          k.FirstReceivedCF AS PickupCF,
          k.FirstDepartedDate,
          k.FirstDepartedRF,
          k.LastDepartedDate,
          k.LastDepartedRF,
          k.FirstArrivedRF,
          k.LastArrivedRF,
          k.FirstOutDate AS OutDate,
          k.FirstOutRF AS OutRF,
          k.FirstOutCF AS OutCF,
          k.LastSortedScanStatus,
          k.FirstOutRF,
          r.CountryCode
        FROM
          `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Scan_KPI`
            AS k
        INNER JOIN
          `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_RF`
            AS r
          ON k.FirstReceivedRF = r.FranchiseeCode
        WHERE
          (
            k.FirstReceivedDate >= DATE_ADD(
              CAST(CURRENT_DATETIME() AS DATE), INTERVAL -1 MONTH))
          AND (k.FirstStopDate IS NULL)
          AND (
            (
              CASE
                WHEN r.CountryCode = 1 AND LEFT(UPPER(k.LabelNo), 2) <> '5A'
                  THEN 1
                WHEN r.CountryCode = 6 AND LEFT(k.LabelNo, 1) <> '9' THEN 1
                WHEN r.CountryCode = 24 THEN 1
                ELSE 0
                END)
            = 1)
      ) AS s
    LEFT OUTER JOIN
      `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label`
        AS l
      ON (s.LabelNo = l.LabelNo) AND (s.CountryCode = l.CountryCode)
    LEFT OUTER JOIN
      `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_TSS_PostCodeMaster`
        AS p
      ON (
        l.DeliveryPostcode = TRIM(p.PostCode))
        AND (UPPER(TRIM(l.DeliveryTown)) = TRIM(p.Suburb))
        AND (p.CountryCode IN (1, 6, 24))
    LEFT OUTER JOIN
      `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label_Address`
        AS a
      ON s.LabelNo = a.LabelNo
  ) AS a_1
LEFT OUTER JOIN
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIMatrix` AS m
  ON (a_1.PickupRF = m.PickupFranchise) AND (a_1.DestRF = m.DeliveryFranchise)
