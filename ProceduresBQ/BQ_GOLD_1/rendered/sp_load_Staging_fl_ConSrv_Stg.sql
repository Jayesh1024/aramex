CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.sp_load_Staging_fl_ConSrv_Stg`(
)
BEGIN
  DECLARE startDate2 DATETIME;
  DECLARE v_ConId INT64;
  SET startDate2 = DATE_SUB(CURRENT_DATETIME(), INTERVAL 14 DAY);

  SET v_ConId = (
    SELECT ConId
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.FWFastlabel_dbo_fl_Con`
    WHERE CreatedOn >= startDate2
    ORDER BY CreatedOn
    LIMIT 1
  );

  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_fl_ConSrv_Stg`
  SELECT cs.ConId
  ,con.CountryId
  ,cs.ServiceItemId
  ,cs.ProductId
  ,con.CreatedOn
  ,cs.FMSInvoiceNo
  ,cs.FMSInvoiceDate
  ,CAST(cs.Price AS NUMERIC) AS Price
  ,CAST(cs.Tax AS NUMERIC) AS Tax
  ,CAST(cs.Total AS NUMERIC) AS Total
  ,CAST(cs.PickUpPrice AS NUMERIC) AS PickUpPrice
  ,CAST(cs.DeliveryPrice AS NUMERIC) AS DeliveryPrice
  ,cs.DLBSBatchId
  ,cs.DLBSInvoiceNo
  ,cs.DLBSInvoiceDate
  ,CAST(cs.DLBSPrice AS NUMERIC) AS DLBSPrice
  ,CAST(cs.DLBSTax AS NUMERIC) AS DLBSTax
  ,CAST(cs.DLBSTotal AS NUMERIC) AS DLBSTotal
  ,cs.PLBSBatchId
  ,cs.PLBSInvoiceNo
  ,cs.PLBSInvoiceDate
  ,CAST(cs.PLBSPrice AS NUMERIC) AS PLBSPrice
  ,CAST(cs.PLBSTax AS NUMERIC) AS PLBSTax
  ,CAST(cs.PLBSTotal AS NUMERIC) AS PLBSTotal
  ,CAST(cs.ServicePrice AS NUMERIC) AS ServicePrice
  ,CAST(cs.ServicePriceDiscountPercent AS NUMERIC) AS ServicePriceDiscountPercent
  ,CAST(cs.ServicePriceDiscountFixed AS NUMERIC) AS ServicePriceDiscountFixed
  ,CAST(cs.ServicePriceCommPercent AS NUMERIC) AS ServicePriceCommPercent
  ,CAST(cs.ServicePriceComm AS NUMERIC) AS ServicePriceComm
  ,cs.UpdatedOn
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.FWFastlabel_dbo_fl_ConSrv` cs 
  INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.FWFastlabel_dbo_fl_Con` con  on con.ConId = cs.ConId
  WHERE con.ConId >= v_ConId
  ;

END;