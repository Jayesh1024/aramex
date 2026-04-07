
-- ==========================================================================================
-- Routine:		Set_LastValue_All
-- Description: Sets the Last Id/Date for all staging tables defined in LoadControl
-- Example:		Exec [Staging].[Set_LastValue_All]  
-- History:
--	23/11/2018  P. Waldron		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ dataset_id }}.staging_Set_LastValue_All`()
BEGIN

  FOR rec IN (
    SELECT RecordSource
    FROM `{{ project_id }}.{{ dataset_id }}.staging_LoadControl`
  )
  DO
    CALL `{{ project_id }}.{{ dataset_id }}.staging_Set_LastValue`(rec.RecordSource, NULL, NULL, FALSE);
  END FOR;

END;