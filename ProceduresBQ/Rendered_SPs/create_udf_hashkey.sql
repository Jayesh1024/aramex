-- ==========================================================================================
-- Object:      dbo_GetHashKey (UDF)
-- Purpose:     Generates SHA256 Hash Keys for Data Vault Business Keys.
-- Phase:       Wave 0 (Global Requirements)
-- ==========================================================================================

CREATE OR REPLACE FUNCTION `{{ project_id }}.{{ target_dataset_id }}.dbo_GetHashKey`(input_string STRING) 
RETURNS BYTES AS (
  -- Removed TO_HEX(). SHA256() returns raw BYTES.
  -- This is 100% compatible with a BYTES column.
  SHA256(UPPER(TRIM(IFNULL(input_string, ''))))
);