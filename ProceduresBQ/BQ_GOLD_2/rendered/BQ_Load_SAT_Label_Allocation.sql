-- ==========================================================================================
-- Routine:		Load_SAT_Label_Allocation
-- Description: Loads attributes into SAT_Label from Staging_SAT_Label_Allocation_Stg
-- Example:		Exec [dv].[Load_SAT_Label_Allocation] 649
-- History:
--	20/11/2018  P. Waldron		Routine Written
--  27/06/2019  P. Waldron      Refactor to use SAT_Label_Allocation instead of SAT_Label
--  09/07/2019  P. Waldron      Add Pickup/Delivery postcode and suburb
--  29/07/2019  P. Waldron      Refactor to use SAT_Label_Allocation_Stg
--  07/08/2019  P. Waldron      DynamicLabel data trumps all other sources
--  05/11/2019  P. Waldron      Refactor table columns when adding RP,TAS,TMD,EBAY
--  17/08/2020  P. Waldron      Refactor MERGE to UPDATE then INSERT - to avoid CCI slowdown
--  10/09/2020  P. Waldron		Add PickupCF and DeliveryCF columns 
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dv_Load_SAT_Label_Allocation`(IN p_ProcessID INT64)
BEGIN
  /*
  ** Routine: Load_SAT_Label_Allocation
  ** Description: Loads attributes into SAT_Label from Staging_SAT_Label_Allocation_Stg
  */

  DECLARE v_DefaultValidFrom DATETIME DEFAULT '1900-01-01 00:00:00';
  DECLARE v_DefaultValidTo DATETIME DEFAULT '9999-12-31 23:59:59';
  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();

  DECLARE v_Component STRING DEFAULT 'dv_Load_SAT_Label_Allocation';
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING;
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_Inserted INT64 DEFAULT 0;
  DECLARE v_Updated INT64 DEFAULT 0;

  BEGIN
    -- Use MERGE to handle both expiring old records and inserting new records in a single scan.
    -- v_Updated will contain the total count of rows affected (both expired and inserted).
    -- v_Inserted remains 0 as per CORE RULES for MERGE operations.
    
    MERGE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation` AS Tgt
    USING (
      WITH DeduplicatedStg AS (
        -- Deduplicate staging data as per original Row_Number logic
        SELECT 
          Stg.LabelNo,
          Stg.CountryCode,
          IFNULL(cty.CountryName, 'Unknown') AS Country,
          Stg.PickupRF,
          Stg.PickupCF,
          Stg.DeliveryRF,
          Stg.DeliveryCF,
          Stg.LabelColour,
          Stg.CreateDateUTC,
          Stg.CreateDateLocal,
          Stg.OESCustomerID,
          Stg.FMSCustomerID,
          Stg.IFSCustomerCode,
          Stg.DLSInvoiceID,
          Stg.FMSInvoiceID,
          Stg.FMSProductID,
          Stg.FKSource,
          Stg.FKID,
          Stg.Reference,
          Stg.NumberOfParcels,
          Stg.Price,
          Stg.ParcelLength,
          Stg.ParcelWidth,
          Stg.ParcelHeight,
          Stg.ParcelWeight, 
          Stg.ParcelCubicWeight,
          Stg.RecordSource,
          Stg.RecordSourceId,
          Stg.Action,
          `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(CAST(Stg.LabelNo AS STRING), '^') AS LabelNo_HSK,
          ROW_NUMBER() OVER (PARTITION BY Stg.LabelNo ORDER BY Stg.CountryCode) AS RowNum
        FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_SAT_Label_Allocation_Stg` AS Stg
        LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Country` AS cty ON cty.CountryCode = Stg.CountryCode
      )
      -- Combine 'EXPIRE' actions and 'INSERT' actions into a single source stream
      SELECT *, 'INSERT' AS MergeAction FROM DeduplicatedStg WHERE RowNum = 1
      UNION ALL
      SELECT *, 'EXPIRE' AS MergeAction FROM DeduplicatedStg WHERE RowNum = 1 AND Action = 'Update'
    ) AS Src
    ON Tgt.LabelNo = Src.LabelNo 
       AND Tgt.IsCurrent = 1 
       AND Src.MergeAction = 'EXPIRE'
    WHEN MATCHED THEN
      UPDATE SET 
        IsCurrent = 0,
        ValidTo = v_Loaded
    WHEN NOT MATCHED BY TARGET AND Src.MergeAction = 'INSERT' THEN
      INSERT (
        LabelNo_HSK,
        LabelNo,
        CountryCode,
        Country,
        PickupRF,
        PickupCF,
        DeliveryRF,
        DeliveryCF,
        LabelColour,
        CreateDateUTC,
        CreateDateLocal,
        OESCustomerID,
        FMSCustomerID,
        IFSCustomerCode,
        DLSInvoiceID,
        FMSInvoiceID,
        FMSProductID,
        FKSource,
        FKID,
        Reference,
        NumberOfParcels,
        Price,
        ParcelLength,
        ParcelWidth,
        ParcelHeight,
        ParcelWeight, 
        ParcelCubicWeight,
        Loaded,
        ProcessId,
        RecordSource,
        RecordSourceId,
        ValidFrom,
        ValidTo,
        IsCurrent
      )
      VALUES (
        Src.LabelNo_HSK,
        Src.LabelNo,
        Src.CountryCode,
        Src.Country,
        Src.PickupRF,
        Src.PickupCF,
        Src.DeliveryRF,
        Src.DeliveryCF,
        Src.LabelColour,
        Src.CreateDateUTC,
        Src.CreateDateLocal,
        Src.OESCustomerID,
        Src.FMSCustomerID,
        Src.IFSCustomerCode,
        Src.DLSInvoiceID,
        Src.FMSInvoiceID,
        Src.FMSProductID,
        Src.FKSource,
        Src.FKID,
        Src.Reference,
        Src.NumberOfParcels,
        Src.Price,
        Src.ParcelLength,
        Src.ParcelWidth,
        Src.ParcelHeight,
        Src.ParcelWeight, 
        Src.ParcelCubicWeight,
        v_Loaded,
        p_ProcessId,
        Src.RecordSource,
        Src.RecordSourceId,
        v_Loaded,
        v_DefaultValidTo,
        1
      );

    SET v_Updated = @@row_count;
    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result = 'Failed';
    SET v_ErrorMessage = @@error.message;
  END;

  -- Log the procedure execution result
  SET v_Ended = CURRENT_DATETIME();
  CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_SaveLog`(
    v_Component,
    p_ProcessId,
    v_Started,
    v_Ended,
    v_Result,
    v_ErrorMessage,
    v_Inserted,
    v_Updated,
    -1
  );

END;