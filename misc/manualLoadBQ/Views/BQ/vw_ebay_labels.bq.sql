CREATE OR REPLACE VIEW `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_vw_ebay_labels` AS
SELECT  
    c.ID, c.AccountId, c.EbayUserID, c.CreatedDateUTC, c.EmailAddress, 
    c.FirstName, c.LastName, c.B_CompanyName, c.B_Address1, c.B_Address2,
    c.B_Town, c.B_Postcode, c.B_CountryCode, c.B_RF, c.B_TownNPostcode,
    c.C_CompanyName, c.C_Address1, c.C_Address2, c.C_Town, c.C_Postcode, 
    c.C_CountryCode, c.C_RF, c.C_TownNPostcode, c.Phoneno_Mobile, c.Phoneno, 
    c.GST_Number, c.SP_Instruction1, c.SP_Instruction2, c.SP_Instruction3, c.Status, 
    c.PickupCSAID, c.PickupCourierID, c.PrintDateUTC, c.OrderClosedDateUTC, c.Do_NeedPickup, 
    c.NoOfItems, c.P_Date, c.P_Time, c.TotalLabelCost, c.TotalReplacementPckCost,
    c.GSTRate, ci.OrderID, ci.LineItemID, ci.Title, ci.SKU,
    ci.EbayCreateDate, ci.TotalValue, ci.DeliveryCompanyName, ci.DeliveryName, 
    ci.DeliveryPhone, ci.DeliveryStreet, ci.DeliveryCity, ci.DeliveryPostcode,
    ci.DeliveryCountry, ci.IsValidAddress, ci.LabelCost, ci.IsDeeded, 
    ci.IsSignatureRequired, ci.ItemType, ci.DeliveryRF, ci.DeliveryStreet1,
    ci.DeliveryPhone1, ci.DeliveryEmail, ci.SP_Instruction1 AS Delivery_SP1, 
    ci.SP_Instruction2 AS Delivery_SP2, ci.SP_Instruction3 AS Delivery_SP3, ci.GalleryURL,
    ci.EbayViewURL, ci.OrderClosedDateUTC AS ItemOrderClosedDateUTC, ci.PrintDateUTC AS ItemPrintDateUTC,
    ci.NoOfPrints, cil.EbayConsignmentItemID, cil.LabelCost AS ItemLabelCost,
    cil.LabelNumber, cil.PackageType, cil.Prefix, cil.LabelColour,
    cil.Status AS ItemLabelStatus, c.AdminStatus, ci.AdminStatus AS ItemAdminStatus, 
    cil.AdminStatus AS ItemLabelAdminStatus, cil.ID AS ItemLabelID,
    cil.CreatedDateUTC AS ItemLabelCreateDateUTC, c.CreateDateLocal
FROM            
    `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_tblEbay_Consignments` c
INNER JOIN
    `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_tblEbay_Consignments_Items` ci ON c.ID = ci.EbayConsignmentID
INNER JOIN
    `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_tblEbay_Consignments_Items_Labels` cil ON ci.ID = cil.EbayConsignmentItemID