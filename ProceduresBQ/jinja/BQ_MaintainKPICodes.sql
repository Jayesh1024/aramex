-- ==========================================================================================
-- Routine:		MaintainKPICodes
-- Description: Load new RFs or CFs into [dbo].[KPICodes]
-- Example:		Exec [dbo].[MaintainKPICodes]  
-- History:
--	12/04/2019  P. Waldron		Routine Written
-- ==========================================================================================

CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dbo_MaintainKPICodes`()
BEGIN
  /*
  ** Routine: MaintainKPICodes
  ** Description: Load new RFs or CFs into dbo_KPICodes
  */

  DECLARE v_Component STRING DEFAULT 'dbo_MaintainKPICodes';
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Ended DATETIME;
  DECLARE v_Result STRING;
  DECLARE v_ErrorMessage STRING DEFAULT NULL;
  DECLARE v_Inserted INT64 DEFAULT 0;
  DECLARE v_Updated INT64 DEFAULT 0;
  DECLARE v_ProcessId INT64 DEFAULT 0;

  BEGIN
    -- Create temporary table to hold KPI codes for comparison
    CREATE TEMP TABLE KPICodes_Temp (
      KPIGroup STRING,
      ScanType STRING,
      ScanStatus STRING
    );

    -- Pickup, Onboard, Load, Unload
    INSERT INTO KPICodes_Temp (KPIGroup, ScanType, ScanStatus)
    VALUES 
      ('Pickup', 'P', NULL),
      ('Onboard', 'T', 'ONB'),
      ('Load', 'T', 'LOA'),
      ('Unload', 'T', 'UNL');

    -- Stop (Type T and D)
    INSERT INTO KPICodes_Temp (KPIGroup, ScanType, ScanStatus)
    SELECT 'Stop', type, status
    FROM UNNEST(['T', 'D']) AS type
    CROSS JOIN UNNEST([
      'AR1','AR2','AR3','AR4','AR5','ARA','ARB','ARC','ARE','ARR','ARY','ATL','B94','CAG','CAR',
      'CC1','CC2','CC3','CC4','CC5','CCL','CCP','CCQ','CSA','CSP','DAM','DGE','DGP','DRU',
      'F01','F02','F03','F04','F05','FFF','FUT','HAD','HAP','INC','LAI','LCL','LUN','NAA',
      'NEI','NOC','NOH','O07','O81','O82','O83','ONF','OO9','OOA','OWC','OWS','PCK','PCR',
      'PCY','PIO','PNT','PRS','R34','R35','R36','RTS','SIG','U01','U02','U03','U04','U05',
      'U06','U07','U08','U09','U10','U11','U12','U13','U14','U15','U16','U17','U38','U42',
      'UA1','UA2','UA3','UA4','UA5','UAR','UND','UTK','YES'
    ]) AS status;

    -- Cage
    INSERT INTO KPICodes_Temp (KPIGroup, ScanType, ScanStatus)
    SELECT 'Cage', 'T', rf.FranchiseeCode
    FROM `{{ project_id }}.{{ target_dataset_id }}.dv_HUB_RF` AS rf
    JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_RF` AS sat ON sat.FranchiseeCode_HSK = rf.FranchiseeCode_HSK
    WHERE sat.CountryCode IN (1, 6, 24, 11) AND sat.IsCurrent = 1;

    -- Bay
    INSERT INTO KPICodes_Temp (KPIGroup, ScanType, ScanStatus)
    SELECT DISTINCT 'Bay', 'T', CourierNumber
    FROM `{{ project_id }}.{{ target_dataset_id }}.dv_HUB_CF` AS cf
    WHERE cf.CourierNumber NOT IN ('', '#12', '#16', '#17', '#20', '***')
      AND cf.CourierNumber NOT IN (SELECT ScanStatus FROM KPICodes_Temp WHERE ScanType = 'T');

    -- Delivery
    INSERT INTO KPICodes_Temp (KPIGroup, ScanType, ScanStatus)
    VALUES
      ('Delivery', 'D', 'ATL'),
      ('Delivery', 'D', 'DAM'),
      ('Delivery', 'D', 'ONF'),
      ('Delivery', 'D', 'OOA'),
      ('Delivery', 'D', 'YES');

    -- Final Load into target table (INSERT ... SELECT as only INSERT is used)
    INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.dbo_KPICodes` (KPIGroup, ScanType, ScanStatus)
    SELECT src.KPIGroup, src.ScanType, src.ScanStatus 
    FROM KPICodes_Temp AS src
    LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPICodes` AS tgt 
      ON tgt.KPIGroup = src.KPIGroup 
      AND IFNULL(tgt.ScanType, '') = IFNULL(src.ScanType, '') 
      AND IFNULL(tgt.ScanStatus, '') = IFNULL(src.ScanStatus, '')
    WHERE tgt.KPIGroup IS NULL;

    SET v_Inserted = @@row_count;
    SET v_Result = 'Success';

  EXCEPTION WHEN ERROR THEN
    SET v_Result = 'Failed';
    SET v_ErrorMessage = @@error.message;
  END;

  -- Log the procedure execution
  SET v_Ended = CURRENT_DATETIME();
  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
    v_Component,
    v_ProcessId,
    v_Started,
    v_Ended,
    v_Result,
    v_ErrorMessage,
    v_Inserted,
    v_Updated,
    -1
  );

END;