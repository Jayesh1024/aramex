CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_CF`
AS
SELECT        hub.RFCode, hub.CourierNumber, sat.Name, sat.ShortName, sat.CFName, sat.Address, sat.EmailAddress, sat.PhoneNumber, sat.MobileNumber, sat.BlackbayRouteId, sat.CourierGroup, sat.CFOwnershipModel, 
                         sat.Inactive, sat.ParcelConnectCFTerritory
FROM            `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_CF` AS hub INNER JOIN
                         `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_CF` AS sat ON sat.Courier_HSK = hub.Courier_HSK
WHERE        (sat.IsCurrent = 1)