-- ==========================================================================================
-- Routine:		Load_SAL_Customer 
-- Description: Loads related business keys into SAL_Customer
-- Example:		Exec [DV].[Load_SAL_Customer] 123
-- History:
--	27/11/2019  P. Waldron		Routine Written
--  13/02/2020  P. Waldron      Add [IFSCustomerType] column to [SAL_Customer] table
--  12/03/2021  B. Woods		Fixed bug causing duplicate rows to be loaded  (ticket BI-70)
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_SAL_Customer`(IN p_ProcessID INT64, IN p_RecordSource STRING)
BEGIN
  /*
  ** Routine: Load_SAL_Customer 
  ** Description: Loads related business keys into SAL_Customer
  */

  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Component STRING DEFAULT 'dv_Load_SAL_Customer';
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING;
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_Inserted INT64 DEFAULT 0;
  DECLARE v_Updated INT64 DEFAULT 0;
  BEGIN
    -- Only INSERT is present in the source logic, so using INSERT ... SELECT per CORE RULES.
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAL_Customer` (
      Customer_HSK,
      CustomerKey,
      RFCode,
      CustomerType,
      IFSCustomerType,
      CustomerId,
      CountryName,
      Loaded,
      ProcessID,
      RecordSource,
      RecordSourceId
    )
    WITH NewBusinessKeys AS (
      SELECT DISTINCT 
        CustomerKey, 
        CustomerId, 
        CustomerType,  
        IF(CustomerType = 'IFS', IFSCustomerType, NULL) AS IFSCustomerType, 
        CountryName, 
        RFCode, 
        Customer_HSK
      FROM (
        SELECT 
          Stg.*, 
          Cty.CountryName, 
          (`prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(CAST(CustomerKey AS STRING), '^')) AS Customer_HSK
        FROM (
          SELECT CustomerKey, CountryCode, CAST(FMSCustomerID AS STRING) AS CustomerId, 'FMS' AS CustomerType, IFSCustomerType, RFCode FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CustomerLinks_Stg` WHERE FMSCustomerID IS NOT NULL 
          UNION DISTINCT
          SELECT CustomerKey, CountryCode, CAST(OESCustomerID AS STRING) AS CustomerId, 'OES' AS CustomerType, IFSCustomerType, RFCode FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CustomerLinks_Stg` WHERE OESCustomerID IS NOT NULL 
          UNION DISTINCT
          SELECT CustomerKey, CountryCode, IFSCustomerCode AS CustomerId, 'IFS' AS CustomerType, IFSCustomerType, RFCode FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CustomerLinks_Stg` WHERE IFSCustomerCode IS NOT NULL AND IFSCustomerCode <> ''
        ) AS Stg
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Country` AS Cty ON Cty.CountryCode = Stg.CountryCode
      ) AS Src
      WHERE NOT EXISTS ( 
        SELECT 1 FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAL_Customer` AS Hub 
        WHERE Src.CustomerKey = Hub.CustomerKey
          AND Src.CustomerType = Hub.CustomerType
          AND (Src.CustomerType IN ('FMS', 'OES') OR (Src.IFSCustomerType = Hub.IFSCustomerType))
          AND Src.CustomerId = Hub.CustomerID 
          AND Src.CountryName = Hub.CountryName
          AND Src.RFCode = Hub.RFCode
      ) 
    )
    SELECT
      (`prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(CAST(CustomerKey AS STRING), '^')) AS CustomerKey_HSK,
      RTRIM(CustomerKey) AS CustomerKey,
      RFCode,
      CustomerType,
      IFSCustomerType,
      CustomerId,
      CountryName,
      v_Loaded AS Loaded,
      p_ProcessID AS ProcessID,
      p_RecordSource AS RecordSource,
      NULL AS RecordSourceId
    FROM NewBusinessKeys
    ORDER BY CustomerKey;

    SET v_Inserted = @@row_count;
    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result = 'Failed';
    SET v_ErrorMessage = @@error.message;
  END;

  -- Record load metrics in log
  SET v_Ended = CURRENT_DATETIME();
  CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
    v_Component,
    p_ProcessID,
    v_Started,
    v_Ended,
    v_Result,
    v_ErrorMessage,
    v_Inserted,
    v_Updated,
    -1
  );

END;