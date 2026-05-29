-- ==========================================================================================
-- Routine:     Load_Missing_AttemptedAndActual_DeliveryScans
--
-- Description: 1. Loads historical scans that were outside the normal processing window. This routine looks for
--				NULL AttemptedDeliveryDate and NULL ActualDeliveryDate and tries to match by ScanStatus with an 
--				Attempted or Delivery scan in LNK_Scan as defined in table KPIScanGroups.
--				Specify the StartDate and EndDate for the range of scans to search in LNK_Scan
--
--				2. After running this procedure the "ReLoad Fact_KPI" job needs to be run with the DisableStaging parameter
--				set to True and the	DisableFinal parmeter set to False. The StartDateOverRide and EndDateOverRide parameters 
--				are ignored when running with DisableStaging set to False.
--
-- Example:     Exec [dbo].[Load_Fact_KPI_Stg] 30
-- History:
--		01/12/2022  B. Woods        Routine Written
--
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `{{ project_id }}.{{ sp_dataset_id }}.Staging_Load_Missing_AttemptedAndActual_DeliveryScans`(
  IN p_ProcessId  INT64,
  IN p_StartDate  STRING,    -- e.g. '2024-01-01'
  IN p_EndDate    STRING     -- e.g. '2025-05-01'
)
BEGIN

  -- -----------------------------------------------------------------------
  -- Step 1: Attempted delivery scans
  -- Replaces SELECT INTO working.temp_AttemptedDeliveryScans
  -- CREATE OR REPLACE makes this idempotent — no OBJECT_ID check needed
  -- -----------------------------------------------------------------------
  CREATE OR REPLACE TEMP TABLE temp_AttemptedDeliveryScans AS
  SELECT
    D.LabelNo,
    S.ScanType,
    S.ScanStatus,
    DATE(S.ScanDate)  AS ScanDate,
    G.KPIGroup,
    D.CountryCode,
    S.FranchiseeCode,
    S.CourierNumber
  FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI_Daily` D
  LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_LNK_Scan` S
    ON  D.LabelNo  = S.LabelNo
    AND S.ScanType = 'D'
    AND S.ScanDate >= CAST(p_StartDate AS DATE)
    AND S.ScanDate <  CAST(p_EndDate   AS DATE)
  LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIScanGroups` G
    ON G.ScanStatus = S.ScanStatus
   AND G.KPIGroup   IN ('Attempted')
  WHERE S.LabelNo              IS NOT NULL
    AND G.ScanStatus           IS NOT NULL
    AND D.ActualAttemptedDate  IS NULL;

  -- -----------------------------------------------------------------------
  -- Step 2: Truncate Staging target before loading
  -- -----------------------------------------------------------------------
  TRUNCATE TABLE `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_KPI_Src_Stg`;

  -- -----------------------------------------------------------------------
  -- Step 3: Insert attempted scans joined to SAT_Label_Allocation_MF
  -- -----------------------------------------------------------------------
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_KPI_Src_Stg`
  (
    LabelNo,
    CountryCode,
    ScanDateTime,
    ScanType,
    ScanStatus,
    FranchiseeCode,
    CourierNumber,
    ScanDate,
    CreatedOn,
    FromRf,
    FromCf,
    ToRf,
    ToCf,
    ToLocality,
    ToPostalCode,
    RealisedDate,
    Zone,
    CustomerId
  )
  WITH MF AS (
    SELECT
      MF.LabelNo,
      MF.CountryCode,
      R.ScanDate        AS ScanDateTime,
      R.ScanType,
      R.ScanStatus,
      R.FranchiseeCode,
      R.CourierNumber,
      R.ScanDate        AS ScanDate,
      MF.CreatedOn,
      MF.FromRf,
      MF.FromCf,
      MF.ToRf,
      MF.ToCf,
      MF.ToLocality,
      MF.ToPostalCode,
      MF.RealisedDate,
      MF.Zone,
      MF.CustomerId
    FROM temp_AttemptedDeliveryScans R
    INNER JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF_partitioned` MF
      ON  MF.CountryCode   = 1
      AND MF.LabelNo       = R.LabelNo
      AND MF.IsCurrent     = 1
      AND MF.RealisedDate  IS NOT NULL
  )
  SELECT * FROM MF;

  -- -----------------------------------------------------------------------
  -- Step 4: Actual delivery scans
  -- Replaces SELECT INTO working.temp_ActualDeliveryScans
  -- -----------------------------------------------------------------------
  CREATE OR REPLACE TEMP TABLE temp_ActualDeliveryScans AS
  SELECT
    D.LabelNo,
    S.ScanType,
    S.ScanStatus,
    DATE(S.ScanDate)  AS ScanDate,
    G.KPIGroup,
    D.CountryCode,
    S.FranchiseeCode,
    S.CourierNumber
  FROM `{{ project_id }}.{{ target_dataset_id }}.dbo_Fact_KPI_Daily` D
  LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_LNK_Scan` S
    ON  D.LabelNo  = S.LabelNo
    AND S.ScanType = 'D'
    AND S.ScanDate >= CAST(p_StartDate AS DATE)
    AND S.ScanDate <  CAST(p_EndDate   AS DATE)
  LEFT JOIN `{{ project_id }}.{{ target_dataset_id }}.dbo_KPIScanGroups` G
    ON G.ScanStatus = S.ScanStatus
   AND G.KPIGroup   IN ('Delivery')
  WHERE S.LabelNo                IS NOT NULL
    AND G.ScanStatus             IS NOT NULL
    AND D.ActualDeliveryScanDate IS NULL;

  -- -----------------------------------------------------------------------
  -- Step 5: Insert actual delivery scans joined to SAT_Label_Allocation_MF
  -- -----------------------------------------------------------------------
  INSERT INTO `{{ project_id }}.{{ target_dataset_id }}.Staging_Fact_KPI_Src_Stg`
  (
    LabelNo,
    CountryCode,
    ScanDateTime,
    ScanType,
    ScanStatus,
    FranchiseeCode,
    CourierNumber,
    ScanDate,
    CreatedOn,
    FromRf,
    FromCf,
    ToRf,
    ToCf,
    ToLocality,
    ToPostalCode,
    RealisedDate,
    Zone,
    CustomerId
  )
  WITH MF AS (
    SELECT
      MF.LabelNo,
      MF.CountryCode,
      R.ScanDate        AS ScanDateTime,
      R.ScanType,
      R.ScanStatus,
      R.FranchiseeCode,
      R.CourierNumber,
      R.ScanDate        AS ScanDate,
      MF.CreatedOn,
      MF.FromRf,
      MF.FromCf,
      MF.ToRf,
      MF.ToCf,
      MF.ToLocality,
      MF.ToPostalCode,
      MF.RealisedDate,
      MF.Zone,
      MF.CustomerId
    FROM temp_ActualDeliveryScans R
    INNER JOIN `{{ project_id }}.{{ target_dataset_id }}.dv_SAT_Label_Allocation_MF_partitioned` MF
      ON  MF.CountryCode   = 1
      AND MF.LabelNo       = R.LabelNo
      AND MF.IsCurrent     = 1
      AND MF.RealisedDate  IS NOT NULL
  )
  SELECT * FROM MF;

  -- -----------------------------------------------------------------------
  -- Step 6: Chain to downstream load procedure
  -- -----------------------------------------------------------------------
  CALL `{{ project_id }}.{{ sp_dataset_id }}.Staging_Load_Fact_KPI_Daily_Stg`(p_ProcessId);

END;