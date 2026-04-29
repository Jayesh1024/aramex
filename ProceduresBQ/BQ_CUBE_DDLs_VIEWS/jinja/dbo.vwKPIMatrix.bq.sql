CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_vwKPIMatrix` as
select CountryCode, PickupFranchise, DeliveryFranchise, Days from `{{ project_id }}.{{ dataset_id }}.dbo_NonLocalKPIMatrix`
UNION DISTINCT
select CountryCode, Franchise, Franchise, 1 from `{{ project_id }}.{{ dataset_id }}.dbo_LocalKPIMatrix`;