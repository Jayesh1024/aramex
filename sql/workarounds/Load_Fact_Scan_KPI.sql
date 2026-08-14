DECLARE v_Loaded DATETIME DEFAULT CURRENT_DATETIME();
DECLARE p_ProcessId INT64 DEFAULT 2;

CREATE OR REPLACE TEMP TABLE LabelsToProcess AS
  SELECT
    Stg.LabelNo,
    CASE
      WHEN Tgt.LabelNo IS NOT NULL
      THEN ROW_NUMBER() OVER (
             PARTITION BY CASE WHEN Tgt.LabelNo = Stg.LabelNo THEN 1 END
             ORDER BY Stg.LabelNo
           )
      ELSE NULL
    END AS UpdateId,
    CASE
      WHEN Tgt.LabelNo IS NULL
      THEN ROW_NUMBER() OVER (
             PARTITION BY CASE WHEN Tgt.LabelNo IS NULL THEN 1 END
             ORDER BY Stg.LabelNo
           )
      ELSE NULL
    END AS InsertId
  FROM `prj-drgfly-prod-sp-01.validation_results.Staging_Fact_Scan_KPI_Stg_reloadWithTieBreaker` AS Stg
  LEFT JOIN `prj-drgfly-prod-sp-01.validation_results.dbo_Fact_Scan_KPI_reloadWithTieBreaker` AS Tgt
    ON Tgt.LabelNo = Stg.LabelNo;

