CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_ZEN_Ticket_Stg`(
  LastDate DATETIME
)
BEGIN
  --  FROM Fastway_dbo_ZEN_Tickets
  --WHERE SysLastUpdatedUtc > LastDate

  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_ZEN_Ticket_Stg`
  SELECT 
         ZenDeskTicketId
        ,LabelNo
        ,Subject
        ,CreatedDate
        ,CreatedTime
        ,TicketType
        ,Issue
        ,CAST(Solved AS INT64) AS Solved
        ,SysLastUpdatedUtc
    FROM `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_ZEN_Tickets`
  WHERE  SysLastUpdatedUtc > LastDate
  ;

END;