-- ==========================================================================================
-- Routine:     Load_SAT_Label_Allocation_DL (refactored Load_SAT_Label_Allocation)
-- Description: Loads attributes into dv.SAT_Label_Allocation_DL from Staging.SAT_Label_Allocation_Stg
-- Example:     Exec [dv].[Load_SAT_Label_Allocation_DL] 653, 'DynamicLabel'
-- History:
--  31/10/2019  P. Waldron      Routine Written
--  07/11/2019  P. Waldron      Remove CountryName from Label_HSK 
--  12/01/2024  B. Woods        Replaced MERGE with DELETE and INSERT
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `dv.Load_SAT_Label_Allocation_DL`(IN p_ProcessID INT64, IN p_RecordSource STRING)
BEGIN
  /*
  ** Routine: Load_SAT_Label_Allocation_DL
  ** Description: Loads attributes into dv.SAT_Label_Allocation_DL from Staging.SAT_Label_Allocation_Stg
  */

  DECLARE v_DefaultValidFrom DATETIME DEFAULT '1900-01-01 00:00:00';
  DECLARE v_DefaultValidTo DATETIME DEFAULT '9999-12-31 23:59:59';
  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();

  DECLARE v_Component STRING DEFAULT 'dv.Load_SAT_Label_Allocation_DL';
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING;
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_Inserted INT64 DEFAULT 0;
  DECLARE v_Updated INT64 DEFAULT 0;

  BEGIN
    -- Use MERGE to handle the DELETE + INSERT pattern (Replace Current) in a single scan.
    -- v_Updated will contain the total rows affected. v_Inserted = 0 per CORE RULES.
    
    MERGE `dv.SAT_Label_Allocation_DL` AS Tgt
    USING (
      SELECT DISTINCT 
        TO_HEX(SHA256(CAST(Stg.LabelNumber AS STRING))) AS LabelNo_HSK,
        Stg.LabelNumber AS LabelNo,
        Stg.CountryCode,
        IFNULL(cty.CountryName, 'Unknown') AS Country,
        Stg.Franchise AS PickupRF,
        Stg.LabelColour,
        Stg.CustomerID AS OESCustomerID,
        Stg.FMSInvoiceID,
        Stg.FMSProductID,
        Stg.FKSource,
        Stg.FKID,
        Stg.DateAllocatedUTC AS CreateDateUTC,
        Stg.DateAllocatedRelativeToRF AS CreateDateLocal,
        Stg.PriceSoldAtExGST AS Price,
        Stg.ExternalReference AS Reference,
        Stg.LengthInCm AS ParcelLength,
        Stg.WidthInCm AS ParcelWidth,
        Stg.HeightInCm AS ParcelHeight,
        Stg.Weight AS ParcelWeight,
        Stg.CubicWeight AS ParcelCubicWeight,
        Stg.GroupTransId,
        Stg.HistoryId AS RecordSourceId
      FROM `Staging.API_RF_AdHocLabel_AllocationHistory_Stg` AS Stg  
      LEFT JOIN `dbo.Dim_Country` AS cty ON cty.CountryCode = Stg.CountryCode
    ) AS Src
    ON Tgt.LabelNo = Src.LabelNo AND Tgt.IsCurrent = 1
    WHEN MATCHED THEN
      UPDATE SET
        LabelNo_HSK = Src.LabelNo_HSK,
        CountryCode = Src.CountryCode,
        Country = Src.Country,
        PickupRF = Src.PickupRF,
        LabelColour = Src.LabelColour,
        Price = Src.Price,
        Reference = Src.Reference,
        CreateDateLocal = Src.CreateDateLocal,
        OESCustomerID = Src.OESCustomerID,
        FMSInvoiceID = Src.FMSInvoiceID,
        FMSProductID = Src.FMSProductID,
        FKSource = Src.FKSource,
        FKID = Src.FKID,
        ParcelLength = Src.ParcelLength,
        ParcelWidth = Src.ParcelWidth,
        ParcelHeight = Src.ParcelHeight,
        ParcelWeight = Src.ParcelWeight,
        ParcelCubicWeight = Src.ParcelCubicWeight,
        GroupTransId = Src.GroupTransId,
        Loaded = v_Loaded,
        ProcessId = p_ProcessID,
        RecordSource = p_RecordSource,
        RecordSourceId = Src.RecordSourceId,
        ValidFrom = v_Loaded,
        ValidTo = v_DefaultValidTo,
        IsCurrent = 1
    WHEN NOT MATCHED THEN
      INSERT (
        LabelNo_HSK, LabelNo, CountryCode, Country, PickupRF, 
        LabelColour, Price, Reference, CreateDateLocal, OESCustomerID, 
        FMSInvoiceID, FMSProductID, FKSource, FKID, ParcelLength, 
        ParcelWidth, ParcelHeight, ParcelWeight, ParcelCubicWeight, GroupTransId, 
        Loaded, ProcessId, RecordSource, RecordSourceId, ValidFrom, ValidTo, IsCurrent
      )
      VALUES (
        Src.LabelNo_HSK, Src.LabelNo, Src.CountryCode, Src.Country, Src.PickupRF, 
        Src.LabelColour, Src.Price, Src.Reference, Src.CreateDateLocal, Src.OESCustomerID, 
        Src.FMSInvoiceID, Src.FMSProductID, Src.FKSource, Src.FKID, Src.ParcelLength, 
        Src.ParcelWidth, Src.ParcelHeight, Src.ParcelWeight, Src.ParcelCubicWeight, Src.GroupTransId, 
        v_Loaded, p_ProcessID, p_RecordSource, Src.RecordSourceId, v_Loaded, v_DefaultValidTo, 1
      );

    SET v_Updated = @@row_count;
    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result = 'Failed';
    SET v_ErrorMessage = @@error.message;
  END;

  -- Record load metrics in log
  SET v_Ended = CURRENT_TIMESTAMP();
  CALL `Staging.SaveLog`(
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