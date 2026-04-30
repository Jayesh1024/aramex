CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_FMS_InvoiceBooks_Stg`(
  FromDate DATETIME
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_FMS_InvoiceBooks_Stg`
  /*
    Invoices are read with a >= SystemDate rather than >
    meaning some invoices already in FastwayDW are re-read
    by this query. these duplicates are removed later
  */
  SELECT RFCode
        ,InvoiceNumber
        ,ProductId
        ,IssueOrReceipt
        ,Label
        ,CustomerId
        ,CourierId
        ,NMId
    FROM `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_FMS_InvoiceBooks` as stg
    WHERE EXISTS (
        select 1 from `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_FMS_InvoiceHead` h 
                where h.EnteredDate >= FromDate
  	and h.InvoiceNumber = stg.InvoiceNumber 
  	and h.RFCode = stg.RFCode
                     and h.NMId in (1,6) 
    )
  ;

END;