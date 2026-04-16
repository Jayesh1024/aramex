CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_fl_MF_Interim_Stg`(
)
BEGIN
  DECLARE startDate DATETIME;

  SET startDate = DATETIME(LAST_DAY(DATE_SUB(CURRENT_DATE(), INTERVAL 2 MONTH)), TIME '23:59:59');

  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_fl_MF_Interim_Stg`
  SELECT 
  ci.Label,
  con.CountryId,
  con.CreatedOn,
  ci.FromRf,
  ci.FromCf,
  ci.ToRf,
  ci.ToCf,
  con.ToLocality,
  con.ToPostalCode,
  con.RealisedDate,
  ci.Zone,
  con.CustomerId
  FROM `{{ project_id }}.{{ source_dataset_id }}.FWFastlabel_dbo_fl_Con` con
  JOIN `{{ project_id }}.{{ source_dataset_id }}.FWFastlabel_dbo_fl_ConItemSum` cis on cis.ConId = con.ConId
  JOIN `{{ project_id }}.{{ source_dataset_id }}.FWFastlabel_dbo_fl_ConItem` ci on ci.ConId = cis.ConId and ci.LineNo = cis.LineNo
  WHERE con.CreatedOn > startDate
    AND Con.RealisedDate IS NOT NULL
  ;

END;