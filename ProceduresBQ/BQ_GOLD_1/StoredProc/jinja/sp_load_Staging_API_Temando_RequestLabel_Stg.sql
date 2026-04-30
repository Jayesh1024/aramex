CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_API_Temando_RequestLabel_Stg`(
  LastID INT64
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_API_Temando_RequestLabel_Stg`
  SELECT
      globalRequestID,  createDateLocal, createDateUTC, requestID, readyDate,
      originCountry, originContactName, originCompany, originStreet, originSuburb, originState, originPostcode, originPhone1, originPhone2, originFax, originEmail, originRF,
      destinationContactName, destinationCompany, destinationStreet, destinationSuburb, destinationState, destinationPostcode, destinationFax, destinationEmail, destinationRF,
      specialInstructions, parcelWeight, parcelLength, parcelWidth, parcelHeight, parcelDescriptioN, Label_Colour, Label_Type, result_LabelNumber, CAST(result_Cost AS NUMERIC) AS result_Cost
  FROM `{{ project_id }}.{{ source_dataset_id }}.OnlineEnquiries_NEW_dbo_API_Temando_RequestLabel`
  WHERE globalRequestID > LastID
  ;

END;