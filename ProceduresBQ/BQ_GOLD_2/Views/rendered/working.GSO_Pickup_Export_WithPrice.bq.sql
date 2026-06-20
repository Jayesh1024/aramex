CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.working_GSO_Pickup_Export_WithPrice`
AS
SELECT
  (
    CASE
      WHEN r.CountryCode = 1 THEN 'AU'
      WHEN r.CountryCode = 6 THEN 'NZ'
      ELSE ''
      END) AS ReceivedCountry,
  (
    CASE
      WHEN d.CountryCode = 1 THEN 'AU'
      WHEN d.CountryCode = 6 THEN 'NZ'
      ELSE ''
      END) AS DeliveryCountry,
  ReceivedRF,
  DeliveryRF,
  CAST(DATE_DIFF(PickupDate, DATE('1970-01-01'), DAY) AS STRING) AS PickupDate,
  sum(NumofPickups) AS NumofLabels,
  SUM(Price) AS Price
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Pickup_Performance5_WithPrice`
    p
INNER JOIN
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_RF` r
  ON p.ReceivedRF = r.FranchiseeCode
LEFT JOIN
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_RF` d
  ON p.DeliveryRF = d.FranchiseeCode
WHERE
  (r.CountryCode IN (1, 6))
  AND (
    PickupDate >= DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), MONTH))
  AND (PickupDate <= DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY))
GROUP BY r.CountryCode, d.CountryCode, ReceivedRF, DeliveryRF, PickupDate

-- Last month
UNION ALL
SELECT
  (
    CASE
      WHEN r.CountryCode = 1 THEN 'AU'
      WHEN r.CountryCode = 6 THEN 'NZ'
      ELSE ''
      END) AS ReceivedCountry,
  (
    CASE
      WHEN d.CountryCode = 1 THEN 'AU'
      WHEN d.CountryCode = 6 THEN 'NZ'
      ELSE ''
      END) AS DeliveryCountry,
  ReceivedRF,
  DeliveryRF,
  CAST(DATE_DIFF(PickupDate, DATE('1970-01-01'), DAY) AS STRING) AS PickupDate,
  sum(NumofPickups) AS NumofLabels,
  SUM(Price) AS Price
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Pickup_Performance5_WithPrice`
    p
INNER JOIN
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_RF` r
  ON p.ReceivedRF = r.FranchiseeCode
LEFT JOIN
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_RF` d
  ON p.DeliveryRF = d.FranchiseeCode
WHERE
  (r.CountryCode IN (1, 6))
  AND (
    PickupDate >= DATE_SUB(
      DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), MONTH),
      INTERVAL 1 MONTH))
  AND (
    PickupDate <= DATE_SUB(
      DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), INTERVAL 1 MONTH))
GROUP BY r.CountryCode, d.CountryCode, ReceivedRF, DeliveryRF, PickupDate

-- Same month last year
UNION ALL
SELECT
  (
    CASE
      WHEN r.CountryCode = 1 THEN 'AU'
      WHEN r.CountryCode = 6 THEN 'NZ'
      ELSE ''
      END) AS ReceivedCountry,
  (
    CASE
      WHEN d.CountryCode = 1 THEN 'AU'
      WHEN d.CountryCode = 6 THEN 'NZ'
      ELSE ''
      END) AS DeliveryCountry,
  ReceivedRF,
  DeliveryRF,
  CAST(DATE_DIFF(PickupDate, DATE('1970-01-01'), DAY) AS STRING) AS PickupDate,
  sum(NumofPickups) AS NumofLabels,
  SUM(Price) AS Price
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Pickup_Performance5_WithPrice`
    p
INNER JOIN
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_RF` r
  ON p.ReceivedRF = r.FranchiseeCode
LEFT JOIN
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_RF` d
  ON p.DeliveryRF = d.FranchiseeCode
WHERE
  (r.CountryCode IN (1, 6))
  AND (
    PickupDate >= DATE_SUB(
      DATE_TRUNC(DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), MONTH),
      INTERVAL 1 YEAR))
  AND (
    PickupDate <= DATE_SUB(
      DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY), INTERVAL 1 YEAR))
GROUP BY r.CountryCode, d.CountryCode, ReceivedRF, DeliveryRF, PickupDate
