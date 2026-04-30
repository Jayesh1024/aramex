CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_InterimStaging_TrackAndTraceData_SignatureAI_Stg`(
  LastUpdateDate DATETIME
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.InterimStaging_TrackAndTraceData_SignatureAI_Stg`
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
    FROM `{{ project_id }}.{{ source_dataset_id }}.FastwayReports_dbo_TrackAndTraceData_SignatureAI`
  WHERE LastUpdatedOn > LastUpdateDate
  ;

END;