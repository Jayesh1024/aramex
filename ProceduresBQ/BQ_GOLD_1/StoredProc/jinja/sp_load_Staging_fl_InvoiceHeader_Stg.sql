CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_fl_InvoiceHeader_Stg`(
  FromDate DATETIME
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_fl_InvoiceHeader_Stg`
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
    FROM `{{ project_id }}.{{ source_dataset_id }}.FWFastlabel_dbo_fl_InvoiceHeader`
  WHERE InvoiceDate >= FromDate
    AND CountryId IN(1,6)
  ;

END;