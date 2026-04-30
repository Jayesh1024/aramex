CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Customer`
AS
SELECT        hub.CustomerKey, sat.RFCode, sat.CourierNumber, sat.FMSCustomerId, sat.CustomerNumber, sat.Active, sat.DeactiveDescription, sat.CustomerName, sat.TradingName, sat.StreetAddress1, sat.StreetAddress2, 
                         sat.StreetAddress3, sat.PostalAddress1, sat.PostalAddress2, sat.PostalAddress3, sat.PostCodeStreet, sat.PostCodePostal, sat.LastPurchDate, sat.StartDate, sat.B2B, sat.B2C, sat.ParentId, sat.TaxNumber, 
                         sat.IndustryClassifcation, sat.IndustryDescription, sat.IndustryClassifcationOtherDes, sat.XLabelCustomer AS MFWCustomer, sat.PriceListCode, rf.CountryCode, sat.xLabelAlcoholDeliveries
FROM            `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_Customer` AS hub INNER JOIN
                         `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Customer` AS sat ON sat.Customer_HSK = hub.Customer_HSK LEFT OUTER JOIN
                         `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_RF` AS rf ON sat.RFCode = rf.FranchiseeCode AND rf.IsCurrent = 1
WHERE        (sat.IsCurrent = 1)