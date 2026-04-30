CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Fact_Aging_Indexed2`
AS
  SELECT
		 FirstScanDate,

         LabelNo,
         LastScanDate,
         LastScanRF,
         LastScanCF,
         LastScanType,
         LastScanStatus,

         FirstReceivedDate,
         FirstReceivedRF,
         FirstReceivedCF,
         FirstDepartedDate,
         FirstDepartedRF,

         LastDepartedDate,
         LastDepartedRF,
         FirstArrivedDate,
         FirstArrivedRF,

         LastArrivedDate, 
         LastArrivedRF,
         LastOutDate,
         LastOutRF,
         LastOutCF,
         LastSortedScanStatus,

		 FirstStopDate,
		 CountryCode,
		 FranchiseeCode,
         LEFT(LabelNo,1) AS LabelPrefix1,
         LEFT(LabelNo,2) AS LabelPrefix2

 FROM   `{{ project_id }}.{{ dataset_id }}.dbo_Fact_Scan_KPI` AS k 
        INNER JOIN `{{ project_id }}.{{ dataset_id }}.dbo_FactAgingControl` fc ON k.FirstScanDate >= fc.DateLimit1 AND k.FirstReceivedDate >= fc.DateLimit2 AND TargetName = 'FactAging1'
        INNER JOIN `{{ project_id }}.{{ dataset_id }}.dv_SAT_RF` AS r  ON k.FirstReceivedRF = r.FranchiseeCode AND r.IsCurrent = 1