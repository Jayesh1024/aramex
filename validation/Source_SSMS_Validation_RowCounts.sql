-- ============================================================================
-- FULL SCRIPT: Row counts from source SQL Server
--
-- Tables sourced from: val_v2 - Sheet1.csv
-- Filters: business/operational date columns ONLY (no ETL dates).
-- Tables without a business date get a full COUNT(*).
--
-- Date range: 2026-04-01 to 2026-05-31
-- IsCurrent: tables with IsCurrent column also filter WHERE IsCurrent = 1
-- All reads use WITH (READPAST) to skip locked rows.
-- Nothing is created on the server — only temp tables (#).
-- ============================================================================

SET NOCOUNT ON;

DECLARE @StartDate        DATE = '2026-04-01',
        @EndDateExclusive DATE = '2026-05-31';

CREATE TABLE #Results (
    SchemaName      NVARCHAR(128),
    TableName       NVARCHAR(128),
    FilterColumn    NVARCHAR(128),
    FilterApplied   NVARCHAR(3),
    [RowCount]        BIGINT,
    ErrorMessage    NVARCHAR(4000),
    queryUsed       NVARCHAR(MAX)
);

CREATE TABLE #Tables (
    Id              INT IDENTITY(1,1),
    SchemaName      NVARCHAR(128),
    TableName       NVARCHAR(128),
    FilterColumn    NVARCHAR(128),
    HasIsCurrent    BIT
);

