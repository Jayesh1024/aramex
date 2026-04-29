CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Dim_ScanStatus` AS 
SELECT
      hub.CountryName
      ,hub.ScanStatus
      ,Description
      ,ExtendedDescription
      ,ShowToCustomer
      ,Misdirected
      ,LeftByCF
      ,Undeliverable
      ,CageScan
      ,BBForceToTScan
      ,DontSendToBB
      ,CanSelectInRunsheetScanning
      ,HeaderGroup
      ,CFBayScan
      ,ContainerScan
	  ,Active
      ,ForcedScanType
      ,ExcludeFromMFYBilling
      ,ImpactStatus
      ,Pickup
      ,PickupRF
      ,DeliveryRF
      ,Delivered
      ,PrePickup
      ,Problem
      ,AttemptedDelivery
      ,CollectionRequired
      ,Onforward
      ,Delayed
      ,ReadyToCollect

  FROM `{{ project_id }}.{{ dataset_id }}.dv_HUB_ScanStatus` hub
  JOIN `{{ project_id }}.{{ dataset_id }}.dv_SAT_ScanStatus` sat 
    ON sat.ScanStatus_HSK = hub.ScanStatus_HSK
  where sat.IsCurrent = 1