MERGE `prj-drgfly-prod-sp-01.validation_results.dbo_Fact_Scan_KPI_reloadWithTieBreaker` AS Tgt
    USING (
      SELECT Src.*
      FROM `prj-drgfly-prod-sp-01.validation_results.Staging_Fact_Scan_KPI_Stg_reloadWithTieBreaker` Src
      JOIN LabelsToProcess Sel ON Sel.LabelNo = Src.LabelNo
      WHERE Sel.UpdateId IS NOT NULL
    ) AS Src
    ON Tgt.LabelNo = Src.LabelNo

    WHEN MATCHED AND (
      IFNULL(CAST(Tgt.FirstScanDate AS STRING),          '') != IFNULL(CAST(Src.FirstScanDate AS STRING),          '') OR
      IFNULL(Tgt.FirstScanRF,                            '') != IFNULL(Src.FirstScanRF,                            '') OR
      IFNULL(Tgt.FirstScanCF,                            '') != IFNULL(Src.FirstScanCF,                            '') OR
      IFNULL(Tgt.FirstScanType,                          '') != IFNULL(Src.FirstScanType,                          '') OR
      IFNULL(Tgt.FirstScanStatus,                        '') != IFNULL(Src.FirstScanStatus,                        '') OR
      IFNULL(CAST(Tgt.LastScanDate AS STRING),           '') != IFNULL(CAST(Src.LastScanDate AS STRING),           '') OR
      IFNULL(Tgt.LastScanRF,                             '') != IFNULL(Src.LastScanRF,                             '') OR
      IFNULL(Tgt.LastScanCF,                             '') != IFNULL(Src.LastScanCF,                             '') OR
      IFNULL(Tgt.LastScanType,                           '') != IFNULL(Src.LastScanType,                           '') OR
      IFNULL(Tgt.LastScanStatus,                         '') != IFNULL(Src.LastScanStatus,                         '') OR
      IFNULL(CAST(Tgt.FirstPscanDate AS STRING),         '') != IFNULL(CAST(Src.FirstPscanDate AS STRING),         '') OR
      IFNULL(Tgt.FirstPscanRF,                           '') != IFNULL(Src.FirstPscanRF,                           '') OR
      IFNULL(Tgt.FirstPscanCF,                           '') != IFNULL(Src.FirstPscanCF,                           '') OR
      IFNULL(Tgt.FirstPscanStatus,                       '') != IFNULL(Src.FirstPscanStatus,                       '') OR
      IFNULL(CAST(Tgt.FirstDscanDate AS STRING),         '') != IFNULL(CAST(Src.FirstDscanDate AS STRING),         '') OR
      IFNULL(Tgt.FirstDscanRF,                           '') != IFNULL(Src.FirstDscanRF,                           '') OR
      IFNULL(Tgt.FirstDscanCF,                           '') != IFNULL(Src.FirstDscanCF,                           '') OR
      IFNULL(Tgt.FirstDscanStatus,                       '') != IFNULL(Src.FirstDscanStatus,                       '') OR
      IFNULL(CAST(Tgt.FirstReceivedDate AS STRING),      '') != IFNULL(CAST(Src.FirstReceivedDate AS STRING),      '') OR
      IFNULL(Tgt.FirstReceivedRF,                        '') != IFNULL(Src.FirstReceivedRF,                        '') OR
      IFNULL(Tgt.FirstReceivedCF,                        '') != IFNULL(Src.FirstReceivedCF,                        '') OR
      IFNULL(Tgt.FirstReceivedScanType,                  '') != IFNULL(Src.FirstReceivedScanType,                  '') OR
      IFNULL(Tgt.FirstReceivedScanStatus,                '') != IFNULL(Src.FirstReceivedScanStatus,                '') OR
      IFNULL(CAST(Tgt.LastReceivedDate AS STRING),       '') != IFNULL(CAST(Src.LastReceivedDate AS STRING),       '') OR
      IFNULL(Tgt.LastReceivedRF,                         '') != IFNULL(Src.LastReceivedRF,                         '') OR
      IFNULL(Tgt.LastReceivedCF,                         '') != IFNULL(Src.LastReceivedCF,                         '') OR
      IFNULL(Tgt.LastReceivedScanType,                   '') != IFNULL(Src.LastReceivedScanType,                   '') OR
      IFNULL(Tgt.LastReceivedScanStatus,                 '') != IFNULL(Src.LastReceivedScanStatus,                 '') OR
      IFNULL(CAST(Tgt.FirstSortedDate AS STRING),        '') != IFNULL(CAST(Src.FirstSortedDate AS STRING),        '') OR
      IFNULL(Tgt.FirstSortedRF,                          '') != IFNULL(Src.FirstSortedRF,                          '') OR
      IFNULL(Tgt.FirstSortedCF,                          '') != IFNULL(Src.FirstSortedCF,                          '') OR
      IFNULL(Tgt.FirstSortedScanType,                    '') != IFNULL(Src.FirstSortedScanType,                    '') OR
      IFNULL(Tgt.FirstSortedScanStatus,                  '') != IFNULL(Src.FirstSortedScanStatus,                  '') OR
      IFNULL(CAST(Tgt.LastSortedDate AS STRING),         '') != IFNULL(CAST(Src.LastSortedDate AS STRING),         '') OR
      IFNULL(Tgt.LastSortedRF,                           '') != IFNULL(Src.LastSortedRF,                           '') OR
      IFNULL(Tgt.LastSortedCF,                           '') != IFNULL(Src.LastSortedCF,                           '') OR
      IFNULL(Tgt.LastSortedScanType,                     '') != IFNULL(Src.LastSortedScanType,                     '') OR
      IFNULL(Tgt.LastSortedScanStatus,                   '') != IFNULL(Src.LastSortedScanStatus,                   '') OR
      IFNULL(CAST(Tgt.FirstDepartedDate AS STRING),      '') != IFNULL(CAST(Src.FirstDepartedDate AS STRING),      '') OR
      IFNULL(Tgt.FirstDepartedRF,                        '') != IFNULL(Src.FirstDepartedRF,                        '') OR
      IFNULL(Tgt.FirstDepartedCF,                        '') != IFNULL(Src.FirstDepartedCF,                        '') OR
      IFNULL(Tgt.FirstDepartedScanType,                  '') != IFNULL(Src.FirstDepartedScanType,                  '') OR
      IFNULL(Tgt.FirstDepartedScanStatus,                '') != IFNULL(Src.FirstDepartedScanStatus,                '') OR
      IFNULL(CAST(Tgt.LastDepartedDate AS STRING),       '') != IFNULL(CAST(Src.LastDepartedDate AS STRING),       '') OR
      IFNULL(Tgt.LastDepartedRF,                         '') != IFNULL(Src.LastDepartedRF,                         '') OR
      IFNULL(Tgt.LastDepartedCF,                         '') != IFNULL(Src.LastDepartedCF,                         '') OR
      IFNULL(Tgt.LastDepartedScanType,                   '') != IFNULL(Src.LastDepartedScanType,                   '') OR
      IFNULL(Tgt.LastDepartedScanStatus,                 '') != IFNULL(Src.LastDepartedScanStatus,                 '') OR
      IFNULL(CAST(Tgt.FirstArrivedDate AS STRING),       '') != IFNULL(CAST(Src.FirstArrivedDate AS STRING),       '') OR
      IFNULL(Tgt.FirstArrivedRF,                         '') != IFNULL(Src.FirstArrivedRF,                         '') OR
      IFNULL(Tgt.FirstArrivedCF,                         '') != IFNULL(Src.FirstArrivedCF,                         '') OR
      IFNULL(Tgt.FirstArrivedScanType,                   '') != IFNULL(Src.FirstArrivedScanType,                   '') OR
      IFNULL(Tgt.FirstArrivedScanStatus,                 '') != IFNULL(Src.FirstArrivedScanStatus,                 '') OR
      IFNULL(CAST(Tgt.LastArrivedDate AS STRING),        '') != IFNULL(CAST(Src.LastArrivedDate AS STRING),        '') OR
      IFNULL(Tgt.LastArrivedRF,                          '') != IFNULL(Src.LastArrivedRF,                          '') OR
      IFNULL(Tgt.LastArrivedCF,                          '') != IFNULL(Src.LastArrivedCF,                          '') OR
      IFNULL(Tgt.LastArrivedScanType,                    '') != IFNULL(Src.LastArrivedScanType,                    '') OR
      IFNULL(Tgt.LastArrivedScanStatus,                  '') != IFNULL(Src.LastArrivedScanStatus,                  '') OR
      IFNULL(CAST(Tgt.FirstOutDate AS STRING),           '') != IFNULL(CAST(Src.FirstOutDate AS STRING),           '') OR
      IFNULL(Tgt.FirstOutRF,                             '') != IFNULL(Src.FirstOutRF,                             '') OR
      IFNULL(Tgt.FirstOutCF,                             '') != IFNULL(Src.FirstOutCF,                             '') OR
      IFNULL(Tgt.FirstOutScanType,                       '') != IFNULL(Src.FirstOutScanType,                       '') OR
      IFNULL(Tgt.FirstOutScanStatus,                     '') != IFNULL(Src.FirstOutScanStatus,                     '') OR
      IFNULL(CAST(Tgt.LastOutDate AS STRING),            '') != IFNULL(CAST(Src.LastOutDate AS STRING),            '') OR
      IFNULL(Tgt.LastOutRF,                              '') != IFNULL(Src.LastOutRF,                              '') OR
      IFNULL(Tgt.LastOutCF,                              '') != IFNULL(Src.LastOutCF,                              '') OR
      IFNULL(Tgt.LastOutScanType,                        '') != IFNULL(Src.LastOutScanType,                        '') OR
      IFNULL(Tgt.LastOutScanStatus,                      '') != IFNULL(Src.LastOutScanStatus,                      '') OR
      IFNULL(CAST(Tgt.FirstStopDate AS STRING),          '') != IFNULL(CAST(Src.FirstStopDate AS STRING),          '') OR
      IFNULL(Tgt.FirstStopRF,                            '') != IFNULL(Src.FirstStopRF,                            '') OR
      IFNULL(Tgt.FirstStopCF,                            '') != IFNULL(Src.FirstStopCF,                            '') OR
      IFNULL(Tgt.FirstStopScanType,                      '') != IFNULL(Src.FirstStopScanType,                      '') OR
      IFNULL(Tgt.FirstStopScanStatus,                    '') != IFNULL(Src.FirstStopScanStatus,                    '') OR
      IFNULL(CAST(Tgt.LastStopDate AS STRING),           '') != IFNULL(CAST(Src.LastStopDate AS STRING),           '') OR
      IFNULL(Tgt.LastStopRF,                             '') != IFNULL(Src.LastStopRF,                             '') OR
      IFNULL(Tgt.LastStopCF,                             '') != IFNULL(Src.LastStopCF,                             '') OR
      IFNULL(Tgt.LastStopScanType,                       '') != IFNULL(Src.LastStopScanType,                       '') OR
      IFNULL(Tgt.LastStopScanStatus,                     '') != IFNULL(Src.LastStopScanStatus,                     '') OR
      IFNULL(CAST(Tgt.FirstDeliveryDate AS STRING),      '') != IFNULL(CAST(Src.FirstDeliveryDate AS STRING),      '') OR
      IFNULL(Tgt.FirstDeliveryRF,                        '') != IFNULL(Src.FirstDeliveryRF,                        '') OR
      IFNULL(Tgt.FirstDeliveryCF,                        '') != IFNULL(Src.FirstDeliveryCF,                        '') OR
      IFNULL(Tgt.FirstDeliveryScanType,                  '') != IFNULL(Src.FirstDeliveryScanType,                  '') OR
      IFNULL(Tgt.FirstDeliveryScanStatus,                '') != IFNULL(Src.FirstDeliveryScanStatus,                '') OR
      IFNULL(CAST(Tgt.LastDeliveryDate AS STRING),       '') != IFNULL(CAST(Src.LastDeliveryDate AS STRING),       '') OR
      IFNULL(Tgt.LastDeliveryRF,                         '') != IFNULL(Src.LastDeliveryRF,                         '') OR
      IFNULL(Tgt.LastDeliveryCF,                         '') != IFNULL(Src.LastDeliveryCF,                         '') OR
      IFNULL(Tgt.LastDeliveryScanType,                   '') != IFNULL(Src.LastDeliveryScanType,                   '') OR
      IFNULL(Tgt.LastDeliveryScanStatus,                 '') != IFNULL(Src.LastDeliveryScanStatus,                 '') OR
      IFNULL(CAST(Tgt.StopDays AS STRING),               '') != IFNULL(CAST(Src.StopDays AS STRING),               '') OR
      IFNULL(CAST(Tgt.StopHoliday AS STRING),            '') != IFNULL(CAST(Src.StopHoliday AS STRING),            '') OR
      IFNULL(CAST(Tgt.KPI AS STRING),                    '') != IFNULL(CAST(Src.KPI AS STRING),                    '') OR
      IFNULL(CAST(Tgt.SingleCycle AS STRING),            '') != IFNULL(CAST(Src.SingleCycle AS STRING),            '') OR
      IFNULL(CAST(Tgt.SubDepot AS STRING),               '') != IFNULL(CAST(Src.SubDepot AS STRING),               '') OR
      IFNULL(CAST(Tgt.DeliveryDays AS STRING),           '') != IFNULL(CAST(Src.DeliveryDays AS STRING),           '') OR
      IFNULL(CAST(Tgt.DeliveryHoliday AS STRING),        '') != IFNULL(CAST(Src.DeliveryHoliday AS STRING),        '') OR
      IFNULL(CAST(Tgt.SLA AS STRING),                    '') != IFNULL(CAST(Src.SLA AS STRING),                    '') OR
      IFNULL(CAST(Tgt.FirstImpactedDate AS STRING),      '') != IFNULL(CAST(Src.FirstImpactedDate AS STRING),      '') OR
      IFNULL(Tgt.FirstImpactedRF,                        '') != IFNULL(Src.FirstImpactedRF,                        '') OR
      IFNULL(Tgt.FirstImpactedCF,                        '') != IFNULL(Src.FirstImpactedCF,                        '') OR
      IFNULL(Tgt.FirstImpactedScanType,                  '') != IFNULL(Src.FirstImpactedScanType,                  '') OR
      IFNULL(Tgt.FirstImpactedScanStatus,                '') != IFNULL(Src.FirstImpactedScanStatus,                '') OR
      IFNULL(CAST(Tgt.FirstFutileDate AS STRING),        '') != IFNULL(CAST(Src.FirstFutileDate AS STRING),        '') OR
      IFNULL(Tgt.FirstFutileRF,                          '') != IFNULL(Src.FirstFutileRF,                          '') OR
      IFNULL(Tgt.FirstFutileCF,                          '') != IFNULL(Src.FirstFutileCF,                          '') OR
      IFNULL(Tgt.FirstFutileScanType,                    '') != IFNULL(Src.FirstFutileScanType,                    '') OR
      IFNULL(Tgt.FirstFutileScanStatus,                  '') != IFNULL(Src.FirstFutileScanStatus,                  '') OR
      IFNULL(CAST(Tgt.FirstReceivedOrFirstScanDate AS STRING), '') != IFNULL(CAST(COALESCE(Src.FirstReceivedDate, Src.FirstScanDate) AS STRING), '')
    )
    THEN UPDATE SET
      FirstScanDate                  = Src.FirstScanDate,
      FirstScanRF                    = Src.FirstScanRF,
      FirstScanCF                    = Src.FirstScanCF,
      FirstScanType                  = Src.FirstScanType,
      FirstScanStatus                = Src.FirstScanStatus,
      LastScanDate                   = Src.LastScanDate,
      LastScanRF                     = Src.LastScanRF,
      LastScanCF                     = Src.LastScanCF,
      LastScanType                   = Src.LastScanType,
      LastScanStatus                 = Src.LastScanStatus,
      FirstPscanDate                 = Src.FirstPscanDate,
      FirstPscanRF                   = Src.FirstPscanRF,
      FirstPscanCF                   = Src.FirstPscanCF,
      FirstPscanStatus               = Src.FirstPscanStatus,
      FirstDscanDate                 = Src.FirstDscanDate,
      FirstDscanRF                   = Src.FirstDscanRF,
      FirstDscanCF                   = Src.FirstDscanCF,
      FirstDscanStatus               = Src.FirstDscanStatus,
      FirstReceivedDate              = Src.FirstReceivedDate,
      FirstReceivedRF                = Src.FirstReceivedRF,
      FirstReceivedCF                = Src.FirstReceivedCF,
      FirstReceivedScanType          = Src.FirstReceivedScanType,
      FirstReceivedScanStatus        = Src.FirstReceivedScanStatus,
      LastReceivedDate               = Src.LastReceivedDate,
      LastReceivedRF                 = Src.LastReceivedRF,
      LastReceivedCF                 = Src.LastReceivedCF,
      LastReceivedScanType           = Src.LastReceivedScanType,
      LastReceivedScanStatus         = Src.LastReceivedScanStatus,
      FirstSortedDate                = Src.FirstSortedDate,
      FirstSortedRF                  = Src.FirstSortedRF,
      FirstSortedCF                  = Src.FirstSortedCF,
      FirstSortedScanType            = Src.FirstSortedScanType,
      FirstSortedScanStatus          = Src.FirstSortedScanStatus,
      LastSortedDate                 = Src.LastSortedDate,
      LastSortedRF                   = Src.LastSortedRF,
      LastSortedCF                   = Src.LastSortedCF,
      LastSortedScanType             = Src.LastSortedScanType,
      LastSortedScanStatus           = Src.LastSortedScanStatus,
      FirstDepartedDate              = Src.FirstDepartedDate,
      FirstDepartedRF                = Src.FirstDepartedRF,
      FirstDepartedCF                = Src.FirstDepartedCF,
      FirstDepartedScanType          = Src.FirstDepartedScanType,
      FirstDepartedScanStatus        = Src.FirstDepartedScanStatus,
      LastDepartedDate               = Src.LastDepartedDate,
      LastDepartedRF                 = Src.LastDepartedRF,
      LastDepartedCF                 = Src.LastDepartedCF,
      LastDepartedScanType           = Src.LastDepartedScanType,
      LastDepartedScanStatus         = Src.LastDepartedScanStatus,
      FirstArrivedDate               = Src.FirstArrivedDate,
      FirstArrivedRF                 = Src.FirstArrivedRF,
      FirstArrivedCF                 = Src.FirstArrivedCF,
      FirstArrivedScanType           = Src.FirstArrivedScanType,
      FirstArrivedScanStatus         = Src.FirstArrivedScanStatus,
      LastArrivedDate                = Src.LastArrivedDate,
      LastArrivedRF                  = Src.LastArrivedRF,
      LastArrivedCF                  = Src.LastArrivedCF,
      LastArrivedScanType            = Src.LastArrivedScanType,
      LastArrivedScanStatus          = Src.LastArrivedScanStatus,
      FirstOutDate                   = Src.FirstOutDate,
      FirstOutRF                     = Src.FirstOutRF,
      FirstOutCF                     = Src.FirstOutCF,
      FirstOutScanType               = Src.FirstOutScanType,
      FirstOutScanStatus             = Src.FirstOutScanStatus,
      LastOutDate                    = Src.LastOutDate,
      LastOutRF                      = Src.LastOutRF,
      LastOutCF                      = Src.LastOutCF,
      LastOutScanType                = Src.LastOutScanType,
      LastOutScanStatus              = Src.LastOutScanStatus,
      FirstStopDate                  = Src.FirstStopDate,
      FirstStopRF                    = Src.FirstStopRF,
      FirstStopCF                    = Src.FirstStopCF,
      FirstStopScanType              = Src.FirstStopScanType,
      FirstStopScanStatus            = Src.FirstStopScanStatus,
      LastStopDate                   = Src.LastStopDate,
      LastStopRF                     = Src.LastStopRF,
      LastStopCF                     = Src.LastStopCF,
      LastStopScanType               = Src.LastStopScanType,
      LastStopScanStatus             = Src.LastStopScanStatus,
      FirstDeliveryDate              = Src.FirstDeliveryDate,
      FirstDeliveryRF                = Src.FirstDeliveryRF,
      FirstDeliveryCF                = Src.FirstDeliveryCF,
      FirstDeliveryScanType          = Src.FirstDeliveryScanType,
      FirstDeliveryScanStatus        = Src.FirstDeliveryScanStatus,
      LastDeliveryDate               = Src.LastDeliveryDate,
      LastDeliveryRF                 = Src.LastDeliveryRF,
      LastDeliveryCF                 = Src.LastDeliveryCF,
      LastDeliveryScanType           = Src.LastDeliveryScanType,
      LastDeliveryScanStatus         = Src.LastDeliveryScanStatus,
      StopDays                       = Src.StopDays,
      StopHoliday                    = Src.StopHoliday,
      KPI                            = Src.KPI,
      SingleCycle                    = Src.SingleCycle,
      SubDepot                       = Src.SubDepot,
      DeliveryDays                   = Src.DeliveryDays,
      DeliveryHoliday                = Src.DeliveryHoliday,
      SLA                            = Src.SLA,
      Updated                        = v_Loaded,
      ProcessId                      = p_ProcessId,
      FirstImpactedDate              = Src.FirstImpactedDate,
      FirstImpactedRF                = Src.FirstImpactedRF,
      FirstImpactedCF                = Src.FirstImpactedCF,
      FirstImpactedScanType          = Src.FirstImpactedScanType,
      FirstImpactedScanStatus        = Src.FirstImpactedScanStatus,
      FirstFutileDate                = Src.FirstFutileDate,
      FirstFutileRF                  = Src.FirstFutileRF,
      FirstFutileCF                  = Src.FirstFutileCF,
      FirstFutileScanType            = Src.FirstFutileScanType,
      FirstFutileScanStatus          = Src.FirstFutileScanStatus,
      FirstReceivedOrFirstScanDate   = COALESCE(Src.FirstReceivedDate, Src.FirstScanDate);


