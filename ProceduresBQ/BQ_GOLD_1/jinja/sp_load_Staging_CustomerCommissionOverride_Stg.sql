CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_CustomerCommissionOverride_Stg`(
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_CustomerCommissionOverride_Stg`
  SELECT NmId
        ,RFCode
        ,Courier
        ,ProductId
        ,Percentage
        ,UpdatedOn
        ,UpdatedBy
  FROM `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_FMS_CustomerCommisionOverride`
  ;

END;