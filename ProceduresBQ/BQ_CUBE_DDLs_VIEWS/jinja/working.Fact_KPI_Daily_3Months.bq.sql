CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.working_Fact_KPI_Daily_3Months`
AS

SELECT K.LabelNo
      ,K.CountryCode
      ,Category
      ,RealisedDate
      ,ServiceType
      ,SLA
      ,KPIPickup
      ,KPILEA
      ,KPIDelivery
      ,KPIPickupImpact
      ,KPILEAImpact
      ,KPIDeliveryImpact
      ,DueDate
	  ,IF(Category = 'Interbranch',K2.DueDate2,k.DueDate) AS NewDueDate
      ,KPIDepartureDate
      ,KPIArrivalDate
      ,KPIAttemptedDate
      ,KPIAttemptedDateAdjust
      ,ActualDepartureDate
      ,ActualDepartureRF
      ,ActualDepartureCF
      ,ActualDepartureType
      ,ActualDepartureStatus
      ,ActualFirstArrivalDate
      ,ActualFirstArrivalRF
      ,ActualFirstArrivalCF
      ,ActualFirstArrivalType
      ,ActualFirstArrivalStatus
      ,ActualArrivalDate
      ,ActualArrivalRF
      ,ActualArrivalCF
      ,ActualArrivalType
      ,ActualArrivalStatus
      ,ActualAttemptedDate
      ,ActualAttemptedRF
      ,ActualAttemptedCF
      ,ActualAttemptedType
      ,ActualAttemptedStatus
      ,ActualDeliveryScanDate
      ,ActualDeliveryRF
      ,ActualDeliveryCF
      ,ActualDeliveryType
      ,ActualDeliveryStatus
      ,LastScanDate
      ,LastScanRF
      ,LastScanCF
      ,LastScanType
      ,LastScanStatus
      ,MISScanDate
      ,MISRF
      ,LastUpdated
      ,ProcessID
      ,CreatedOn
      ,OLD_KPIDelivery
      ,OnTimeDelivery
  FROM `{{ project_id }}.{{ dataset_id }}.working_Fact_KPI_Daily-3Months` K
  JOIN `{{ project_id }}.{{ dataset_id }}.working_Fact_KPI_Daily-3Months-NewDueDate` K2 ON K2.LabelNo = K.LabelNo
  WHERE K.CountryCode = 1