CREATE OR REPLACE PROCEDURE `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.sp_load_Staging_tblCustomer_Stg`(
)
BEGIN
  INSERT INTO `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_tblCustomer_Stg`
  SELECT CustomerID
        ,CustomerNumber
        ,CountryCode
        ,createDate
        ,topCustomer
        ,CustomerName
        ,StreetAddress
        ,StreetAddress1
        ,AddressExtra
        ,Suburb
        ,PostCode
        ,City
        ,ContactName
        ,PhoneNumber
        ,MobileNumber
        ,FaxNumber
        ,EmailAddress
        ,FranchiseeCode
        ,CSAid
        ,pref_enable_Enquiry
        ,pref_SendAutoEmails
        ,FF_AuthorisedSendersType
        ,DeleteDate
        ,DeleteLog
        ,WebSettings_Banner
        ,WebSettings_CSS
        ,WebSettings_HomePage
        ,WebSettings_ContactUsPage
        ,GroupID
        ,PSC_FrequentPricing
        ,FastLabel_ClientID
        ,FF_CanBeInvoiced
        ,ElecLabelSystem
        ,ElecLabelCode
        ,GSTCode
        ,InvoiceNo_Last
        ,MaxDailyReprints
        ,PreferredCourierNo
        ,CAST(Bank_CurrentBalance AS NUMERIC) AS Bank_CurrentBalance
        ,CAST(Bank_AllowNegativeBalance AS INT64) AS Bank_AllowNegativeBalance
        ,CAST(FastLabel_AllowDynamicLabels AS INT64) AS FastLabel_AllowDynamicLabels
        ,FastLabel_EmailTemplateJSON
        ,CAST(FastLabel_EmailTemplateUse AS INT64) AS FastLabel_EmailTemplateUse
        ,RP_DefaultPaymentTypeID
        ,CAST(BudgetLabel_ReverseManifestingEnabled AS INT64) AS BudgetLabel_ReverseManifestingEnabled
        ,TrademeAccessToken
        ,TrademeAccessTokenSecret
        ,TrademeAccessTokenExpiresUTC
        ,CAST(GreenInvoice_Enabled AS INT64) AS GreenInvoice_Enabled
        ,CAST(FastLabel_EnableA4 AS INT64) AS FastLabel_EnableA4
        ,CAST(ElectronicLabels_ExportToFTP AS INT64) AS ElectronicLabels_ExportToFTP
        ,CAST(RPReturnsCustomer AS INT64) AS RPReturnsCustomer
        ,CAST(FastLabel_PrintPBarcode AS INT64) AS FastLabel_PrintPBarcode
        ,DynamicLabels_InvoiceLevel
        ,CAST(DynamicLabels_InvoiceEnabled AS INT64) AS DynamicLabels_InvoiceEnabled
        ,DyanmicLabels_InvoicePeriod
        ,FastLabel_MaxWeightDead
        ,FastLabel_MaxWeightCubic
        ,FastLabel_CubicMultiplier
        ,CAST(ElectronicLabels_ExportToFTP_Dynamic AS INT64) AS ElectronicLabels_ExportToFTP_Dynamic
        ,CAST(MinimumBalance AS NUMERIC) AS MinimumBalance
        ,CAST(Is_CustomerType_Frequent AS INT64) AS Is_CustomerType_Frequent
        ,ReturnUrl
        ,CAST(EnableTSSNZ AS INT64) AS EnableTSSNZ
        ,CAST(FastLabel_AllowPOBox AS INT64) AS FastLabel_AllowPOBox
        ,CAST(FastLabel_ConsToAutoImport AS INT64) AS FastLabel_ConsToAutoImport
        ,CAST(ElectronicLabels_ExportToFTP_OnlyWithReference AS INT64) AS ElectronicLabels_ExportToFTP_OnlyWithReference
        ,CAST(Service_Override_Enabled AS INT64) AS Service_Override_Enabled
        ,CAST(UseStreetAutoComplete AS INT64) AS UseStreetAutoComplete
        ,PSC_RFCode
        ,CAST(FastLabel_AllManifestsAreAuto AS INT64) AS FastLabel_AllManifestsAreAuto
        ,CAST(EnableDoubleBaseLabel AS INT64) AS EnableDoubleBaseLabel
        ,CAST(DLSReqScan AS INT64) AS DLSReqScan
        ,PSC_FlatRateLabel
        ,CAST(FastLabel_PrintReturnLabel_ANY AS INT64) AS FastLabel_PrintReturnLabel_ANY
        ,FastLabel_DynamicLabelsSystemId
        ,Undelivered_Labels_Report_LastReportDate
        ,Undelivered_Labels_Report_Span
        ,Undelivered_Labels_Report_Emails
        ,CAST(FastLabel_SendTextMessage AS INT64) AS FastLabel_SendTextMessage
        ,FastLabel_SendTextMessage_Message
        ,LabelAddressLineA
        ,LabelAddressLineB
        ,LabelAddressLineC
        ,LabelAddressLineD
        ,CAST(UseLabelAddressLines AS INT64) AS UseLabelAddressLines
        ,DefaultCostCenterID
        ,CAST(RunSheetTSection AS INT64) AS RunSheetTSection
        ,FMSCustomerID
        ,FastLabel_BillingType
        ,CAST(OneLabelPerPage AS INT64) AS OneLabelPerPage
        ,DLSScanType
        ,CAST(FastLabel_DynamicLabelsDeliveryRfGetsSale AS INT64) AS FastLabel_DynamicLabelsDeliveryRfGetsSale
        ,CAST(FtpExportImages AS INT64) AS FtpExportImages
        ,CAST(DynamicLabelLowerDLFee AS INT64) AS DynamicLabelLowerDLFee
        ,CAST(AutoCloseEnable AS INT64) AS AutoCloseEnable
        ,DLSEmailAddress
        ,BlackBayExpectedTriggerPoints
        ,BlackBayServiceTypes
        ,BlackBayDefaultNotificationType
        ,CAST(HideTranstasmanOriginCountryScans AS INT64) AS HideTranstasmanOriginCountryScans
        ,PaymentTrigger
        ,CAST(IsZoneBillingMatrix AS INT64) AS IsZoneBillingMatrix
        ,CAST(IsImpliedScanning AS INT64) AS IsImpliedScanning
        ,CAST(FastLabel_ShowWalletBalance AS INT64) AS FastLabel_ShowWalletBalance
        ,CAST(ExportParcelConnectFtp AS INT64) AS ExportParcelConnectFtp
        ,CAST(IsAramexAccount AS INT64) AS IsAramexAccount
        ,RpEmailTemplateId
        ,RpCustomSettingsJson
        ,CAST(PickupDashEmailWhenJobsCancelled AS INT64) AS PickupDashEmailWhenJobsCancelled
        ,ReceiverPaysReturnType
        ,RpDynamicLabelSystemId
        ,CAST(FastLabel_PreAuthorizedReturns AS INT64) AS FastLabel_PreAuthorizedReturns
        ,CAST(FastLabel_ReturnServiceEnabled AS INT64) AS FastLabel_ReturnServiceEnabled
        ,ReturnsDynamicLabelSystemId
        ,CustomFtpExportRulesJson
        ,ReturnsThirdPartyDynamicLabelSystemId
        ,CAST(IsNationalCustomer AS INT64) AS IsNationalCustomer
       ,CAST(TrackAndTrace_ShowEventsAuNz AS INT64) AS TrackAndTrace_ShowEventsAuNz
       ,CAST(ExportFTP_DescriptionToContactName_DScan AS INT64) AS ExportFTP_DescriptionToContactName_DScan
       ,CAST(ExportFTP_IncludePrivateScans AS INT64) AS ExportFTP_IncludePrivateScans
       ,CAST(ImportsAllocateToHdManifests AS INT64) AS ImportsAllocateToHdManifests
       ,FastLabelDefaultDeliveryService
       ,CAST(FastLabelSignatureRequiredServiceAllImports AS INT64) AS FastLabelSignatureRequiredServiceAllImports
    FROM `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_goku_silver.OnlineEnquiries_NEW_dbo_tblCustomer`
  ;

END;