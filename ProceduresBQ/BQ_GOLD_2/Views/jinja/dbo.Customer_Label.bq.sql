CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Customer_Label`
AS
SELECT DISTINCT 
                         l.LabelNo, l.CountryCode, l.Country, l.PickupTown, l.PickupPostcode, l.DeliveryTown, l.DeliveryPostcode, l.PickupRF, l.DeliveryRF, l.Electronic_CustomerType, l.Electronic_CustomerID, l.Electronic_Reference, 
                         l.FastLabel_ConsignmentID, l.FastLabel_DestinationRF, l.Distribution_Date, l.Distribution_FranchiseeCode, l.FKSource, l.OESCustomerID, l.FMSCustomerID, l.FMSInvoiceID, l.FMSProductID, l.FMSRfID, l.LabelColour, 
                         l.Reference, l.NumberOfParcels, l.Price, l.CreateDate, l.ParcelLength, l.ParcelWidth, l.ParcelHeight, l.ParcelWeight, l.ParcelCubicWeight, c.CustomerKey
FROM            `{{ project_id }}.{{ dataset_id }}.dbo_Dim_Label` AS l INNER JOIN
                         `{{ project_id }}.{{ dataset_id }}.dv_SAL_Customer` AS c ON c.CustomerType = 'FMS' AND c.CustomerID = CAST(l.FMSCustomerID AS STRING) AND l.Country = c.CountryName OR
                         c.CustomerType = 'IFS' AND c.CustomerID = CAST(l.Electronic_CustomerID AS STRING) AND l.Country = c.CountryName OR
                         c.CustomerType = 'OES' AND c.CustomerID = CAST(l.OESCustomerID AS STRING) AND l.Country = c.CountryName AND c.CustomerID <> '0'