-- ==========================================================================================
-- Routine:     Load_HUB_Product
-- Description: Loads business keys into HUB_Product
-- Example:     Exec [dv].[Load_HUB_Product] 123, 'ZENLog'  
-- History:
--  13/04/2024  B. Woods      Routine Written
--
-- ==========================================================================================

CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_HUB_ZEN_Ticket`(
    IN p_ProcessID INT64,
    IN p_RecordSource STRING
)
OPTIONS(strict_mode=false)
BEGIN
    DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Component STRING DEFAULT 'dv_Load_HUB_ZEN_Ticket';
    DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
    DECLARE v_Result STRING DEFAULT 'Success';
    DECLARE v_ErrorMessage STRING;
    DECLARE v_Inserted INT64 DEFAULT 0;
    DECLARE v_Updated INT64 DEFAULT 0;

    BEGIN
        -- A MERGE statement handles the Hub load pattern using Jinja2 templates for all identifiers.
        -- p_RecordSource remains a dynamic input parameter.
        MERGE INTO `{{ project_id }}.{{ target_dataset_id }}.dv_HUB_ZEN_Ticket` AS Dest
        USING (
            SELECT DISTINCT 
                ZenDeskTicketId,
                RTRIM(CAST(LabelNo AS STRING)) AS LabelNo
            FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_ZEN_Ticket_Stg`
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
                -- Assuming GetHashKey is migrated as a BigQuery UDF within the target project/dataset
                `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(SUBSTR(CAST(Src.ZenDeskTicketId AS STRING), 1, 10), '^'),
                Src.LabelNo,
                Src.ZenDeskTicketId,
                v_Started, 
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
    CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
        v_Component,
        p_ProcessID,
        v_Started,
        CURRENT_DATETIME(),
        v_Result,
        v_ErrorMessage,
        v_Inserted,
        v_Updated,
        -1
    );
END;