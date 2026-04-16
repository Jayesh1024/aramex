CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_API_RF_AdHocLabel_AllocationHistory_Stg`(
  LastID INT64
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_API_RF_AdHocLabel_AllocationHistory_Stg`
  SELECT
         HistoryID
        ,SystemID
        ,LabelColour
        ,LabelNumber
        ,CountryCode
        ,Franchise
        ,CAST(PriceSoldAtExGST AS NUMERIC) AS PriceSoldAtExGST
        ,DateAllocatedUTC
        ,ExternalReference
        ,CustomerID
        ,FKID
        ,FKSource
        ,FMSInvoiceID
        ,FMSProductID
        ,CAST(AllocatedByCustomer AS INT64) AS AllocatedByCustomer
        ,CustomerUniqueID
        ,PickupTown
        ,PickupPostcode
        ,DeliveryTown
        ,DeliveryPostcode
        ,CAST(Weight AS NUMERIC) AS Weight
        ,DateAllocatedRelativeToRF
        ,CAST(DeletedLabel AS INT64) AS DeletedLabel
        ,DeliveryAddr1
        ,DeliveryAddr2
        ,PickupAddr1
        ,PickupAddr2
        ,GroupTransId
        ,DeliveryPhoneNo
        ,LengthInCm
        ,WidthInCm
        ,HeightInCm
        ,CAST(CubicWeight AS NUMERIC) AS CubicWeight
  FROM `{{ project_id }}.{{ source_dataset_id }}.OnlineEnquiries_NEW_dbo_API_RF_AdHocLabel_AllocationHistory`
  WHERE HistoryID > LastID
  ;

END;