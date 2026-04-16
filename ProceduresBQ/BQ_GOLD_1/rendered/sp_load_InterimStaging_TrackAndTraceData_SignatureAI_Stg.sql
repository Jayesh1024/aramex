CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.sp_load_InterimStaging_TrackAndTraceData_SignatureAI_Stg`(
  LastUpdateDate DATETIME
)
BEGIN
  INSERT INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.InterimStaging_TrackAndTraceData_SignatureAI_Stg`
  SELECT TrackAndTraceId
        ,AILabel
        ,AIScore
        ,AIVersion
        ,UserLabel
        ,ValidatedByUsername
        ,CourierNo
        ,FranchiseeCode
        ,ScanDate
        ,LastUpdatedOn
        ,TrainingLabel
    FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_vegeta_silver.FastwayReports_dbo_TrackAndTraceData_SignatureAI`
  WHERE LastUpdatedOn > LastUpdateDate
  ;

END;