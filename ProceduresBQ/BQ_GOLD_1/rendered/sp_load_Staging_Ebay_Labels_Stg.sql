CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.sp_load_Staging_Ebay_Labels_Stg`(
  startID INT64
)
BEGIN
  INSERT INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_Ebay_Labels_Stg`
  SELECT 
  	ID, 
  	LabelNumber, 
  	LabelColour, 
  	AccountId, 
  	EbayUserID, 
  	CreatedDateUTC, 
  	FirstName, LastName, B_CompanyName, Phoneno, EmailAddress, 
  	B_Address1, B_Address2, B_Town, B_Postcode, B_CountryCode, B_RF, 
  	C_CompanyName, C_Address1, C_Address2, C_Town, C_Postcode, C_CountryCode, C_RF, Phoneno_Mobile, 
  	SP_Instruction1, SP_Instruction2, SP_Instruction3, Status, 
  	OrderClosedDateUTC, NoOfItems, P_Date, EbayCreateDate, IsDeeded, IsSignatureRequired, ItemType,
  	DeliveryCompanyName, DeliveryName, 
  	DeliveryPhone, DeliveryPhone1, 
  	DeliveryStreet, DeliveryStreet1, 
  	DeliveryCity, DeliveryPostcode, DeliveryCountry, 
  	DeliveryRF, DeliveryEmail, 
  	Delivery_SP1, Delivery_SP2, Delivery_SP3,
  	LabelCost, ItemLabelCost, TotalLabelCost, TotalReplacementPckCost, GST_Number, TotalValue
  FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_vw_ebay_labels`
  --WHERE ID > startID
  ;

END;