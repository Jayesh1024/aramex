CREATE OR REPLACE PROCEDURE `searce-sandbox-da-delivery.Aramex_oceania_SP.rpt_GetDeliveryDate`(
  IN  p_ArrivalDate   DATETIME,
  IN  p_PickupRF      STRING,
  IN  p_Suburb        STRING,
  IN  p_Postcode      INT64,
  OUT p_DeliveryDate  DATE,
  OUT p_DeliveryCycle STRING
)
BEGIN

  DECLARE v_ArrivalDate    DATETIME DEFAULT p_ArrivalDate;
  DECLARE v_ArrivalDay     INT64;
  DECLARE v_ArrivalCycle   STRING;
  DECLARE v_CurrentCycle   STRING;
  DECLARE v_DeliveryDate   DATE;
  DECLARE v_Found          BOOL DEFAULT FALSE;

  -- -----------------------------------------------------------------------
  -- Derive ISO day of week: Monday = 1 ... Sunday = 7
  -- BQ EXTRACT(DAYOFWEEK) returns Sunday=1, so we adjust:
  -- MOD(EXTRACT(DAYOFWEEK FROM date) + 5, 7) + 1 gives Mon=1 ... Sun=7
  -- -----------------------------------------------------------------------
  SET v_ArrivalDay = MOD(EXTRACT(DAYOFWEEK FROM v_ArrivalDate) + 5, 7) + 1;

  -- -----------------------------------------------------------------------
  -- Determine arrival cycle: AM (<12) or PM (>=12)
  -- If AM → available for PM same day
  -- If PM → roll to next day AM
  -- -----------------------------------------------------------------------
  IF EXTRACT(HOUR FROM v_ArrivalDate) < 12 THEN
    SET v_ArrivalCycle = 'P';   -- available for delivery in PM same day
  ELSE
    SET v_ArrivalDate  = DATETIME(DATE_ADD(CAST(v_ArrivalDate AS DATE), INTERVAL 1 DAY));
    SET v_ArrivalDay   = MOD(EXTRACT(DAYOFWEEK FROM v_ArrivalDate) + 5, 7) + 1;
    SET v_ArrivalCycle = 'A';   -- available for delivery in AM next day
  END IF;

  SET v_DeliveryDate = CAST(v_ArrivalDate AS DATE);

  -- -----------------------------------------------------------------------
  -- REFACTORED: Look up the delivery cycle for the current day from Tmp_TSS
  -- Use SET variable = (SELECT ...) instead of SELECT INTO
  -- -----------------------------------------------------------------------
  SET v_CurrentCycle = (
    SELECT
      CASE v_ArrivalDay
        WHEN 1 THEN Mon
        WHEN 2 THEN Tue
        WHEN 3 THEN Wed
        WHEN 4 THEN Thu
        WHEN 5 THEN Fri
        WHEN 6 THEN Sat
        WHEN 7 THEN Sun
        ELSE        Mon
      END
    FROM `searce-sandbox-da-delivery.Aramex_oceania.dbo_Tmp_TSS`
    WHERE PickFranchise = p_PickupRF
      AND Town          = p_Suburb
      AND Postcode      = p_Postcode
    LIMIT 1
  );

  -- -----------------------------------------------------------------------
  -- If no TSS record found return NULLs
  -- -----------------------------------------------------------------------
  IF v_CurrentCycle IS NULL THEN
    SET p_DeliveryDate  = NULL;
    SET p_DeliveryCycle = NULL;
    RETURN;
  END IF;

  -- -----------------------------------------------------------------------
  -- Advance date until a valid delivery cycle is found
  -- Bounded to 14 days to guarantee termination
  -- -----------------------------------------------------------------------
  FOR day_rec IN (
    SELECT day_date
    FROM UNNEST(
      GENERATE_DATE_ARRAY(
        DATE_ADD(CAST(v_ArrivalDate AS DATE), INTERVAL 1 DAY),
        DATE_ADD(CAST(v_ArrivalDate AS DATE), INTERVAL 14 DAY)
      )
    ) AS day_date
  )
  DO
    -- Exit loop if current day/cycle combination is already valid
    IF NOT (
      (v_ArrivalCycle = 'A' AND v_CurrentCycle = 'N') OR
      (v_ArrivalCycle = 'P' AND v_CurrentCycle NOT IN ('P', 'B'))
    ) THEN
      SET v_Found = TRUE;
      LEAVE;                      -- BQ LEAVE exits the FOR loop
    END IF;

    -- Advance to next day
    SET v_ArrivalDay   = MOD(EXTRACT(DAYOFWEEK FROM day_rec.day_date) + 5, 7) + 1;
    SET v_DeliveryDate = day_rec.day_date;
    SET v_ArrivalCycle = 'A';     -- reset to AM on any rolled-forward day

    -- -----------------------------------------------------------------------
    -- REFACTORED: Look up the delivery cycle for the advanced day
    -- Use SET variable = (SELECT ...) instead of SELECT INTO
    -- -----------------------------------------------------------------------
    SET v_CurrentCycle = (
      SELECT
        CASE v_ArrivalDay
          WHEN 1 THEN Mon
          WHEN 2 THEN Tue
          WHEN 3 THEN Wed
          WHEN 4 THEN Thu
          WHEN 5 THEN Fri
          WHEN 6 THEN Sat
          WHEN 7 THEN Sun
          ELSE        Mon
        END
      FROM `searce-sandbox-da-delivery.Aramex_oceania.dbo_Tmp_TSS`
      WHERE PickFranchise = p_PickupRF
        AND Town          = p_Suburb
        AND Postcode      = p_Postcode
      LIMIT 1
    );

  END FOR;

  -- -----------------------------------------------------------------------
  -- Final cycle adjustment:
  -- If we landed on an AM arrival with a PM-only cycle, promote to PM
  -- -----------------------------------------------------------------------
  IF v_ArrivalCycle = 'A' AND v_CurrentCycle = 'P' THEN
    SET v_ArrivalCycle = 'P';
  END IF;

  SET p_DeliveryDate  = v_DeliveryDate;
  SET p_DeliveryCycle = v_ArrivalCycle;

END;