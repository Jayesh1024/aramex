CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.sp_load_Staging_ZEN_Ticket_Stg`(
  LastDate DATETIME
)
BEGIN
  --  FROM Fastway_dbo_ZEN_Tickets
  --WHERE SysLastUpdatedUtc > LastDate

  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_ZEN_Ticket_Stg`
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
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_ZEN_Tickets`
  WHERE  SysLastUpdatedUtc > LastDate
  ;

END;