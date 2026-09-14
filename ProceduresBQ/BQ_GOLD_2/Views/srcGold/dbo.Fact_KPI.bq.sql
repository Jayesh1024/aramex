CREATE OR REPLACE VIEW `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI`
AS
SELECT        LabelNo, CountryCode, Category, RealisedDate, ServiceType, SLA, KPIPickup, KPILEA, KPIDelivery, KPIPickupImpact, KPILEAImpact, KPIDeliveryImpact, DueDate, KPIDepartureDate, KPIArrivalDate, KPIAttemptedDate, 
                         KPIAttemptedDateAdjust, ActualDepartureDate, ActualDepartureRF, ActualDepartureCF, ActualDepartureType, ActualDepartureStatus, ActualFirstArrivalDate, ActualFirstArrivalRF, ActualFirstArrivalCF, ActualFirstArrivalType, 
                         ActualFirstArrivalStatus, ActualArrivalDate, ActualArrivalRF, ActualArrivalCF, ActualArrivalType, ActualArrivalStatus, ActualAttemptedDate, ActualAttemptedRF, ActualAttemptedCF, ActualAttemptedType, ActualAttemptedStatus, 
                         ActualDeliveryScanDate, ActualDeliveryRF, ActualDeliveryCF, ActualDeliveryType, ActualDeliveryStatus, LastScanDate, LastScanRF, LastScanCF, LastScanType, LastScanStatus, MISScanDate, MISRF, LastUpdated, 
                         ProcessID
FROM         `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI_Daily`