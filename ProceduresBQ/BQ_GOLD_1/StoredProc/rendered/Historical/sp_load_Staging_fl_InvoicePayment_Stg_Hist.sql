CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.sp_load_Staging_fl_InvoicePayment_Stg_Hist`(
)
BEGIN
  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_fl_InvoicePayment_Stg`
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
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.FWFastlabel_dbo_fl_InvoicePayment`
    WHERE CountryId IN(1,6)
  ;

END;