INSERT INTO #Tables (SchemaName, TableName, FilterColumn, HasIsCurrent) VALUES
-- InterimStaging
('InterimStaging', 'TrackAndTraceData_SignatureAI_Stg', 'ScanDate', 0),
('InterimStaging', 'TrackAndTrace_Stg', 'ScanDate', 0),
-- Staging
('Staging', 'API_RF_AdHocLabel_AllocationHistory_Stg', 'DateAllocatedUTC', 0),
('Staging', 'API_RF_AdHocLabel_AllocationHistory_Stg_Weekly', 'DateAllocatedUTC', 0),
('Staging', 'BLK_ContainerManifestContents_Stg', 'ScanDate', 0),
('Staging', 'BLK_ContainerManifest_Stg', 'ActionDate', 0),
('Staging', 'BLK_Container_Stg', 'LastActionDate', 0),
('Staging', 'BLK_TransitManifestContents_stg', NULL, 0),
('Staging', 'BLK_TransitManifest_Stg', 'DateOpened', 0),
('Staging', 'CF_Productivity_Stg_AU', 'WorkDate', 0),
('Staging', 'CF_Productivity_Stg_NZ', 'WorkDate', 0),
('Staging', 'ConsignmentItem_Stg', 'CreatedOn', 0),
('Staging', 'Courier_Stg', NULL, 0),
('Staging', 'CustomerCommissionOverride_Stg', NULL, 0),
('Staging', 'CustomerLinks_Stg', NULL, 0),
('Staging', 'Ebay_Labels_Stg', 'OrderClosedDateUTC', 0),
('Staging', 'FMS_Customer_Stg', 'StartDate', 0),
('Staging', 'FMS_InvoiceBooks_Stg', NULL, 0),
('Staging', 'FMS_InvoiceHead_Stg', 'SystemDate', 0),
('Staging', 'FMS_InvoiceLines_Stg', 'InvoiceDateInvLine', 0),
('Staging', 'FMS_UndTcktInvoice_Stg', 'Date', 0),
('Staging', 'FWFastlabel_ClickAndCollect_Stg', 'CreatedOn', 0),
('Staging', 'Fact_KPI_Src_Stg', 'ScanDate', 0),
('Staging', 'Fact_KPI_Stg', 'RealisedDate', 0),
('Staging', 'Fact_Scan_KPI_Stg', 'LastScanDate', 0),
('Staging', 'Fact_Scan_Stg2', 'ScanDate', 0),
('Staging', 'Fact_Scan_Stg2_NZ', 'ScanDate', 0),
('Staging', 'FastwayLabels_Stg', NULL, 0),
('Staging', 'Franchisee_Stg', NULL, 0),
('Staging', 'HDManifests_Stg', NULL, 0),
('Staging', 'IFSCustomers_Stg', NULL, 0),
('Staging', 'KPI_Labels_Stg', NULL, 0),
('Staging', 'LA_RuralOnforwards_Stg', 'Date', 0),
('Staging', 'LNK_Scan_Stg', 'ScanDate', 0),
('Staging', 'LabelMaster_Stg', 'Distribution_Date', 0),
('Staging', 'Label_Address_Stg', NULL, 0),
('Staging', 'Label_Interbranch_Stg', 'InvoiceDate', 0),
('Staging', 'Label_Product_ServiceItem_Stg', 'FMSInvoiceDate', 0),
('Staging', 'Label_Product_ServiceItem_Stg_Interim', 'FMSInvoiceDate', 0),
('Staging', 'LoadControl', NULL, 0),
('Staging', 'LoadLog', NULL, 0),
('Staging', 'PickupRequest_AU_Stg', 'CollectionDate', 0),
('Staging', 'PickupRequest_NZ_Stg', 'CollectionDate', 0),
('Staging', 'PickupRequest_SA_Stg', 'CollectionDate', 0),
('Staging', 'PickupRequest_Stg', 'CollectionDate', 0),
('Staging', 'Product_ServiceCon_Stg', 'FMSInvoiceDate', 0),
('Staging', 'Product_Stg', NULL, 0),
('Staging', 'SAT_Label_Allocation_Stg', 'CreateDateLocal', 0),
('Staging', 'STK_RFProducts_Stg', NULL, 0),
('Staging', 'ScanStatus_Stg', NULL, 0),
('Staging', 'Scans_Stg', 'ScanDate', 0),
('Staging', 'fl_ConItemSrv_Stg', 'FMSInvoiceDate', 0),
('Staging', 'fl_ConItemSrv_Stg_Interim', 'FMSInvoiceDate', 0),
('Staging', 'fl_ConItem_Stg', 'FMSInvoiceDate', 0),
('Staging', 'fl_ConSrv_Stg', 'FMSInvoiceDate', 0),
('Staging', 'fl_InvoiceHeader_Stg', 'InvoiceDate', 0),
('Staging', 'fl_InvoicePayment_Stg', NULL, 0),
('Staging', 'fl_MF_Interim_Stg', 'RealisedDate', 0),
('Staging', 'fl_ServiceItem_Stg', NULL, 0),
('Staging', 'tblCustomer_Stg', 'Undelivered_Labels_Report_LastReportDate', 0),
('Staging', 'tblFastLabel_Consignment_Stg', 'DateConsumed', 0),
('Staging', 'tblOnlineEnquiry_RP_Stg', 'PickupDateLocal', 0),
-- dbo
('dbo', 'AmazonDomesticSLA', NULL, 0),
('dbo', 'AmazonInternationalSLA', NULL, 0),
('dbo', 'CF_Productivity_AU', 'WorkDate', 0),
('dbo', 'CF_Productivity_NZ', 'WorkDate', 0),
('dbo', 'ControlTarget', NULL, 0),
('dbo', 'Customer_Grouping', NULL, 0),
('dbo', 'DLBSInvoiceHeader', 'DeliveryRFInvoiceDate', 0),
('dbo', 'DLBSRFBatching', 'Date', 0),
('dbo', 'DLS_InvoiceRFHeader', 'PeriodStart', 0),
('dbo', 'Dim_Country', NULL, 0),
('dbo', 'Dim_Label', 'CreateDate', 0),
('dbo', 'Dim_Time', 'Calendar_Date', 0),
('dbo', 'FMS_UndTcktInvoice', 'Date', 0),
('dbo', 'FWFastlabel_ClickAndCollect', 'CreatedOn', 0),
('dbo', 'Fact_Delivery_Performance', 'DeliveryDate', 0),
('dbo', 'Fact_KPI_Daily', 'RealisedDate', 0),
('dbo', 'Fact_KPI_Daily_Priority', 'RealisedDate', 0),
('dbo', 'Fact_KPI_Delivery_Performance', 'DeliveryDate', 0),
('dbo', 'Fact_Scan_KPI', 'FirstScanDate', 0),
('dbo', 'KPIBulkCustomer', NULL, 0),
('dbo', 'KPIBulkLocalCustomer', NULL, 0),
('dbo', 'KPICodes', NULL, 0),
('dbo', 'KPICustomerMatrix', 'ValidFrom', 1),
('dbo', 'KPIExcludedDates', 'Date', 0),
('dbo', 'KPIExcludedLabels', NULL, 0),
('dbo', 'KPIGroupDet', NULL, 0),
('dbo', 'KPIGroupHead', NULL, 0),
('dbo', 'KPIMatrix', NULL, 0),
('dbo', 'KPIPickupCutoffs', NULL, 0),
('dbo', 'KPIRate', 'DateBOM', 0),
('dbo', 'KPIScanGroups', NULL, 0),
('dbo', 'LocalKPIMatrix', NULL, 0),
('dbo', 'NonLocalKPIMatrix', NULL, 0),
('dbo', 'PLBSInvoiceHeader', 'PickupRFInvoiceDate', 0),
('dbo', 'Payzone_Agents', NULL, 0),
('dbo', 'Payzone_Regions', NULL, 0),
('dbo', 'Product_Grouping', NULL, 0),
('dbo', 'ProformaInvoices', NULL, 0),
('dbo', 'SPK_SprinklRTickets', 'CreatedDate', 0),
('dbo', 'SubDepot_Grouping', NULL, 0),
('dbo', 'TSS_PostCodeMaster', NULL, 0),
('dbo', 'Tssdetail', NULL, 0),
('dbo', 'fl_CustomerLabelAliasScannedNoCon', NULL, 0),
('dbo', 'fl_CustomerZoneOverrideHeader', 'FromDate', 0),
('dbo', 'fl_CustomerZoneOverrides', NULL, 0),
('dbo', 'fl_CustomerZoneSatchelOverrides', NULL, 0),
('dbo', 'fl_PriceListZones', NULL, 0),
('dbo', 'fl_PriceLists', NULL, 0),
-- dv
('dv', 'AgingExcludedLabels', NULL, 0),
('dv', 'HUB_Address', NULL, 0),
('dv', 'HUB_CF', NULL, 0),
('dv', 'HUB_Customer', NULL, 0),
('dv', 'HUB_Invoice', NULL, 0),
('dv', 'HUB_Label', NULL, 0),
('dv', 'HUB_Product', NULL, 0),
('dv', 'HUB_RF', NULL, 0),
('dv', 'HUB_ScanStatus', NULL, 0),
('dv', 'HUB_ServiceItem', NULL, 0),
('dv', 'LNK_InvoiceLine', NULL, 0),
('dv', 'LNK_Invoice_Label', NULL, 0),
('dv', 'LNK_Label_Address', NULL, 0),
('dv', 'LNK_Label_Product_ServiceItem', NULL, 0),
('dv', 'LNK_Product_ServiceCon', NULL, 0),
('dv', 'LNK_RFBatchingInvoiceLog', 'InvoiceDate', 0),
('dv', 'LNK_RuralOnforwards', 'CreatedDate', 0),
('dv', 'LNK_Scan', 'ScanDate', 0),
('dv', 'LNK_Scan_Signature', NULL, 0),
('dv', 'LNK_Scan_SignatureAI', 'ScanDate', 0),
('dv', 'LSAT_FL_InvoiceHeader', 'InvoiceDate', 0),
('dv', 'LSAT_FL_InvoicePayment', NULL, 0),
('dv', 'LSAT_InvoiceHead', 'EnteredDate', 0),
('dv', 'LSAT_InvoiceLine', 'InvoiceDateInvLine', 0),
('dv', 'LSAT_Label_Interbranch', 'InvoiceDate', 0),
('dv', 'LSAT_Label_Product_ServiceItem', 'CreatedOn', 1),
('dv', 'LSAT_Product_ServiceCon', 'CreatedOn', 1),
('dv', 'SAL_Customer', NULL, 0),
('dv', 'SAT_Address', 'ValidFrom', 1),
('dv', 'SAT_Assura_AffectedPerson', NULL, 0),
('dv', 'SAT_Assura_EventDetail', 'EventDateTime', 0),
('dv', 'SAT_BLKContainer', 'LastActionDate', 0),
('dv', 'SAT_BLKContainerManifest', 'ActionDate', 0),
('dv', 'SAT_BLKContainerManifestContents', 'ScanDate', 0),
('dv', 'SAT_BLKTransitManifest', 'DateOpened', 0),
('dv', 'SAT_BLKTransitManifestContents', NULL, 0),
('dv', 'SAT_CF', 'ValidFrom', 1),
('dv', 'SAT_Customer', 'StartDate', 1),
('dv', 'SAT_CustomerCommissionOverride', NULL, 0),
('dv', 'SAT_Customer_OES', 'Undelivered_Labels_Report_LastReportDate', 0),
('dv', 'SAT_FL_PriceListCustomerOverride', NULL, 0),
('dv', 'SAT_FL_ServiceZoneOverride', NULL, 0),
('dv', 'SAT_FL_Zones', NULL, 0),
('dv', 'SAT_Label_Allocation', 'CreateDateLocal', 1),
('dv', 'SAT_Label_Allocation_DL', 'CreateDateLocal', 1),
('dv', 'SAT_Label_Allocation_EBAY', 'CreateDateUTC', 1),
('dv', 'SAT_Label_Allocation_FL', 'CreateDate', 1),
('dv', 'SAT_Label_Allocation_FLE', 'ValidFrom', 1),
('dv', 'SAT_Label_Allocation_IFS', 'DateInserted', 1),
('dv', 'SAT_Label_Allocation_MF', 'CreatedOn', 1),
('dv', 'SAT_Label_Allocation_RP', 'CreateDateUTC', 1),
('dv', 'SAT_Label_Distribution', 'Distribution_Date', 1),
('dv', 'SAT_Label_PickupRequest', 'CollectionDate', 0),
('dv', 'SAT_Product', 'ValidFrom', 1),
('dv', 'SAT_RF', 'ValidFrom', 1),
('dv', 'SAT_STK_RFProducts', NULL, 0),
('dv', 'SAT_ScanStatus', 'ValidFrom', 1);

