CREATE OR REPLACE PROCEDURE `dv.Load_HUB_ZEN_Ticket`(
    IN p_ProcessID INT64,
    IN p_RecordSource STRING
)
BEGIN
    DECLARE v_Loaded TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Component STRING DEFAULT 'dv.Load_HUB_ZEN_Ticket';
    DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;

    BEGIN
        -- A MERGE statement efficiently handles the "Insert if Not Exists" Hub load pattern,
        -- replacing the CTE, LEFT JOIN, and INSERT approach from SQL Server.
        MERGE INTO `dv.HUB_ZEN_Ticket` AS Dest
        USING (
            SELECT DISTINCT 
                ZenDeskTicketId,
                RTRIM(CAST(LabelNo AS STRING)) AS LabelNo
            FROM `Staging.ZEN_Ticket_Stg`
        ) AS Src
        ON CAST(Dest.ZenDeskTicketId AS STRING) = RTRIM(CAST(Src.ZenDeskTicketId AS STRING))
        WHEN NOT MATCHED THEN
            INSERT (
                ZenTicket_HSK,
                LabelNo,
                ZenDeskTicketId,
                Loaded,
                ProcessID,
                RecordSource
            )
            VALUES (
                -- Assuming GetHashKey is migrated as a BigQuery UDF.
                -- CONVERT(varchar(10), ...) translates to casting/substring in BigQuery.
                `dbo.GetHashKey`(SUBSTR(CAST(Src.ZenDeskTicketId AS STRING), 1, 10)),
                Src.LabelNo,
                Src.ZenDeskTicketId,
                v_Started, -- The original T-SQL explicitly used @Started instead of @Loaded here
                p_ProcessID,
                p_RecordSource
            );

        -- Capture the number of new records inserted
        SET v_Inserted = @@row_count;

    EXCEPTION WHEN ERROR THEN
        SET v_Result = 'Failed';
        SET v_ErrorMessage = @@error.message;
    END;

    -- Final Log Call (Handles both Success and Failure metrics)
    CALL `Staging.SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,
        CURRENT_TIMESTAMP(),
        v_Result,
        v_ErrorMessage,
        v_Inserted,
        v_Updated,
        -1
    );
END;