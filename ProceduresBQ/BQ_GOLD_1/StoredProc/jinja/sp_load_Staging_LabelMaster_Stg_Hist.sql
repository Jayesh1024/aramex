-- ==========================================================================================
-- Routine:     sp_load_Staging_LabelMaster_Stg_Hist
-- Description: One-shot historical load of LabelMaster staging from silver sources.
--              No UploadDate watermark or 1-month ScanDate window (unlike incremental).
-- Example:     CALL sp_load_Staging_LabelMaster_Stg_Hist();
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_LabelMaster_Stg_Hist`(
)
BEGIN

  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_LabelMaster_Stg`
  WITH Scan AS (
      SELECT LabelNo, MAX(UploadDate) AS UploadDate
      FROM `{{ project_id }}.{{ source_dataset_id }}.FastwayReports_dbo_TrackAndTraceDataP`
      WHERE CountryCode IN (1, 6, 11, 24)
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
        ,CAST(KPI_PickupOK AS INT64) AS KPI_PickupOK
        ,CAST(KPI_DeliveryOK AS INT64) AS KPI_DeliveryOK
        ,CAST(KPI_LatePickup AS INT64) AS KPI_LatePickup
        ,CAST(KPI_LateDelivery AS INT64) AS KPI_LateDelivery
        ,KPI_DelRF
        ,KPI_PicRF
        ,FMSCustomerID
        ,FMSRfID
        ,OES_CustomerId
        ,KPI_ExpectedDelivery
        ,KPI_ExceptionScan
        ,PrintedOn
        ,EbayClickCollect
        ,CAST(HasSubscriptions AS INT64) AS HasSubscriptions
        ,Scan.UploadDate
  FROM `{{ project_id }}.{{ source_dataset_id }}.FastwayReports_dbo_LabelMaster` AS Label
  JOIN Scan ON Scan.LabelNo = Label.LabelNo
  WHERE CountryCode IN (1, 6, 11, 24);

END;
