CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.sp_load_Staging_FMS_InvoiceBooks_Stg_Hist`(
)
BEGIN
  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_FMS_InvoiceBooks_Stg`
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
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_FMS_InvoiceBooks` as stg
    WHERE EXISTS (
        select 1 from `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_FMS_InvoiceHead` h 
                where
                h.InvoiceNumber = stg.InvoiceNumber 
                and h.RFCode = stg.RFCode
                and h.NMId in (1,6) 
    )
  ;

END