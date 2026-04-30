CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_Product_Stg`(
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_Product_Stg`
  SELECT 
  	CountryCode, 
  	REPLACE(IFNULL(c.Country, CAST(p.CountryCode AS STRING)), '  ', '') AS Country2, 
  	ProductId, 
  	p.Code, 
  	Description, 
  	Price, 
  	QtyOnHand, 
  	QtyCommitted, 
  	ItemType, 
  	LabelPrefix, 
  	BooksPerPackOrCarton, 
  	LabelsPerBook, 
  	FMSBookPrice, 
  	FMSDeliveryPrice, 
  	FMSPickupPrice, 
  	FMSCommission, 
  	CAST(IncludesGST AS INT64) AS IncludesGST, 
  	FMSSalesType, 
  	MinimumStockLevel, 
  	QTYOnBackOrder, 
  	LastLandedUnitCost, 
  	PackPrice, 
  	PacksInOpenCartons, 
  	CAST(DormantItem AS INT64) AS DormantItem, 
  	ProductCategory, 
  	DestinationLabelCost, 
  	DestinationLabelCostA, 
  	DestinationLabelCostB, 
  	DestinationLabelCostc, 
  	DeliveryNumberofDays, 
  	OldProductCode, 
  	CAST(NotSoldByFSO AS INT64) AS NotSoldByFSO, 
  	MYOBAccountNo, 
  	UsualSupplierId, 
  	NMOrderingComments, 
  	SuppliersCode, 
  	SuppliersDescription, 
  	SupplierPrice, 
  	CAST(InterRFProduct AS INT64) AS InterRFProduct, 
  	EnterpriseFastLabelColor, 
  	CAST(Supplementary AS INT64) AS Supplementary, 
  	CAST(AramexProduct AS INT64) AS AramexProduct, 
  	FSOONFCharge,
                    SAPGroup,
                    SAPProductGroup,
                    SAPSubProduct
  
  FROM `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_prods` p 
  LEFT JOIN `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_Country` c ON c.Code = p.CountryCode
  ;

END;