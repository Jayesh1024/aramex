
-- ==========================================================================================
-- Routine:		Set_LastValue_All
-- Description: Sets the Last Id/Date for all Staging tables defined in LoadControl
-- Example:		Exec [Staging].[Set_LastValue_All]  
-- History:
--	23/11/2018  P. Waldron		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `searce-sandbox-da-delivery.Aramex_oceania_SP.Staging_Set_LastValue_All`()
BEGIN

  FOR rec IN (
    SELECT RecordSource
    FROM `searce-sandbox-da-delivery.Aramex_oceania.Staging_LoadControl`
  )
  DO
    CALL `searce-sandbox-da-delivery.Aramex_oceania_SP.Staging_Set_LastValue`(rec.RecordSource, NULL, NULL, FALSE);
  END FOR;

END;