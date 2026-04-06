-- ==========================================================================================================
-- Routine:		Load_HUB_Label
-- Description: Loads business keys into HUB_Label
-- Example:		Exec [dv].[Load_HUB_Label] 123
-- History:
--	25/10/2018  P. Waldron		Routine Written
--  02/07/2019  P. Waldron      Add CountryName column
--  29/07/2019  P. Waldron      Add three more source (stg) tables
--	16/12/2021	B. Woods		Changed the order of label source systems to match
--								the order in Load_SAT_Label_Allocation.
-- ==========================================================================================================
CREATE OR REPLACE PROCEDURE `your_project.dv.Load_HUB_Label`(
  p_ProcessID INT64
)
BEGIN
  DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
  DECLARE v_Inserted_Count INT64 DEFAULT 0;
  DECLARE v_Status STRING DEFAULT 'Success';
  DECLARE v_Error_Msg STRING DEFAULT NULL;

  BEGIN
    -- Use a MERGE to handle multi-source consolidation and deduplication
    MERGE `your_project.dv.HUB_Label` AS Target
    USING (
      WITH UnifiedLabels AS (
        -- Consolidate all sources with a priority rank (SourceOrder)
        SELECT 0 AS SrcOrder, LabelNo FROM `your_project.Staging.LabelMaster_Stg` UNION ALL
        SELECT 1 AS SrcOrder, Label AS LabelNo FROM `your_project.Staging.fl_ConItem_Stg` UNION ALL
        SELECT 2 AS SrcOrder, LabelNumber AS LabelNo FROM `your_project.Staging.API_RF_AdHocLabel_AllocationHistory_Stg` UNION ALL
        SELECT 3 AS SrcOrder, LabelNumber AS LabelNo FROM `your_project.Staging.tblFastLabel_Consignment_Stg` UNION ALL
        SELECT 4 AS SrcOrder, LabelNumber AS LabelNo FROM `your_project.Staging.ConsignmentItem_Stg` UNION ALL
        SELECT 5 AS SrcOrder, LabelNo FROM `your_project.Staging.HDManifests_Stg` UNION ALL
        SELECT 6 AS SrcOrder, LabelNumber AS LabelNo FROM `your_project.Staging.Ebay_Labels_Stg` UNION ALL
        SELECT 7 AS SrcOrder, label_number AS LabelNo FROM `your_project.Staging.tblOnlineEnquiry_RP_Stg` UNION ALL
        SELECT 8 AS SrcOrder, LabelNumber AS LabelNo FROM `your_project.Staging.tblTasman_Consignment_Stg` UNION ALL
        SELECT 9 AS SrcOrder, result_LabelNumber AS LabelNo FROM `your_project.Staging.API_Temando_RequestLabel_Stg`
      ),
      RankedLabels AS (
        -- Group by LabelNo and pick the minimum SourceOrder to determine RecordSource
        SELECT 
          LabelNo,
          MIN(SrcOrder) AS MinSrcOrder
        FROM UnifiedLabels
        WHERE LabelNo IS NOT NULL AND LabelNo != ''
        GROUP BY LabelNo
      )
      SELECT 
        UPPER(TO_HEX(SHA256(TRIM(LabelNo)))) AS LabelNo_HSK,
        LabelNo,
        v_Started AS Loaded,
        p_ProcessID AS ProcessID,
        CASE MinSrcOrder
          WHEN 0 THEN 'LabelMaster'
          WHEN 1 THEN 'MyFastway'
          WHEN 2 THEN 'DynamicLabel'
          WHEN 3 THEN 'FastLabel'
          WHEN 4 THEN 'FastLabelEnterprise'
          WHEN 5 THEN 'HDManifests'
          WHEN 6 THEN 'EBAY'
          WHEN 7 THEN 'ReceiverPays'
          WHEN 8 THEN 'Tasman'
          WHEN 9 THEN 'Temando'
          ELSE CONCAT('Unknown:', CAST(MinSrcOrder AS STRING))
        END AS RecordSource
      FROM RankedLabels
    ) AS Source
    ON Target.LabelNo_HSK = Source.LabelNo_HSK
    -- Only insert if the Label HSK does not already exist in the Hub
    WHEN NOT MATCHED THEN
      INSERT (LabelNo_HSK, LabelNo, Loaded, ProcessID, RecordSource)
      VALUES (Source.LabelNo_HSK, Source.LabelNo, Source.Loaded, Source.ProcessID, Source.RecordSource);

    SET v_Inserted_Count = @@row_count;

  EXCEPTION WHEN ERROR THEN
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- Metadata Logging
  CALL `your_project.Staging.SaveLog`(
    'dv.Load_HUB_Label',
    p_ProcessID,
    v_Started,
    CURRENT_TIMESTAMP(),
    v_Status,
    v_Error_Msg,
    v_Inserted_Count
  );

  IF v_Status = 'Failed' THEN
    ERROR(v_Error_Msg);
  END IF;

END;
