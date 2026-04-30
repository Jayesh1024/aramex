CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.sp_load_Staging_CustomerLinks_Stg`(
)
BEGIN
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_CustomerLinks_Stg`
  SELECT 
                            Concat(RFId, LPAD(CAST(CourierNumber AS STRING), 3, '0'), LPAD(CAST(CustomerNumber AS STRING), 4, '0')) as CustomerKey, 
                            TRIM(fms.BusinessName) as CustomerName,
                            fms.NMId as CountryCode, 
                            fms.RFId as RFCode,
                            fms.CustomerId as FMSCustomerID, 
                            lnk.OESCustomerID, 
                            lnk.IFSCustomerCode,
                            lnk.IFSCustomerType  
                        FROM `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_FMS_Customer` fms
                        LEFT JOIN (
                            Select  
                                coalesce(oes.CountryCode,ifs.CountryCode) as CountryCode, 
                                coalesce(oes.CustomerID, ifs.FMSCustomerId) as FMSCustomerID, 
                                CAST(OESCustomerID AS INT64) AS OESCustomerID, 
                                IFSCustomerCode,
                                CustomerType as IFSCustomerType
                            From `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_DLS_CustomerLinks` oes
                            Full Join `{{ project_id }}.{{ source_dataset_id }}.Fastway_dbo_IFSCustomers` ifs on oes.CustomerID = ifs.FMSCustomerId and oes.CountryCode = ifs.CountryCode and ifs.RFCode = oes.Franchise
                        ) lnk ON fms.CustomerId = lnk.FMSCustomerID and fms.NMId = lnk.CountryCode
                        WHERE fms.NMId in (1,6,11,24)
                        ORDER BY 1
  ;

END;