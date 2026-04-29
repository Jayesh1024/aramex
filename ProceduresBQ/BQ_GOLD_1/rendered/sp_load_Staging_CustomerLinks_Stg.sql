CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.sp_load_Staging_CustomerLinks_Stg`(
)
BEGIN
  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_CustomerLinks_Stg`
  SELECT 
                            Concat(RFId, LPAD(CAST(CourierNumber AS STRING), 3, '0'), LPAD(CAST(CustomerNumber AS STRING), 4, '0')) as CustomerKey, 
                            TRIM(fms.BusinessName) as CustomerName,
                            fms.NMId as CountryCode, 
                            fms.RFId as RFCode,
                            fms.CustomerId as FMSCustomerID, 
                            lnk.OESCustomerID, 
                            lnk.IFSCustomerCode,
                            lnk.IFSCustomerType  
                        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_FMS_Customer` fms
                        LEFT JOIN (
                            Select  
                                coalesce(oes.CountryCode,ifs.CountryCode) as CountryCode, 
                                coalesce(oes.CustomerID, ifs.FMSCustomerId) as FMSCustomerID, 
                                CAST(OESCustomerID AS INT64) AS OESCustomerID, 
                                IFSCustomerCode,
                                CustomerType as IFSCustomerType
                            From `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_DLS_CustomerLinks` oes
                            Full Join `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_krillin_silver.Fastway_dbo_IFSCustomers` ifs on oes.CustomerID = ifs.FMSCustomerId and oes.CountryCode = ifs.CountryCode and ifs.RFCode = oes.Franchise
                        ) lnk ON fms.CustomerId = lnk.FMSCustomerID and fms.NMId = lnk.CountryCode
                        WHERE fms.NMId in (1,6,11,24)
                        ORDER BY 1
  ;

END;