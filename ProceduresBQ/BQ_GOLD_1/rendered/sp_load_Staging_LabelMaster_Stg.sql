CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.sp_load_Staging_LabelMaster_Stg`(
  startDate DATETIME
)
BEGIN
  SET startDate = DATE_SUB(startDate, INTERVAL 1 DAY);

  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_LabelMaster_Stg`
  WITH Scan AS (
      SELECT LabelNo, max(UploadDate) as UploadDate
      FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_vegeta_silver.FastwayReports_dbo_TrackAndTraceDataP` 
      WHERE UploadDate > startDate 
      AND ScanDate >= DATE_SUB(CURRENT_DATETIME(), INTERVAL 1 MONTH)
      AND CountryCode IN (1,6,11,24)
      GROUP BY LabelNo
  )
  
  SELECT 
         Label.LabelNo
        ,CountryCode
        ,Electronic_CustomerType
        ,Electronic_CustomerID
        ,Electronic_Reference
        ,FastLabel_ConsignmentID
        ,FastLabel_DestinationRF
        ,Distribution_Date
        ,Distribution_FranchiseeCode
        ,KPI_PickupOK
        ,KPI_DeliveryOK
        ,KPI_LatePickup
        ,KPI_LateDelivery
        ,KPI_DelRF
        ,KPI_PicRF
        ,FMSCustomerID
        ,FMSRfID
        ,OES_CustomerId
        ,KPI_ExpectedDelivery
        ,KPI_ExceptionScan
        ,PrintedOn
        ,EbayClickCollect
        ,HasSubscriptions
        ,Scan.UploadDate
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_vegeta_silver.FastwayReports_dbo_LabelMaster` AS Label
  JOIN Scan ON Scan.LabelNo = Label.LabelNo 
  WHERE CountryCode IN (1,6,11,24)
  ;

END;