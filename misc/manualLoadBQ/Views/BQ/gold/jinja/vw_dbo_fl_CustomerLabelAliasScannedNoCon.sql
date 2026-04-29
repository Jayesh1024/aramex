-- Miscellaneous.dtsx / Maintain fl_CustomerLabelAliasScannedNoCon
-- SSIS: FWFastlabel.dbo.fl_CustomerLabelAliasScannedNoCon -> CUBE.FastwayDW dbo.fl_CustomerLabelAliasScannedNoCon
CREATE OR REPLACE VIEW `{{ project_id }}.{{ gold_dataset_id }}.vw_dbo_fl_CustomerLabelAliasScannedNoCon` AS
SELECT
  *
FROM
  `{{ project_id }}.{{ silver_dataset_id }}.FWFastlabel_dbo_fl_CustomerLabelAliasScannedNoCon`;
