CREATE VIEW `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIMatrix` AS
SELECT
  CountryCode,
  PickupFranchise,
  DeliveryFranchise,
  CAST(Days AS INT64) AS Days,
  EconomyDays,
  PriorityDays
FROM
  `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_NonLocalKPIMatrix`
WHERE
  IFNULL(Prefix, '') = ''