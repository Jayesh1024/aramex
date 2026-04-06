-- ==========================================================================================
-- Routine:		Load_HUB_Container
-- Description: Loads business keys into HUB_Container
-- Example:		Exec [dv].[Load_HUB_Container] 123, 'Fastway' 
-- History:
--	13/11/2018  P. Waldron		Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `your_project.dv.Load_HUB_Container`(
  p_ProcessID INT64,
  p_RecordSource STRING
)
BEGIN
  DECLARE v_Started TIMESTAMP DEFAULT CURRENT_TIMESTAMP();
  DECLARE v_Inserted_Count INT64 DEFAULT 0;
  DECLARE v_Status STRING DEFAULT 'Success';
  DECLARE v_Error_Msg STRING DEFAULT NULL;

  BEGIN
    -- Using MERGE for atomic "Insert if not exists" logic
    MERGE `your_project.dv.HUB_Container` AS Target
    USING (
      SELECT DISTINCT
        -- Hashing the business key 'Container'
        UPPER(TO_HEX(SHA256(TRIM(Container)))) AS Container_HSK,
        Container,
        v_Started AS Loaded,
        p_ProcessID AS ProcessID,
        p_RecordSource AS RecordSource
      FROM `your_project.Staging.BBA_ContainerMaster_Stg`
      WHERE TruckOrContainer = 'C'
        AND Container IS NOT NULL
        AND TRIM(Container) != ''
    ) AS Source
    ON Target.Container_HSK = Source.Container_HSK
    WHEN NOT MATCHED THEN
      INSERT (Container_HSK, Container, Loaded, ProcessID, RecordSource)
      VALUES (Source.Container_HSK, Source.Container, Source.Loaded, Source.ProcessID, Source.RecordSource);

    SET v_Inserted_Count = @@row_count;

  EXCEPTION WHEN ERROR THEN
    SET v_Status = 'Failed';
    SET v_Error_Msg = @@error.message;
  END;

  -- Metadata Logging (assuming SaveLog exists in BigQuery)
  CALL `your_project.Staging.SaveLog`(
    'dv.Load_HUB_Container',
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
