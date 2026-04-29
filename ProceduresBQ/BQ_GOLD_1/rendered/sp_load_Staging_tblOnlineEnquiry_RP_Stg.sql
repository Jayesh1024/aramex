CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.sp_load_Staging_tblOnlineEnquiry_RP_Stg`(
  startID INT64
)
BEGIN
  SET startID = 1235690;

  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_tblOnlineEnquiry_RP_Stg`
  SELECT rp.RPID, CreateDateUTC, CountryID, DescriptionOfGoods, PickupFranchiseeCode, DeliveryFranchiseeCode, PickupCourierNumber, DeliveryCourierNumber, 
  NumberOfParcels, Sender_Name, Sender_StreetAddress, Sender_StreetAddress1, Sender_Suburb, Sender_Postcode, Sender_City, Sender_ContactName, Sender_ContactPhone,
  Sender_MobileNumber, Sender_FaxNumber, Sender_EmailAddress, Sender_LocalRF, Receiver_Name, Receiver_StreetAddress, Receiver_StreetAddress1, Receiver_Suburb, Receiver_Postcode, Receiver_City,
  Receiver_ContactName, Receiver_ContactPhone, Receiver_MobileNumber, Receiver_FaxNumber, Receiver_EmailAddress, Receiver_LocalRF,
  Customer_Name, CAST(IsThirdParty AS INT64) AS IsThirdParty, CustomerID, CloseDateUTC, CancellationDateUTC, PickupDateLocal, PaymentDateUTC, label_colour, label_number, label_cost, receiverpays_label_cost, parcel_weight, parcel_height, parcel_width, parcel_length
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_tblOnlineEnquiry_RP` rp
  JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_tblOnlineEnquiry_RP_Parcels` par ON rp.RPID = par.rpid
  WHERE rp.RPID > startID
  ;

END;