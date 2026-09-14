-- Miscellaneous.dtsx / Maintain fl_CustomerLabelAliasScannedNoCon
-- SSIS: FWFastlabel.dbo.fl_CustomerLabelAliasScannedNoCon -> CUBE.FastwayDW dbo.fl_CustomerLabelAliasScannedNoCon
CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_fl_CustomerLabelAliasScannedNoCon` AS
SELECT
  *
FROM
  `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.FWFastlabel_dbo_fl_CustomerLabelAliasScannedNoCon`;