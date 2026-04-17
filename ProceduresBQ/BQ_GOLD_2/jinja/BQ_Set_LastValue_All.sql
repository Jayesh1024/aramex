
-- ==========================================================================================
-- Routine:		Set_LastValue_All
-- Description: Sets the Last Id/Date for all Staging tables defined in LoadControl
-- Example:		Exec [Staging].[Set_LastValue_All]  
-- History:
--	23/11/2018  P. Waldron		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.Staging_Set_LastValue_All`()
BEGIN

  FOR rec IN (
    SELECT RecordSource
    FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_LoadControl`
  )
  DO
    CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_Set_LastValue`(rec.RecordSource, NULL, NULL, FALSE);
  END FOR;

END;