CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.sp_load_Staging_Courier_Stg`(
)
BEGIN
  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Courier_Stg`
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
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_FMS_Courier` c
           left join `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_FMS_LookUpTableDetail` g ON c.RFCode = g.RFCode AND UPPER(HeaderCode) = 'GRP' AND c.CourierGroup = g.ItemCode
           left join `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_FMS_LookUpTableDetail` w ON UPPER(w.HeaderCode) = 'OWN' AND w.ItemCode = c.CFOwnershipModel AND c.NMid = w.NMid
  WHERE Inactive = FALSE;

END;
