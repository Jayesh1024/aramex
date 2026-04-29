-- ==========================================================================================
-- Routine:		SaveLog
-- Description: Saves load metrics
--
-- History:
--	23/04/2019  P. Waldron		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
IN p_Component STRING,
IN p_ProcessId INT64,
IN p_Started DATETIME,
IN p_Ended DATETIME,
IN p_Result STRING,
IN p_ErrorMessage STRING,
IN p_Inserted INT64,
IN p_Updated INT64,
IN p_Errors INT64
)
BEGIN

INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_LoadLog` (
Component,
ProcessId,
Started,
Ended,
Result,
ErrorMessage,
Inserted,
Updated,
Errors
)
VALUES (
p_Component,
p_ProcessId,
p_Started,
IFNULL(p_Ended, CURRENT_DATETIME()),
p_Result,
p_ErrorMessage,
p_Inserted,
p_Updated,
p_Errors
);
END;