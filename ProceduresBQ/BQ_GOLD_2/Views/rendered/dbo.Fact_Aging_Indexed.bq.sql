CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Aging_Indexed`
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

 FROM   `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Scan_KPI_partitioned` AS k 
        INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_FactAgingControl` fc ON k.FirstScanDate >= fc.DateLimit1 AND k.FirstReceivedDate >= fc.DateLimit2 AND TargetName = 'FactAging1'
        INNER JOIN `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_RF` AS r  ON k.FirstReceivedRF = r.FranchiseeCode AND r.IsCurrent = 1