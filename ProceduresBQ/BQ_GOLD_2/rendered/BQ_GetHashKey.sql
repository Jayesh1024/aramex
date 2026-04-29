-- ==========================================================================================
-- Function:  GetHashKey (BigQuery Standard SQL)
-- Description: Returns SHA1(BYTES) of the supplied business key, matching SQL Server
--              [dbo].[GetHashKey] normalization rules.
-- Example:
--   SELECT `your_project.your_dataset.dbo_GetHashKey`('C12345', '^');
-- Notes:
--   - Replace `your_project.your_dataset` with your project and dataset.
--   - `delim` is intended as a single character (same as original nchar(1)).
--   - BigQuery does not support DEFAULT on function parameters; pass '^' (or the
--     delimiter used in the business_key) explicitly at every call site.
-- ==========================================================================================
CREATE OR REPLACE FUNCTION `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.dbo_GetHashKey`(
  business_key STRING,
  delim STRING
)
RETURNS BYTES
AS (
  SHA1(
    IF(
      business_key IS NULL
      OR STRPOS(business_key, delim) = 0,
      UPPER(TRIM(business_key)),
      UPPER(
        ARRAY_TO_STRING(
          ARRAY(
            SELECT TRIM(part)
            FROM UNNEST(SPLIT(business_key, delim)) AS part
          ),
          delim
        )
      )
    )
  )
);