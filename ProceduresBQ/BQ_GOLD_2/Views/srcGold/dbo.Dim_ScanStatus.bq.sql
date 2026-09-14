CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_ScanStatus` AS 
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

  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_ScanStatus` hub
  JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_ScanStatus` sat 
    ON sat.ScanStatus_HSK = hub.ScanStatus_HSK
  where sat.IsCurrent = 1