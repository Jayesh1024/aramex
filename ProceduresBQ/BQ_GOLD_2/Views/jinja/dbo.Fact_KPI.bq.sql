CREATE OR REPLACE VIEW `{{ project_id }}.{{ dataset_id }}.dbo_Fact_KPI`
AS
SELECT        LabelNo, CountryCode, Category, RealisedDate, ServiceType, SLA, KPIPickup, KPILEA, KPIDelivery, KPIPickupImpact, KPILEAImpact, KPIDeliveryImpact, DueDate, KPIDepartureDate, KPIArrivalDate, KPIAttemptedDate, 
                         KPIAttemptedDateAdjust, ActualDepartureDate, ActualDepartureRF, ActualDepartureCF, ActualDepartureType, ActualDepartureStatus, ActualFirstArrivalDate, ActualFirstArrivalRF, ActualFirstArrivalCF, ActualFirstArrivalType, 
                         ActualFirstArrivalStatus, ActualArrivalDate, ActualArrivalRF, ActualArrivalCF, ActualArrivalType, ActualArrivalStatus, ActualAttemptedDate, ActualAttemptedRF, ActualAttemptedCF, ActualAttemptedType, ActualAttemptedStatus, 
                         ActualDeliveryScanDate, ActualDeliveryRF, ActualDeliveryCF, ActualDeliveryType, ActualDeliveryStatus, LastScanDate, LastScanRF, LastScanCF, LastScanType, LastScanStatus, MISScanDate, MISRF, LastUpdated, 
                         ProcessID
FROM         `{{ project_id }}.{{ dataset_id }}.dbo_Fact_KPI_Daily`