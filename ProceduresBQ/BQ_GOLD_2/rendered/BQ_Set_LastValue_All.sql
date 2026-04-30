
-- ==========================================================================================
-- Routine:		Set_LastValue_All
-- Description: Sets the Last Id/Date for all Staging tables defined in LoadControl
-- Example:		Exec [Staging].[Set_LastValue_All]  
-- History:
--	23/11/2018  P. Waldron		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_Set_LastValue_All`()
BEGIN

  FOR rec IN (
    SELECT RecordSource
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_LoadControl`
  )
  DO
    CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_Set_LastValue`(rec.RecordSource, NULL, NULL, FALSE);
  END FOR;

END;