DECLARE @i INT = 1, @MaxId INT, @Schema NVARCHAR(128), @Table NVARCHAR(128),
        @Filter NVARCHAR(128), @HasIsCurrent BIT, @SQL NVARCHAR(MAX), @Cnt BIGINT, @ErrMsg NVARCHAR(4000);

SELECT @MaxId = MAX(Id) FROM #Tables;

WHILE @i <= @MaxId
BEGIN
    SELECT @Schema = SchemaName, @Table = TableName, @Filter = FilterColumn, @HasIsCurrent = HasIsCurrent
    FROM #Tables WHERE Id = @i;

    SET @Cnt = NULL;
    SET @ErrMsg = NULL;

    BEGIN TRY
        IF @Filter IS NOT NULL AND @HasIsCurrent = 1
        BEGIN
            SET @SQL = N'SELECT @RowCount = COUNT(*) '
                     + N'FROM ' + QUOTENAME(@Schema) + N'.' + QUOTENAME(@Table) + N' WITH (READPAST) '
                     + N'WHERE ' + QUOTENAME(@Filter) + N' >= @SD AND ' + QUOTENAME(@Filter) + N' <= @ED AND [IsCurrent] = 1;';
            EXEC sp_executesql @SQL, N'@RowCount BIGINT OUTPUT, @SD DATE, @ED DATE',
                 @RowCount = @Cnt OUTPUT, @SD = @StartDate, @ED = @EndDateExclusive;
        END
        ELSE IF @Filter IS NOT NULL
        BEGIN
            SET @SQL = N'SELECT @RowCount = COUNT(*) '
                     + N'FROM ' + QUOTENAME(@Schema) + N'.' + QUOTENAME(@Table) + N' WITH (READPAST) '
                     + N'WHERE ' + QUOTENAME(@Filter) + N' >= @SD AND ' + QUOTENAME(@Filter) + N' <= @ED;';
            EXEC sp_executesql @SQL, N'@RowCount BIGINT OUTPUT, @SD DATE, @ED DATE',
                 @RowCount = @Cnt OUTPUT, @SD = @StartDate, @ED = @EndDateExclusive;
        END
        ELSE IF @HasIsCurrent = 1
        BEGIN
            SET @SQL = N'SELECT @RowCount = COUNT(*) '
                     + N'FROM ' + QUOTENAME(@Schema) + N'.' + QUOTENAME(@Table) + N' WITH (READPAST) '
                     + N'WHERE [IsCurrent] = 1;';
            EXEC sp_executesql @SQL, N'@RowCount BIGINT OUTPUT', @RowCount = @Cnt OUTPUT;
        END
        ELSE
        BEGIN
            SET @SQL = N'SELECT @RowCount = COUNT(*) '
                     + N'FROM ' + QUOTENAME(@Schema) + N'.' + QUOTENAME(@Table) + N' WITH (READPAST);';
            EXEC sp_executesql @SQL, N'@RowCount BIGINT OUTPUT', @RowCount = @Cnt OUTPUT;
        END
    END TRY
    BEGIN CATCH
        SET @ErrMsg = ERROR_MESSAGE();
    END CATCH

    INSERT INTO #Results (SchemaName, TableName, FilterColumn, FilterApplied, [RowCount], ErrorMessage, queryUsed)
    VALUES (@Schema, @Table, ISNULL(@Filter, 'N/A'),
            CASE WHEN @Filter IS NOT NULL THEN 'Yes' ELSE 'No' END, @Cnt, @ErrMsg, @SQL);
    
    SELECT @Schema, @Table, @Filter, @Cnt, @ErrMsg, @SQL;

    SET @i = @i + 1;
END

SELECT SchemaName AS [Schema], TableName AS [Table], FilterColumn AS [Filter Column],
       FilterApplied AS [Filter Applied], ISNULL([RowCount], 0) AS [Row Count],
       ISNULL(ErrorMessage, '') AS [Error], queryUsed
FROM #Results ORDER BY SchemaName, TableName;

DROP TABLE #Results;
DROP TABLE #Tables;
