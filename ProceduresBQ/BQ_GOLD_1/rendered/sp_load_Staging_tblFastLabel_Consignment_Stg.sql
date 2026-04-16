CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.sp_load_Staging_tblFastLabel_Consignment_Stg`(
  startDate DATETIME
)
BEGIN
  SET startDate = DATE_SUB(startDate, INTERVAL 1 DAY);
  --SET startDate = '2022-06-01T00:00:00'

  INSERT INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_tblFastLabel_Consignment_Stg`
  SELECT 
  	d.LabelNumber,
  	d.CreateDate,
  	d.CountryCode,
  	d.ClientID,
  	d.CustomerID,
  	d.LabelPrinted,
  	d.ConsumedByCustomerUserID, 
  	d.LblColour, 
  	d.LblPrice, 
  	d.LblPrice1,
  	i.Reference, 
  	i.Packaging, 
  	i.Weight, 
  	i.WeightCubic, 
  	i.Length, 
  	i.Width, 
  	i.Height, 
  	b.ManifestID, 
  	b.Address1,
  	b.Address2,
  	b.Town, 
  	b.PostCode, 
  	b.State, 
  	b.destRF,
  	d.BookID,
                    d.DateConsumed,
                    i.ConsignmentID
  FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_tblFastLabel_Book_Detail` d
  LEFT JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_tblFastLabel_Consignment_Items` i on d.AppliedToItemID = i.ItemID
  LEFT JOIN `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_tblFastLabel_Consignment` b on i.ConsignmentID = b.ConsignmentID
  WHERE d.CreateDate > startDate OR d.DateConsumed > startDate
  ;

END;