-- ==========================================================================================
-- Routine:     Load_LNK_Label_Product_ServiceItem  (BigQuery Version)
-- Description: Loads LNK_Label_Product_ServiceItem from Staging.fl_ConItemSrv_Stg
-- Example:     CALL dv.Load_LNK_Label_Product_ServiceItem(659, 'MyFastway')
-- History:
--  15/08/2020  P. Waldron      Routine Written
--  [BQ Migration] Converted SQL Server -> BigQuery
--    * CREATE PROCEDURE -> CREATE OR REPLACE PROCEDURE
--    * SYSDATETIME()    -> CURRENT_DATETIME()
--    * datetime2(3)     -> DATETIME
--    * NVARCHAR/VARCHAR -> STRING
--    * BIGINT/INT       -> INT64
--    * BEGIN TRY/CATCH  -> BEGIN ... EXCEPTION WHEN ERROR THEN ... END
--    * EXEC SaveLog     -> CALL Staging.SaveLog(...)
--    * @@ROWCOUNT       -> @@row_count
--    * GOTO RESULT      -> code after BEGIN...END block (always executes)
--    * SET NOCOUNT ON   -> removed (not applicable)
--    * RETURN IIF(...)  -> removed (BQ procedures have no return value)
--    * v_ prefix used on local scalar vars to avoid column-name ambiguity in SELECT
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE dv.Load_LNK_Label_Product_ServiceItem(
    IN ProcessID    INT64,
    IN RecordSource STRING   -- Pass NULL to use default 'MyFastway'
)
BEGIN
    DECLARE v_Loaded        DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_RecordSource  STRING   DEFAULT IFNULL(RecordSource, 'MyFastway');
    DECLARE Component       STRING   DEFAULT 'dv.Load_LNK_Label_Product_ServiceItem';
    DECLARE Started         DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended           DATETIME;
    DECLARE Result          STRING   DEFAULT 'Success';
    DECLARE ErrorMessage    STRING   DEFAULT NULL;
    DECLARE Inserted        INT64    DEFAULT 0;
    DECLARE Updated         INT64    DEFAULT 0;

    BEGIN

        INSERT INTO dv.LNK_Label_Product_ServiceItem
        (
            Label_Product_ServiceItem_HSK,
            LabelNo_HSK,
            Product_HSK,
            ServiceItem_HSK,
            LabelNo,
            Country,
            ProductCode,
            ServiceItem,
            Loaded,
            ProcessID,
            RecordSource,
            RecordSourceId
        )
        SELECT
            Stg.Label_Product_ServiceItem_HSK,
            Stg.LabelNo_HSK,
            Stg.Product_HSK,
            Stg.ServiceItem_HSK,
            Stg.LabelNo,
            Stg.Country,
            Stg.ProductCode,
            Stg.ServiceItem,
            v_Loaded        AS Loaded,
            ProcessID       AS ProcessID,
            v_RecordSource  AS RecordSource,
            Stg.RecordSourceId
        FROM Staging.Label_Product_ServiceItem_Stg AS Stg
        WHERE NOT EXISTS (
            SELECT 1
            FROM dv.LNK_Label_Product_ServiceItem AS Tgt
            WHERE Tgt.Label_Product_ServiceItem_HSK = Stg.Label_Product_ServiceItem_HSK
        );

        SET Inserted = @@row_count;
        SET Result   = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed';
        SET ErrorMessage = @@error_message;
    END;

    -- Record load metrics in log (always executes – equivalent to GOTO RESULT label)
    SET Ended = CURRENT_DATETIME();
    CALL Staging.SaveLog(
        Component,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted
    );

END;
