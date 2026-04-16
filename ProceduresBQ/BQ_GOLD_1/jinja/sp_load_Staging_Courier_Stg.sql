CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_Courier_Stg`(
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_Courier_Stg`
  SELECT
      c.RFCode,
      CourierNumber,
      Name,
      ShortName,
      CFName,
      Address1,
      Address2,
      Address3,
      Address4,
      EmailAddress,
      PhoneNumber,
      Mobile,
      CAST(BlackbayRouteId AS INT64) AS BlackbayRouteId,
      g.Description as CourierGroup,
      w.Description AS CFOwnershipModel,
      CAST(c.Inactive AS INT64) AS Inactive,
      ParcelConnectCFTerritory
  FROM `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_FMS_Courier` c
           left join `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_FMS_LookUpTableDetail` g ON c.RFCode = g.RFCode AND HeaderCode = 'GRP' AND c.CourierGroup = g.ItemCode
           left join `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_FMS_LookUpTableDetail` w ON w.HeaderCode = 'OWN' AND w.ItemCode = c.CFOwnershipModel AND c.NMid = w.NMid
  WHERE Inactive = FALSE
  ;

END;
