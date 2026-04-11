
-- ==========================================================================================
-- Routine:		Set_LastValue_All
-- Description: Sets the Last Id/Date for all Staging tables defined in LoadControl
-- Example:		Exec [Staging].[Set_LastValue_All]  
-- History:
--	23/11/2018  P. Waldron		Routine Written
-- ==========================================================================================
<<<<<<< HEAD:ProceduresBQ/Jinja PlaceHolder SPs/BQ_Set_LastValue_All.sql
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.Staging_Set_LastValue_All`()
=======
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ dataset_id }}.staging_Set_LastValue_All`()
>>>>>>> refs/remotes/origin/dev_manas:ProceduresBQ/BQ_Set_LastValue_All.sql
BEGIN

  FOR rec IN (
    SELECT RecordSource
<<<<<<< HEAD:ProceduresBQ/Jinja PlaceHolder SPs/BQ_Set_LastValue_All.sql
    FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_LoadControl`
  )
  DO
    CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_Set_LastValue`(rec.RecordSource, NULL, NULL, FALSE);
=======
    FROM `{{ project_id }}.{{ dataset_id }}.staging_LoadControl`
  )
  DO
    CALL `{{ project_id }}.{{ dataset_id }}.staging_Set_LastValue`(rec.RecordSource, NULL, NULL, FALSE);
>>>>>>> refs/remotes/origin/dev_manas:ProceduresBQ/BQ_Set_LastValue_All.sql
  END FOR;

END;