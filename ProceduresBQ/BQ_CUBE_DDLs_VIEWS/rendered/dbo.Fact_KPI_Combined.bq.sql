CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI_Combined`
AS



SELECT * FROM
	 (SELECT 
             COALESCE(Interim.LabelNo, KPI.LabelNo) AS LabelNo
            ,COALESCE(Interim.CountryCode, KPI.CountryCode) AS CountryCode
            ,COALESCE(Interim.Category, KPI.Category) AS Category
            ,COALESCE(Interim.RealisedDate, KPI.RealisedDate) AS RealisedDate
            ,COALESCE(Interim.ServiceType, KPI.ServiceType) AS ServiceType
            ,COALESCE(Interim.SLA, KPI.SLA) AS SLA
            ,COALESCE(Interim.KPIPickup, KPI.KPIPickup) AS KPIPickup
            ,COALESCE(Interim.KPILEA, KPI.KPILEA) AS KPILEA
            ,COALESCE(Interim.KPIDelivery, KPI.KPIDelivery) AS KPIDelivery
            ,COALESCE(Interim.KPIPickupImpact, KPI.KPIPickupImpact) AS KPIPickupImpact
            ,COALESCE(Interim.KPILEAImpact, KPI.KPILEAImpact) AS KPILEAImpact
            ,COALESCE(Interim.KPIDeliveryImpact, KPI.KPIDeliveryImpact) AS KPIDeliveryImpact
            ,COALESCE(Interim.DueDate, KPI.DueDate) AS DueDate
            ,COALESCE(Interim.KPIDepartureDate, KPI.KPIDepartureDate) AS KPIDepartureDate
            ,COALESCE(Interim.KPIArrivalDate, KPI.KPIArrivalDate) AS KPIArrivalDate
            ,COALESCE(Interim.KPIAttemptedDate, KPI.KPIAttemptedDate) AS KPIAttemptedDate
            ,COALESCE(Interim.KPIAttemptedDateAdjust, KPI.KPIAttemptedDateAdjust) AS KPIAttemptedDateAdjust

            ,COALESCE(Interim.ActualDepartureDate, KPI.ActualDepartureDate) AS ActualDepartureDate
            ,COALESCE(Interim.ActualDepartureRF, KPI.ActualDepartureRF) AS ActualDepartureRF
            ,COALESCE(Interim.ActualDepartureCF, KPI.ActualDepartureCF) AS ActualDepartureCF
            ,COALESCE(Interim.ActualDepartureType, KPI.ActualDepartureType) AS ActualDepartureType
            ,COALESCE(Interim.ActualDepartureStatus, KPI.ActualDepartureStatus) AS ActualDepartureStatus
            ,COALESCE(Interim.ActualFirstArrivalDate, KPI.ActualFirstArrivalDate) AS ActualFirstArrivalDate
            ,COALESCE(Interim.ActualFirstArrivalRF, KPI.ActualFirstArrivalRF) AS ActualFirstArrivalRF
            ,COALESCE(Interim.ActualFirstArrivalCF, KPI.ActualFirstArrivalCF) AS ActualFirstArrivalCF
            ,COALESCE(Interim.ActualFirstArrivalType, KPI.ActualFirstArrivalType) AS ActualFirstArrivalType
            ,COALESCE(Interim.ActualFirstArrivalStatus, KPI.ActualFirstArrivalStatus) AS ActualFirstArrivalStatus
            ,COALESCE(Interim.ActualArrivalDate, KPI.ActualArrivalDate) AS ActualArrivalDate
            ,COALESCE(Interim.ActualArrivalRF, KPI.ActualArrivalRF) AS ActualArrivalRF
            ,COALESCE(Interim.ActualArrivalCF, KPI.ActualArrivalCF) AS ActualArrivalCF
            ,COALESCE(Interim.ActualArrivalType, KPI.ActualArrivalType) AS ActualArrivalType
            ,COALESCE(Interim.ActualArrivalStatus, KPI.ActualArrivalStatus) AS ActualArrivalStatus
            ,COALESCE(Interim.ActualAttemptedDate, KPI.ActualAttemptedDate) AS ActualAttemptedDate
            ,COALESCE(Interim.ActualAttemptedRF, KPI.ActualAttemptedRF) AS ActualAttemptedRF
            ,COALESCE(Interim.ActualAttemptedCF, KPI.ActualAttemptedCF) AS ActualAttemptedCF
            ,COALESCE(Interim.ActualAttemptedType, KPI.ActualAttemptedType) AS ActualAttemptedType
            ,COALESCE(Interim.ActualAttemptedStatus, KPI.ActualAttemptedStatus) AS ActualAttemptedStatus
            ,COALESCE(Interim.ActualDeliveryScanDate, KPI.ActualDeliveryScanDate) AS ActualDeliveryScanDate
            ,COALESCE(Interim.ActualDeliveryRF, KPI.ActualDeliveryRF) AS ActualDeliveryRF
            ,COALESCE(Interim.ActualDeliveryCF, KPI.ActualDeliveryCF) AS ActualDeliveryCF
            ,COALESCE(Interim.ActualDeliveryType, KPI.ActualDeliveryType) AS ActualDeliveryType
            ,COALESCE(Interim.ActualDeliveryStatus, KPI.ActualDeliveryStatus) AS ActualDeliveryStatus

            ,COALESCE(Interim.LastScanDate, KPI.LastScanDate) AS LastScanDate
            ,COALESCE(Interim.LastScanRF, KPI.LastScanRF) AS LastScanRF
            ,COALESCE(Interim.LastScanCF, KPI.LastScanCF) AS LastScanCF
            ,COALESCE(Interim.LastScanType, KPI.LastScanType) AS LastScanType
            ,COALESCE(Interim.LastScanStatus, KPI.LastScanStatus) AS LastScanStatus
            ,COALESCE(Interim.MISScanDate, KPI.MISScanDate) AS MISScanDate
            ,COALESCE(Interim.MISRF, KPI.MISRF) AS MISRF
            ,COALESCE(Interim.LastUpdated, KPI.LastUpdated) AS LastUpdated
            ,COALESCE(Interim.ProcessID, KPI.ProcessID) AS ProcessID            
		FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI_Interim` Interim

  FULL JOIN (
		SELECT LabelNo
			  ,CountryCode
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
		  FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI_Daily` 
		  
		) AS KPI ON KPI.LabelNo = Interim.LabelNo

) AS A
--WHERE LabelNo IN ('MS0006879213', 'MS0006871099')