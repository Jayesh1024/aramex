CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI_Combined`
AS



SELECT * FROM
	 (SELECT 
             COALESCE(fk.LabelNo, KPI.LabelNo) AS LabelNo
            ,COALESCE(fk.CountryCode, KPI.CountryCode) AS CountryCode
            ,COALESCE(fk.Category, KPI.Category) AS Category
            ,COALESCE(fk.RealisedDate, KPI.RealisedDate) AS RealisedDate
            ,COALESCE(fk.ServiceType, KPI.ServiceType) AS ServiceType
            ,COALESCE(fk.SLA, KPI.SLA) AS SLA
            ,COALESCE(fk.KPIPickup, KPI.KPIPickup) AS KPIPickup
            ,COALESCE(fk.KPILEA, KPI.KPILEA) AS KPILEA
            ,COALESCE(fk.KPIDelivery, KPI.KPIDelivery) AS KPIDelivery
            ,COALESCE(fk.KPIPickupImpact, KPI.KPIPickupImpact) AS KPIPickupImpact
            ,COALESCE(fk.KPILEAImpact, KPI.KPILEAImpact) AS KPILEAImpact
            ,COALESCE(fk.KPIDeliveryImpact, KPI.KPIDeliveryImpact) AS KPIDeliveryImpact
            ,COALESCE(fk.DueDate, KPI.DueDate) AS DueDate
            ,COALESCE(fk.KPIDepartureDate, KPI.KPIDepartureDate) AS KPIDepartureDate
            ,COALESCE(fk.KPIArrivalDate, KPI.KPIArrivalDate) AS KPIArrivalDate
            ,COALESCE(fk.KPIAttemptedDate, KPI.KPIAttemptedDate) AS KPIAttemptedDate
            ,COALESCE(fk.KPIAttemptedDateAdjust, KPI.KPIAttemptedDateAdjust) AS KPIAttemptedDateAdjust

            ,COALESCE(fk.ActualDepartureDate, KPI.ActualDepartureDate) AS ActualDepartureDate
            ,COALESCE(fk.ActualDepartureRF, KPI.ActualDepartureRF) AS ActualDepartureRF
            ,COALESCE(fk.ActualDepartureCF, KPI.ActualDepartureCF) AS ActualDepartureCF
            ,COALESCE(fk.ActualDepartureType, KPI.ActualDepartureType) AS ActualDepartureType
            ,COALESCE(fk.ActualDepartureStatus, KPI.ActualDepartureStatus) AS ActualDepartureStatus
            ,COALESCE(fk.ActualFirstArrivalDate, KPI.ActualFirstArrivalDate) AS ActualFirstArrivalDate
            ,COALESCE(fk.ActualFirstArrivalRF, KPI.ActualFirstArrivalRF) AS ActualFirstArrivalRF
            ,COALESCE(fk.ActualFirstArrivalCF, KPI.ActualFirstArrivalCF) AS ActualFirstArrivalCF
            ,COALESCE(fk.ActualFirstArrivalType, KPI.ActualFirstArrivalType) AS ActualFirstArrivalType
            ,COALESCE(fk.ActualFirstArrivalStatus, KPI.ActualFirstArrivalStatus) AS ActualFirstArrivalStatus
            ,COALESCE(fk.ActualArrivalDate, KPI.ActualArrivalDate) AS ActualArrivalDate
            ,COALESCE(fk.ActualArrivalRF, KPI.ActualArrivalRF) AS ActualArrivalRF
            ,COALESCE(fk.ActualArrivalCF, KPI.ActualArrivalCF) AS ActualArrivalCF
            ,COALESCE(fk.ActualArrivalType, KPI.ActualArrivalType) AS ActualArrivalType
            ,COALESCE(fk.ActualArrivalStatus, KPI.ActualArrivalStatus) AS ActualArrivalStatus
            ,COALESCE(fk.ActualAttemptedDate, KPI.ActualAttemptedDate) AS ActualAttemptedDate
            ,COALESCE(fk.ActualAttemptedRF, KPI.ActualAttemptedRF) AS ActualAttemptedRF
            ,COALESCE(fk.ActualAttemptedCF, KPI.ActualAttemptedCF) AS ActualAttemptedCF
            ,COALESCE(fk.ActualAttemptedType, KPI.ActualAttemptedType) AS ActualAttemptedType
            ,COALESCE(fk.ActualAttemptedStatus, KPI.ActualAttemptedStatus) AS ActualAttemptedStatus
            ,COALESCE(fk.ActualDeliveryScanDate, KPI.ActualDeliveryScanDate) AS ActualDeliveryScanDate
            ,COALESCE(fk.ActualDeliveryRF, KPI.ActualDeliveryRF) AS ActualDeliveryRF
            ,COALESCE(fk.ActualDeliveryCF, KPI.ActualDeliveryCF) AS ActualDeliveryCF
            ,COALESCE(fk.ActualDeliveryType, KPI.ActualDeliveryType) AS ActualDeliveryType
            ,COALESCE(fk.ActualDeliveryStatus, KPI.ActualDeliveryStatus) AS ActualDeliveryStatus

            ,COALESCE(fk.LastScanDate, KPI.LastScanDate) AS LastScanDate
            ,COALESCE(fk.LastScanRF, KPI.LastScanRF) AS LastScanRF
            ,COALESCE(fk.LastScanCF, KPI.LastScanCF) AS LastScanCF
            ,COALESCE(fk.LastScanType, KPI.LastScanType) AS LastScanType
            ,COALESCE(fk.LastScanStatus, KPI.LastScanStatus) AS LastScanStatus
            ,COALESCE(fk.MISScanDate, KPI.MISScanDate) AS MISScanDate
            ,COALESCE(fk.MISRF, KPI.MISRF) AS MISRF
            ,COALESCE(fk.LastUpdated, KPI.LastUpdated) AS LastUpdated
            ,COALESCE(fk.ProcessID, KPI.ProcessID) AS ProcessID            
		FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI` fk

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
		  
		) AS KPI ON KPI.LabelNo = fk.LabelNo

) AS A
--WHERE LabelNo IN ('MS0006879213', 'MS0006871099')