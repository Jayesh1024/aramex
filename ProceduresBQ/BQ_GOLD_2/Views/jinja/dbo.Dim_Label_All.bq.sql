-- NOTE: Original SQL Server view was UNION of Dim_Label and Dim_Label_History using SELECT *.
-- In BQ, these tables have mismatched schemas (39 vs 37 columns, incompatible types).
-- Align the underlying table schemas before enabling the UNION.
CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Dim_Label_All`
AS
SELECT * FROM `{{ project_id }}.{{ dataset_id }}.dbo_Dim_Label_partitioned`