CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.sp_load_Staging_API_RF_AdHocLabel_AllocationHistory_Stg_Weekly`(
  LastID INT64
)
BEGIN
  DECLARE maxDate DATE;
  SET maxDate = DATE_ADD(DATE '1905-01-01', INTERVAL DATE_DIFF(CURRENT_DATE(), DATE '1905-01-01', WEEK) WEEK);

  --Get Previous Sunday or Today if day is SUN  - 19050101 was a SUN

  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_API_RF_AdHocLabel_AllocationHistory_Stg_Weekly`
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
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_API_RF_AdHocLabel_AllocationHistory` 
    WHERE HistoryID > LastID - 6000000
   AND DateAllocatedUTC <  maxDate
  ;

END;