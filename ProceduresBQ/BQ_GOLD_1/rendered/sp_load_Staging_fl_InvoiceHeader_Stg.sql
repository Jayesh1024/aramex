CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.sp_load_Staging_fl_InvoiceHeader_Stg`(
  FromDate DATETIME
)
BEGIN
  INSERT INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_fl_InvoiceHeader_Stg`
  /*
    Invoices are read with a >= EnteredDate rather than >
    meaning some invoices already in FastwayDW are re-read
    by this query. these duplicates are removed later
  */
  SELECT 
         InvoiceHeaderId
        ,BatchId
        ,RF
        ,ParentRF
        ,CountryId
        ,CustomerId
        ,ParentCustomerId
        ,InvoiceNo
        ,InvoiceDate
        ,Price
        ,Tax
        ,Total
        ,GroupPrice
        ,GroupTax
        ,GroupTotal
        ,CAST(Released AS INT64) AS Released
        ,RFLegalEntity
        ,ParentRFLegalEntity
        ,CFLegalEntity
        ,Level
        ,CAST(BankProcess AS INT64) AS BankProcess
        ,ParentInvoiceHeaderId
        ,CFOverride
        ,CFOverrideBasePriceCommPercent
        ,CFOverrideExcessPriceCommPercent
        ,CAST(SelectedUI AS INT64) AS SelectedUI
        ,CAST(EnterpriseFastlabelType AS INT64) AS EnterpriseFastlabelType
        ,DueDate
        ,CloseDate
        ,TotalPaid
        ,CourierNumber
        ,CAST(GroupTaxExempt AS INT64) AS GroupTaxExempt
    FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_krillin_silver.FWFastlabel_dbo_fl_InvoiceHeader`
  WHERE InvoiceDate >= FromDate
    AND CountryId IN(1,6)
  ;

END;