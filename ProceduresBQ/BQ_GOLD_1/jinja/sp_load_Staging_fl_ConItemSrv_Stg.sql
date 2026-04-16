CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_fl_ConItemSrv_Stg`(
  startDate DATETIME
)
BEGIN
  DECLARE startDate2 DATETIME;
  DECLARE v_ConId INT64;

  SET v_ConId = (
    SELECT ConId
    FROM `{{ project_id }}.{{ source_dataset_id }}.FWFastlabel_dbo_fl_Con`
    WHERE CreatedOn >= startDate2
    ORDER BY CreatedOn
    LIMIT 1
  );

  SET startDate2 = DATE_SUB(CURRENT_DATETIME(), INTERVAL 30 DAY);

  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_fl_ConItemSrv_Stg`
  SELECT ci.Label
        ,cis.ConId
        ,cis.ConItemId
        ,ci.LineNo
        ,ci.CountryId
        ,cis.ProductId
        ,cis.ServiceItemId
        ,con.CreatedOn
        ,cis.FMSInvoiceNo
        ,cis.FMSInvoiceDate
        ,CAST(cis.Price AS NUMERIC) AS Price
        ,CAST(cis.Tax AS NUMERIC) AS Tax
        ,CAST(cis.Total AS NUMERIC) AS Total
        ,CAST(cis.PickUpPrice AS NUMERIC) AS PickUpPrice
        ,CAST(cis.DeliveryPrice AS NUMERIC) AS DeliveryPrice
        ,cis.DLBSBatchId
        ,cis.DLBSInvoiceNo
        ,cis.DLBSInvoiceDate
        ,CAST(cis.DLBSPrice AS NUMERIC) AS DLBSPrice
        ,CAST(cis.DLBSTax AS NUMERIC) AS DLBSTax
        ,CAST(cis.DLBSTotal AS NUMERIC) AS DLBSTotal
        ,cis.PLBSBatchId
        ,cis.PLBSInvoiceNo
        ,cis.PLBSInvoiceDate
        ,CAST(cis.PLBSPrice AS NUMERIC) AS PLBSPrice
        ,CAST(cis.PLBSTax AS NUMERIC) AS PLBSTax
        ,CAST(cis.PLBSTotal AS NUMERIC) AS PLBSTotal
        ,cis.BareProfileId
        ,CAST(cis.ServicePrice AS NUMERIC) AS ServicePrice
        ,CAST(cis.ServicePriceComm AS NUMERIC) AS ServicePriceComm
        ,CAST(cis.ServicePriceCommPercent AS NUMERIC) AS ServicePriceCommPercent
        ,CAST(cis.ServicePriceDiscountFixed AS NUMERIC) AS ServicePriceDiscountFixed
        ,CAST(cis.ServicePriceDiscountPercent AS NUMERIC) AS ServicePriceDiscountPercent
        ,cis.UpdatedOn
    FROM `{{ project_id }}.{{ source_dataset_id }}.FWFastlabel_dbo_fl_ConItemSrv` cis  
    INNER JOIN `{{ project_id }}.{{ source_dataset_id }}.FWFastlabel_dbo_fl_Con` con  on con.ConId = cis.ConId
    INNER JOIN `{{ project_id }}.{{ source_dataset_id }}.FWFastlabel_dbo_fl_ConItem` ci  on ci.ConId = cis.ConId AND ci.ConItemId = cis.ConItemId
  WHERE con.ConId >= v_ConId
  ;

END;