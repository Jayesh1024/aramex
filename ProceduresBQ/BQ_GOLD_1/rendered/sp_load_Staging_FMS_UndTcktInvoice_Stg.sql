CREATE OR REPLACE PROCEDURE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.sp_load_Staging_FMS_UndTcktInvoice_Stg`(
  LastDate DATETIME
)
BEGIN
  DECLARE StartDate DATETIME;

  SET StartDate = DATE_SUB(LastDate, INTERVAL 3 DAY);

  INSERT INTO `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_FMS_UndTcktInvoice_Stg`
  SELECT UnderTickId
        ,CountryId
        ,LoggedByRF
        ,UpdatedByRF
        ,PRF
        ,SaleRF
        ,Label
        ,CustomerId
        ,CustomerName
        ,SystemDeadWeight
        ,SystemLength
        ,SystemWidth
        ,SystemHeight
        ,SystemWeightCubic
        ,SystemPrice
        ,NewDeadWeight
        ,NewLength
        ,NewWidth
        ,NewHeight
        ,NewWeightCubic
        ,NewPrice
        ,FromAddress1
        ,FromAddress2
        ,FromAddress3
        ,FromAddress4
        ,FromAddress5
        ,FromAddress6
        ,ToAddress1
        ,ToAddress2
        ,ToAddress3
        ,ToAddress4
        ,ToAddress5
        ,ToAddress6
        ,Source
        ,Note
        ,Date
        ,UserIdRecorded
        ,BankedFMSCustomerId
        ,CAST(Procssed AS INT64) AS Procssed
        ,DeliveryRF
        ,NumberOfExcess
        ,NewExcessLabels
        ,CAST(RepricedAutomatically AS INT64) AS RepricedAutomatically
        ,FMSOriginalInvoiceNumber
        ,FMSBankedInvoiceAmount
        ,FMSCustomerInvoiceMonthlyBatch
        ,FMSCustomerInvoiceNumber
        ,FMSCustomerIdInvoiced
        ,FMSCustomerInvoiceAmount
        ,DLBSInvoiceMonthlyBatch
        ,DLBSInvoiceNumber
        ,DLBSInvoiceRFFrom
        ,DLBSInvoiceRFTo
        ,DLBSInvoiceAmount
        ,LeaMonthlyBatch
        ,LeaInvoiceNumber
        ,LeaChargeAmount
        ,CAST(Locked AS INT64) AS Locked
        ,CAST(Repriced AS INT64) AS Repriced
        ,InvoicePrice
        ,ExcessPrice
        ,CAST(Invoiced AS INT64) AS Invoiced
        ,NewPriceIncGST
        ,CAST(MultiplePriceOptions AS INT64) AS MultiplePriceOptions
        ,NewColour
        ,RCTIInvoiceNumber
        ,CAST(InvException AS INT64) AS InvException
        ,InvExceptionReason
        ,ToLng
        ,ToLat
        ,CAST(ChildCharge AS INT64) AS ChildCharge
  FROM `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_krillin_silver.Fastway_dbo_FMS_UndTcktInvoice`
  WHERE Date >= StartDate
  ;

END;