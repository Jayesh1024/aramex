CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Dim_Container` AS(
SELECT Container
  FROM `{{ project_id }}.{{ dataset_id }}.dv_HUB_Container`
 )