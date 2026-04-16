CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_fl_InvoicePayment_Stg`(
  FromDate DATETIME
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_fl_InvoicePayment_Stg`
  /*
    Invoices are read with a >= EnteredDate rather than >
    meaning some invoices already in FastwayDW are re-read
    by this query. these duplicates are removed later
  */
  SELECT 
         InvoicePaymentId
        ,CountryId
        ,CustomerId
        ,InvoiceHeaderId
        ,JournalId
        ,CAST(Amount AS NUMERIC) AS Amount
        ,UpdatedOn
        ,UpdatedBy
    FROM `{{ project_id }}.{{ source_dataset_id }}.FWFastlabel_dbo_fl_InvoicePayment`
  WHERE UpdatedOn >= FromDate
    AND CountryId IN(1,6)
  ;

END;