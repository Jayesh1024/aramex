CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_CF_Productivity`
AS
SELECT * FROM `{{ project_id }}.{{ dataset_id }}.dbo_CF_Productivity_AU_partitioned`
UNION DISTINCT
SELECT * FROM `{{ project_id }}.{{ dataset_id }}.dbo_CF_Productivity_NZ_partitioned`