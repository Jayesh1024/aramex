CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Dim_Truck` AS 

SELECT TruckNum
  FROM `{{ project_id }}.{{ dataset_id }}.dv_HUB_Truck`GO