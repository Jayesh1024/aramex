CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_ConsignmentItem_Stg`(
  startDate DATETIME
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_ConsignmentItem_Stg`
  SELECT 
         cl.LabelNumber,
         cl.CountryId,
         cm.WebCustomerId,
         c.CustomerId,
         c.ReceiverCompanyName,
         c.ReceiverContactName,
         c.ReceiverAddress1,
         c.ReceiverAddress2,
         c.ReceiverSuburb,
         c.ReceiverCity,
         c.ReceiverPostcode,
         c.ReceiverPhone,
         c.ReceiverEmail,
         CAST(cl.PrintedOn AS DATETIME) AS PrintedOn,
         ci.Reference,
         c.SpecialInstructions,
         c.DestinationRF,
         c.ManifestId,
         CAST(c.Price AS NUMERIC) AS Price,
         CAST(cl.InvoiceNo AS STRING) AS InvoiceNo,
         c.ItemCount,
         cl.CreatedOn,
         CAST(ci.WeightDead AS NUMERIC) AS WeightDead,
         CAST(ci.WeightCubic AS NUMERIC) AS WeightCubic,
         CAST(ci.Length AS NUMERIC) AS Length,
         CAST(ci.Width AS NUMERIC) AS Width,
         CAST(ci.Height AS NUMERIC) AS Height,
         cl.Colour,
         cl.ConsignmentItemId
  FROM `{{ project_id }}.{{ source_dataset_id }}.FastLabelServer_dbo_Consignment` c 
  JOIN `{{ project_id }}.{{ source_dataset_id }}.FastLabelServer_dbo_ConsignmentItem` ci on c.CountryId = ci.CountryId and c.CustomerId = ci.CustomerId and c.Id = ci.ConsignmentId
  JOIN `{{ project_id }}.{{ source_dataset_id }}.FastLabelServer_dbo_ConsignmentLabel` cl on ci.CountryId = cl.CountryId and ci.CustomerId = cl.CustomerId and ci.Id = cl.ConsignmentItemId
  LEFT JOIN `{{ project_id }}.{{ source_dataset_id }}.FastLabelServer_dbo_CustomerMap` cm on c.CountryId = cm.CountryId and c.CustomerId = cm.CustomerId 
  WHERE cl.CreatedOn >startDate
  ;

END;