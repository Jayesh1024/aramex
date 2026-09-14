CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_vwKPIMatrix` as
select CountryCode, PickupFranchise, DeliveryFranchise, Days from `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_NonLocalKPIMatrix`
UNION DISTINCT
select CountryCode, Franchise, Franchise, 1 from `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_LocalKPIMatrix`;