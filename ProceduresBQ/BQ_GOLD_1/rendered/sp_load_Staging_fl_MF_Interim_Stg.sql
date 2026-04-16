CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.sp_load_Staging_fl_MF_Interim_Stg`(
)
BEGIN
  DECLARE startDate DATETIME;

  SET startDate = DATETIME(LAST_DAY(DATE_SUB(CURRENT_DATE(), INTERVAL 2 MONTH)), TIME '23:59:59');

  INSERT INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_fl_MF_Interim_Stg`
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
  FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_krillin_silver.FWFastlabel_dbo_fl_Con` con
  JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_krillin_silver.FWFastlabel_dbo_fl_ConItemSum` cis on cis.ConId = con.ConId
  JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_krillin_silver.FWFastlabel_dbo_fl_ConItem` ci on ci.ConId = cis.ConId and ci.LineNo = cis.LineNo
  WHERE con.CreatedOn > startDate
    AND Con.RealisedDate IS NOT NULL
  ;

END;