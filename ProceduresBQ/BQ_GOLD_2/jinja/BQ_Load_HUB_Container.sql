-- ==========================================================================================
-- Routine:   Load_HUB_Container
-- Description: Loads business keys into HUB_Container
-- Example:   Exec [dv].[Load_HUB_Container] 123, 'Fastway' 
-- History:
--  13/11/2018  P. Waldron    Routine Written
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.dv_Load_HUB_Container`(
  p_ProcessID INT64,
  p_RecordSource STRING
)
BEGIN
  -- timestamp
  DECLARE v_Started DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
  DECLARE v_Status STRING DEFAULT 'Success';
  DECLARE v_Error_Msg STRING DEFAULT NULL;
  DECLARE v_Inserted_Count INT64 DEFAULT 0;

  BEGIN
    -- Using MERGE for atomic "Insert if not exists" logic
    -- Path transformed to: {{ project_id }}.{{ target_dataset_id }}.dv_HUB_Container
    MERGE `{{ project_id }}.{{ target_dataset_id }}.dv_HUB_Container` AS Target
    USING (
      SELECT DISTINCT
        -- Hashing the business key 'Container' (Standard DV 2.0 SHA256)
        -- Kept as STRING (TO_HEX) to match existing table schema
        UPPER(TO_HEX(SHA256(TRIM(Container)))) AS Container_HSK,
        Container,
        v_Loaded AS Loaded,
        p_ProcessID AS ProcessID,
        p_RecordSource AS RecordSource
      -- Path transformed to: {{ project_id }}.{{ target_dataset_id }}.Staging_BBA_ContainerMaster_Stg
      FROM `{{ project_id }}.{{ target_dataset_id }}.Staging_BBA_ContainerMaster_Stg`
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

  -- Metadata Logging
  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_SaveLog`(
    'dv_Load_HUB_Container',
    p_ProcessID,
    v_Started,
    CURRENT_DATETIME(),
    v_Status,
    v_Error_Msg,
    v_Inserted_Count,
    0,
    0
  );

  IF v_Status = 'Failed' THEN
    RAISE USING MESSAGE = v_Error_Msg;
  END IF;

END;