-- ==========================================================================================
-- Routine:     Staging_Copy_PickupRequest_Country_To_Stg
-- Description: Copies new pickup-request rows from a country staging table
--              (`Staging_PickupRequest_<CC>_Stg`) into shared `Staging_PickupRequest_Stg`
--              (SSIS «Copy Country Staging to PickupRequest_Stg»). Only inserts IDs
--              not already present in the shared table.
-- Parameters:
--   p_country_suffix — AU, NZ, or SA (suffix of `Staging_PickupRequest_<CC>_Stg`).
-- History:
--  [BQ]  2026-05-27  Extracted from LoadPickupRequests DAG inline SQL.
-- ==========================================================================================
CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_Copy_PickupRequest_Country_To_Stg`(
  IN p_country_suffix STRING
)
BEGIN
  IF p_country_suffix NOT IN ('AU', 'NZ', 'SA') THEN
    RAISE USING MESSAGE = CONCAT(
      'Invalid p_country_suffix: ',
      IFNULL(p_country_suffix, '<NULL>'),
      '; expected AU, NZ, or SA.'
    );
  END IF;

  EXECUTE IMMEDIATE FORMAT(
    """
    INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_PickupRequest_Stg` (
      ID,
      CreateDateUtc,
      ShouldPrintLabel,
      PickupFranchiseeCode,
      PickupCourierNumber,
      LabelNumber,
      CollectionDate,
      CollectionCycle,
      PickupAddress1,
      PickupAddress2,
      PickupSuburb,
      PickupPostcode,
      PickupName,
      PickupPhone,
      PickupEmail,
      DeliveryAddress1,
      DeliveryAddress2,
      DeliverySuburb,
      DeliveryPostcode,
      DeliveryName,
      DeliveryPhone,
      DeliveryEmail,
      IsMessageSent,
      Weight,
      Width,
      Height,
      Length,
      RequestingCustomerName,
      CountryCode,
      IsPrinted,
      IsComplete,
      ConsolidationGroupId,
      CourierMessageResult,
      ConsolidationDateUtc,
      PickupSpecialInstructions,
      DeliverySpecialInstructions,
      HhcMessageId,
      HasCourierRejected,
      IsRegularCollection,
      RequestingCustomerOesId,
      IsCancelled,
      CancellationReason,
      CancellationTitle,
      FutileScanDate,
      NotReadyScanDate,
      PickupScanDate,
      MessageSentDateUtc,
      CourierMessageResultText,
      RejectionReason,
      RejectionDate,
      InternalStatus,
      DidNotAssignCourierDuringCreation,
      IsReturnService,
      IsParcelConnectPickupLocation,
      SecondaryLabelNumber,
      PickupSubDepotFranchiseeCode,
      CubicWeight,
      PickupCompany,
      DeliveryCompany,
      IsPriority
    )
    SELECT
      Src.Id,
      Src.CreateDateUtc,
      Src.ShouldPrintLabel,
      Src.PickupFranchiseeCode,
      Src.PickupCourierNumber,
      Src.LabelNumber,
      Src.CollectionDate,
      Src.CollectionCycle,
      Src.PickupAddress1,
      Src.PickupAddress2,
      Src.PickupSuburb,
      Src.PickupPostcode,
      Src.PickupName,
      Src.PickupPhone,
      Src.PickupEmail,
      Src.DeliveryAddress1,
      Src.DeliveryAddress2,
      Src.DeliverySuburb,
      Src.DeliveryPostcode,
      Src.DeliveryName,
      Src.DeliveryPhone,
      Src.DeliveryEmail,
      Src.IsMessageSent,
      Src.Weight,
      Src.Width,
      Src.Height,
      Src.Length,
      Src.RequestingCustomerName,
      Src.CountryCode,
      Src.IsPrinted,
      Src.IsComplete,
      Src.ConsolidationGroupId,
      Src.CourierMessageResult,
      Src.ConsolidationDateUtc,
      Src.PickupSpecialInstructions,
      Src.DeliverySpecialInstructions,
      Src.HhcMessageId,
      Src.HasCourierRejected,
      Src.IsRegularCollection,
      Src.RequestingCustomerOesId,
      Src.IsCancelled,
      Src.CancellationReason,
      Src.CancellationTitle,
      Src.FutileScanDate,
      Src.NotReadyScanDate,
      Src.PickupScanDate,
      Src.MessageSentDateUtc,
      Src.CourierMessageResultText,
      Src.RejectionReason,
      Src.RejectionDate,
      Src.InternalStatus,
      Src.DidNotAssignCourierDuringCreation,
      Src.IsReturnService,
      Src.IsParcelConnectPickupLocation,
      Src.SecondaryLabelNumber,
      Src.PickupSubDepotFranchiseeCode,
      Src.CubicWeight,
      Src.PickupCompany,
      Src.DeliveryCompany,
      Src.IsPriority
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_PickupRequest_%s_Stg` AS Src
    LEFT JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_PickupRequest_Stg` AS Tgt
      ON Tgt.ID = Src.Id
    WHERE Tgt.ID IS NULL
    """,
    p_country_suffix
  );
END;