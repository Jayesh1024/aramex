-- ==========================================================================================
-- Routine:     dv_Load_SAT_ZEN_Ticket
-- Description: Loads SAT_ZEN_Ticket from `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_ZEN_Ticket_Stg`
--              BigQuery compatible version of Load_SAT_ZEN_Ticket
--              Note: WITH (TABLOCK) hints removed.
--                    UPDATE ... FROM replaced with MERGE (BQ requires MERGE for UPDATE with JOIN).
--                    dbo.GetHashKey replaced with TO_HEX(MD5(...)).
-- Example:     CALL dv.dv_Load_SAT_ZEN_Ticket(-29, 'ZENLog')
-- History:
--  13/04/2024  B. Woods        Routine Written
--  [BQ Port]   Converted from SQL Server to BigQuery
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_SAT_ZEN_Ticket`(
    IN ProcessID    INT64,
    IN RecordSource STRING
)
BEGIN

    DECLARE Loaded    DATETIME DEFAULT CURRENT_DATETIME();

    DECLARE Component    STRING DEFAULT 'dv.Load_SAT_ZEN_Ticket';
    DECLARE Started      DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE Ended        DATETIME;
    DECLARE Result       STRING;
    DECLARE ErrorMessage STRING;
    DECLARE Updated      INT64 DEFAULT 0;
    DECLARE Inserted     INT64 DEFAULT 0;

    BEGIN

        -- -----------------------------------------------------------------------
        -- STEP 1: Insert new rows (ZenDeskTicketId not yet in target)
        -- -----------------------------------------------------------------------
        INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_ZEN_Ticket`
        SELECT
            MD5(CAST(ZenDeskTicketId AS STRING)) AS ZenTicket_HSK,
            ZenDeskTicketId,
            TRIM(LabelNo)   AS LabelNo,
            Subject,
            CreatedDate,
            CreatedTime,
            TicketType,
            Issue,
            Solved,
            Started         AS Loaded,
            ProcessID       AS ProcessID,
            RecordSource,
            SysLastUpdatedUtc
        FROM (
            SELECT DISTINCT
                Src.ZenDeskTicketId,
                TRIM(Src.LabelNo)       AS LabelNo,
                Src.Subject,
                Src.CreatedDate,
                Src.CreatedTime,
                Src.TicketType,
                Src.Issue,
                Src.Solved,
                Src.SysLastUpdatedUtc
            FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_ZEN_Ticket_Stg` AS Src
            WHERE NOT EXISTS (
                SELECT 1
                FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_ZEN_Ticket` AS Dest
                WHERE Dest.ZenDeskTicketId = Src.ZenDeskTicketId
            )
        );

        SET Inserted = @@ROW_COUNT;
        SET Result   = 'Success';

        -- -----------------------------------------------------------------------
        -- STEP 2: Update existing rows (ZenDeskTicketId already in target)
        -- Replaces UPDATE ... FROM using MERGE
        -- -----------------------------------------------------------------------
        MERGE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_ZEN_Ticket` AS Tgt
        USING (
            SELECT DISTINCT
                Src.ZenDeskTicketId,
                TRIM(Src.LabelNo)       AS LabelNo,
                Src.Subject,
                Src.CreatedDate,
                Src.CreatedTime,
                Src.TicketType,
                Src.Issue,
                Src.Solved,
                Src.SysLastUpdatedUtc
            FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_ZEN_Ticket_Stg` AS Src
            WHERE EXISTS (
                SELECT 1
                FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_ZEN_Ticket` AS Dest
                WHERE Dest.ZenDeskTicketId = Src.ZenDeskTicketId
            )
        ) AS Src
        ON Tgt.ZenDeskTicketId = Src.ZenDeskTicketId
        WHEN MATCHED THEN UPDATE SET
            Tgt.LabelNo           = Src.LabelNo,
            Tgt.Subject           = Src.Subject,
            Tgt.CreatedDate       = Src.CreatedDate,
            Tgt.CreatedTime       = Src.CreatedTime,
            Tgt.TicketType        = Src.TicketType,
            Tgt.Issue             = Src.Issue,
            Tgt.Solved            = Src.Solved,
            Tgt.Loaded            = Started,
            Tgt.ProcessID         = ProcessID,
            Tgt.RecordSource      = RecordSource,
            Tgt.SysLastUpdatedUtc = Src.SysLastUpdatedUtc;

        SET Updated = @@ROW_COUNT;
        SET Result  = 'Success';

    EXCEPTION WHEN ERROR THEN
        SET Result       = 'Failed';
        SET ErrorMessage = @@error.message;

    END;

    -- Record load metrics in log
    SET Result = 'Success';
    SET Ended  = CURRENT_DATETIME();
    CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
        Component,
        ProcessID,
        Started,
        Ended,
        Result,
        ErrorMessage,
        Inserted,
        Updated,
        -1
    );

END;