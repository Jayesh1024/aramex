CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_dbo_DLBSRFBatching`(
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dbo_DLBSRFBatching`
  SELECT CAST(BatchId AS INT64) AS BatchId
        ,Date
        ,Time
        ,FromDate
        ,ToDate
        ,CAST(NumberOfInvoices AS INT64) AS NumberOfInvoices
        ,CAST(CountryCode AS INT64) AS CountryCode
        ,Processing
        ,Info
        ,CAST(Released AS STRING) AS Released
        ,CAST(IsOpen AS STRING) AS IsOpen
        ,CAST(LastExceptionNo AS INT64) AS LastExceptionNo
        ,CAST(PricedAndPrinted AS STRING) AS PricedAndPrinted
    FROM `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_invbtch`
    WHERE CountryCode in (1,6)
  ;

END;