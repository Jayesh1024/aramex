CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Dim_Label_Address_By_LabelNo`
AS
SELECT        a.LabelNo, p.AddressKey AS PickupAddress, p.AddressLine1 AS PickupAddress1, p.AddressLine2 AS PickupAddress2, p.Town AS PickupTown, p.Postcode AS PickupPostcode, d.AddressKey AS DeliveryAddress, 
                         d.AddressLine1 AS DelAddress1, d.AddressLine2 AS DelAddress2, d.Town AS DelTown, d.Postcode AS DelPostcode
FROM            `{{ project_id }}.{{ dataset_id }}.dv_LNK_Label_Address` AS a LEFT OUTER JOIN
                         `{{ project_id }}.{{ dataset_id }}.dv_SAT_Address` AS d ON a.Delivery_Address_HSK = d.Address_HSK AND d.IsCurrent = 1 LEFT OUTER JOIN
                         `{{ project_id }}.{{ dataset_id }}.dv_SAT_Address` AS p ON a.Pickup_Address_HSK = p.Address_HSK AND p.IsCurrent = 1