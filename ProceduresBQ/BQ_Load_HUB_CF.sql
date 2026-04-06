-- ==========================================================================================
-- Routine:		Load_HUB_CF (courier franchisee)
-- Description: Loads business keys into HUB_CF
-- Example:		Exec [DV].[Load_HUB_CF] 123, 'Fastway'  
-- History:
--	25/10/2018  P. Waldron		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `your_project.dv.Load_HUB_CF`(
  p_ProcessID INT64,
  p_RecordSource STRING
)
BEGIN
  DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
  DECLARE v_Inserted_Count INT64 DEFAULT 0;
  DECLARE v_Status STRING DEFAULT 'Success';
  DECLARE v_Error_Msg STRING DEFAULT NULL;

  BEGIN
    -- MERGE effectively replaces the EXCEPT logic by checking the Hash Key
    MERGE `your_project.dv.HUB_CF` AS Target
    USING (
      SELECT DISTINCT
        -- Hashing: RFCode + '^' + CourierNumber
        UPPER(TO_HEX(SHA256(CONCAT(IFNULL(RFCode, ''), '^', IFNULL(CourierNumber, ''))))) AS Courier_HSK,
        RFCode,
        CourierNumber,
        v_Started AS Loaded,
        p_ProcessID AS ProcessID,
        p_RecordSource AS RecordSource
      FROM `your_project.Staging.Courier_Stg`
      -- Filter out records where both keys might be missing if applicable
      WHERE RFCode IS NOT NULL OR CourierNumber IS NOT NULL
    ) AS Source
    ON Target.Courier_HSK = Source.Courier_HSK
    WHEN NOT MATCHED THEN
      INSERT (Courier_HSK, RFCode, CourierNumber, Loaded, ProcessID, RecordSource)
      VALUES (Source.Courier_HSK, Source.RFCode, Source.CourierNumber, Source.Loaded, Source.ProcessID, Source.RecordSource);

    SET v_Inserted_Count = @@row_count;

  EXCEPTION WHEN ERROR THEN
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- Metadata Logging
  CALL `your_project.Staging.SaveLog`(
    'dv.Load_HUB_CF',
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
