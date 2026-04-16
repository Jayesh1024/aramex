CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_ScanStatus_Stg`(
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_ScanStatus_Stg`
  SELECT 
  	CountryCode, 
  	IFNULL(ct.Country,'Unknown') as CountryName, 
  	st.Code as StatusCode, 
  	Description, 
  	ExtendedDescription, 
  	CAST(ShowToCustomer AS INT64) AS ShowToCustomer, 
  	CAST(Misdirected AS INT64) AS Misdirected, 
  	CAST(LeftByCF AS INT64) AS LeftByCF, 
  	CAST(Undeliverable AS INT64) AS Undeliverable, 
  	CAST(CageScan AS INT64) AS CageScan, 
  	CAST(BBForceToTScan AS INT64) AS BBForceToTScan, 
  	CAST(DontSendToBB AS INT64) AS DontSendToBB, 
  	CAST(CanSelectInRunsheetScanning AS INT64) AS CanSelectInRunsheetScanning, 
  	HeaderGroup, 
  	CAST(CFBayScan AS INT64) AS CFBayScan, 
  	CAST(ContainerScan AS INT64) AS ContainerScan,
  	CAST(Active AS INT64) AS Active,
                    ForcedScanType,
                    CAST(ExcludeFromMFYBilling AS INT64) AS ExcludeFromMFYBilling,
                    CAST(ImpactStatus AS INT64) AS ImpactStatus,
                    CAST(Pickup AS INT64) AS Pickup,
                    CAST(PickupRF AS INT64) AS PickupRF,
                    CAST(DeliveryRF AS INT64) AS DeliveryRF,
                    CAST(Delivered AS INT64) AS Delivered,
                    CAST(PrePickup AS INT64) AS PrePickup,
                    CAST(Problem AS INT64) AS Problem,
                    CAST(AttemptedDelivery AS INT64) AS AttemptedDelivery,
                    CAST(CollectionRequired AS INT64) AS CollectionRequired,
                    CAST(Onforward AS INT64) AS Onforward,
                    CAST(Delayed AS INT64) AS Delayed,
                    CAST(ReadyToCollect AS INT64) AS ReadyToCollect
  FROM `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_status` st 
  LEFT JOIN `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_Country` ct ON ct.Code = st.CountryCode
  ;

END;