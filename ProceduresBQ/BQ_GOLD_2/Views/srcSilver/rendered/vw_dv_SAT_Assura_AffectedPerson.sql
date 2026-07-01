CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Assura_AffectedPerson` AS
SELECT
  ObjectId,
  EventObjectId,
  Person,
  ReportingClassification,
  AffectedPersonType,
  CausedBy
FROM prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_vegeta_silver.FastwayReports_dbo_Assura_AffectedPerson