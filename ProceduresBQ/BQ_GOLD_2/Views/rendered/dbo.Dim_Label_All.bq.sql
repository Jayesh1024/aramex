-- NOTE: Original SQL Server view was UNION of Dim_Label and Dim_Label_History using SELECT *.
-- In BQ, these tables have mismatched schemas (39 vs 37 columns, incompatible types).
-- Align the underlying table schemas before enabling the UNION.
CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label_All`
AS
SELECT * FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label_partitioned`