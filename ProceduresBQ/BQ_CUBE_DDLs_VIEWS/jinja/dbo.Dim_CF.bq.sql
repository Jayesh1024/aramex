CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Dim_CF`
AS
SELECT        hub.RFCode, hub.CourierNumber, sat.Name, sat.ShortName, sat.CFName, sat.Address, sat.EmailAddress, sat.PhoneNumber, sat.MobileNumber, sat.BlackbayRouteId, sat.CourierGroup, sat.CFOwnershipModel, 
                         sat.Inactive, sat.ParcelConnectCFTerritory
FROM            `{{ project_id }}.{{ dataset_id }}.dv_HUB_CF` AS hub INNER JOIN
                         `{{ project_id }}.{{ dataset_id }}.dv_SAT_CF` AS sat ON sat.Courier_HSK = hub.Courier_HSK
WHERE        (sat.IsCurrent = 1)