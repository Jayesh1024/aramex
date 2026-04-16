CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.sp_load_Staging_API_Temando_RequestLabel_Stg`(
  LastID INT64
)
BEGIN
  INSERT INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_API_Temando_RequestLabel_Stg`
  SELECT
      globalRequestID,  createDateLocal, createDateUTC, requestID, readyDate,
      originCountry, originContactName, originCompany, originStreet, originSuburb, originState, originPostcode, originPhone1, originPhone2, originFax, originEmail, originRF,
      destinationContactName, destinationCompany, destinationStreet, destinationSuburb, destinationState, destinationPostcode, destinationFax, destinationEmail, destinationRF,
      specialInstructions, parcelWeight, parcelLength, parcelWidth, parcelHeight, parcelDescriptioN, Label_Colour, Label_Type, result_LabelNumber, CAST(result_Cost AS NUMERIC) AS result_Cost
  FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_API_Temando_RequestLabel`
  WHERE globalRequestID > LastID
  ;

END;