INSERT INTO `prj-drgfly-prod-sp-01.validation_results.dbo_Fact_Scan_KPI_reloadWithTieBreaker`
    (
      LabelNo,
      FirstScanDate, FirstScanRF, FirstScanCF, FirstScanType, FirstScanStatus,
      LastScanDate, LastScanRF, LastScanCF, LastScanType, LastScanStatus,
      FirstPscanDate, FirstPscanRF, FirstPscanCF, FirstPscanStatus,
      FirstDscanDate, FirstDscanRF, FirstDscanCF, FirstDscanStatus,
      FirstReceivedDate, FirstReceivedRF, FirstReceivedCF, FirstReceivedScanType, FirstReceivedScanStatus,
      LastReceivedDate, LastReceivedRF, LastReceivedCF, LastReceivedScanType, LastReceivedScanStatus,
      FirstSortedDate, FirstSortedRF, FirstSortedCF, FirstSortedScanType, FirstSortedScanStatus,
      LastSortedDate, LastSortedRF, LastSortedCF, LastSortedScanType, LastSortedScanStatus,
      FirstDepartedDate, FirstDepartedRF, FirstDepartedCF, FirstDepartedScanType, FirstDepartedScanStatus,
      LastDepartedDate, LastDepartedRF, LastDepartedCF, LastDepartedScanType, LastDepartedScanStatus,
      FirstArrivedDate, FirstArrivedRF, FirstArrivedCF, FirstArrivedScanType, FirstArrivedScanStatus,
      LastArrivedDate, LastArrivedRF, LastArrivedCF, LastArrivedScanType, LastArrivedScanStatus,
      FirstOutDate, FirstOutRF, FirstOutCF, FirstOutScanType, FirstOutScanStatus,
      LastOutDate, LastOutRF, LastOutCF, LastOutScanType, LastOutScanStatus,
      FirstStopDate, FirstStopRF, FirstStopCF, FirstStopScanType, FirstStopScanStatus,
      LastStopDate, LastStopRF, LastStopCF, LastStopScanType, LastStopScanStatus,
      FirstDeliveryDate, FirstDeliveryRF, FirstDeliveryCF, FirstDeliveryScanType, FirstDeliveryScanStatus,
      LastDeliveryDate, LastDeliveryRF, LastDeliveryCF, LastDeliveryScanType, LastDeliveryScanStatus,
      StopDays, StopHoliday, KPI, SingleCycle, SubDepot,
      DeliveryDays, DeliveryHoliday, SLA,
      Created, Updated, ProcessId,
      FirstImpactedDate, FirstImpactedRF, FirstImpactedCF, FirstImpactedScanType, FirstImpactedScanStatus,
      FirstFutileDate, FirstFutileRF, FirstFutileCF, FirstFutileScanType, FirstFutileScanStatus,
      FirstReceivedOrFirstScanDate
    )
    SELECT
      Src.LabelNo,
      Src.FirstScanDate, Src.FirstScanRF, Src.FirstScanCF, Src.FirstScanType, Src.FirstScanStatus,
      Src.LastScanDate, Src.LastScanRF, Src.LastScanCF, Src.LastScanType, Src.LastScanStatus,
      Src.FirstPscanDate, Src.FirstPscanRF, Src.FirstPscanCF, Src.FirstPscanStatus,
      Src.FirstDscanDate, Src.FirstDscanRF, Src.FirstDscanCF, Src.FirstDscanStatus,
      Src.FirstReceivedDate, Src.FirstReceivedRF, Src.FirstReceivedCF, Src.FirstReceivedScanType, Src.FirstReceivedScanStatus,
      Src.LastReceivedDate, Src.LastReceivedRF, Src.LastReceivedCF, Src.LastReceivedScanType, Src.LastReceivedScanStatus,
      Src.FirstSortedDate, Src.FirstSortedRF, Src.FirstSortedCF, Src.FirstSortedScanType, Src.FirstSortedScanStatus,
      Src.LastSortedDate, Src.LastSortedRF, Src.LastSortedCF, Src.LastSortedScanType, Src.LastSortedScanStatus,
      Src.FirstDepartedDate, Src.FirstDepartedRF, Src.FirstDepartedCF, Src.FirstDepartedScanType, Src.FirstDepartedScanStatus,
      Src.LastDepartedDate, Src.LastDepartedRF, Src.LastDepartedCF, Src.LastDepartedScanType, Src.LastDepartedScanStatus,
      Src.FirstArrivedDate, Src.FirstArrivedRF, Src.FirstArrivedCF, Src.FirstArrivedScanType, Src.FirstArrivedScanStatus,
      Src.LastArrivedDate, Src.LastArrivedRF, Src.LastArrivedCF, Src.LastArrivedScanType, Src.LastArrivedScanStatus,
      Src.FirstOutDate, Src.FirstOutRF, Src.FirstOutCF, Src.FirstOutScanType, Src.FirstOutScanStatus,
      Src.LastOutDate, Src.LastOutRF, Src.LastOutCF, Src.LastOutScanType, Src.LastOutScanStatus,
      Src.FirstStopDate, Src.FirstStopRF, Src.FirstStopCF, Src.FirstStopScanType, Src.FirstStopScanStatus,
      Src.LastStopDate, Src.LastStopRF, Src.LastStopCF, Src.LastStopScanType, Src.LastStopScanStatus,
      Src.FirstDeliveryDate, Src.FirstDeliveryRF, Src.FirstDeliveryCF, Src.FirstDeliveryScanType, Src.FirstDeliveryScanStatus,
      Src.LastDeliveryDate, Src.LastDeliveryRF, Src.LastDeliveryCF, Src.LastDeliveryScanType, Src.LastDeliveryScanStatus,
      Src.StopDays, Src.StopHoliday, Src.KPI, Src.SingleCycle, Src.SubDepot,
      Src.DeliveryDays, Src.DeliveryHoliday, Src.SLA,
      v_Loaded,   -- Created
      v_Loaded,   -- Updated
      p_ProcessId,
      Src.FirstImpactedDate, Src.FirstImpactedRF, Src.FirstImpactedCF, Src.FirstImpactedScanType, Src.FirstImpactedScanStatus,
      Src.FirstFutileDate, Src.FirstFutileRF, Src.FirstFutileCF, Src.FirstFutileScanType, Src.FirstFutileScanStatus,
      COALESCE(Src.FirstReceivedDate, Src.FirstScanDate) AS FirstReceivedOrFirstScanDate
    FROM `prj-drgfly-prod-sp-01.validation_results.Staging_Fact_Scan_KPI_Stg_reloadWithTieBreaker` Src
    JOIN LabelsToProcess Sel ON Sel.LabelNo = Src.LabelNo
    WHERE Sel.InsertId IS NOT NULL;