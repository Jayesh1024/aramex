CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.sp_load_Staging_Product_Stg`(
)
BEGIN
  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Product_Stg`
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
  
  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_prods` p 
  LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_Country` c ON c.Code = p.CountryCode
  ;

END;