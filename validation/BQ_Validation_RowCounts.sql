-- ============================================================================
-- FULL SCRIPT: Row counts from BigQuery
--
-- Tables sourced from: val_v2 - Sheet1.csv
-- BQ table names sourced from: Cube tables mapping - Sheet1.csv
-- Project: prj-drgfly-prod-sp-01
--
-- Filters: business/operational date columns ONLY (no ETL dates).
-- Tables without a business date get a full COUNT(*).
-- Date range: 2026-04-01 to 2026-05-31
-- IsCurrent: tables with IsCurrent column also filter WHERE IsCurrent = 1
-- ============================================================================

DECLARE StartDate STRING DEFAULT '2026-04-01';
DECLARE EndDateExclusive STRING DEFAULT '2026-05-31';
DECLARE i INT64 DEFAULT 0;
DECLARE max_id INT64;
DECLARE bq_table STRING;
DECLARE filter_col STRING;
DECLARE has_is_current BOOL;
DECLARE schema_name STRING;
DECLARE table_name STRING;
DECLARE dyn_sql STRING;
DECLARE row_cnt INT64;

CREATE OR REPLACE TEMP TABLE _Tables (
    Id INT64, SchemaName STRING, TableName STRING, BQTable STRING, FilterColumn STRING, HasIsCurrent BOOL
);

CREATE OR REPLACE TEMP TABLE _Results (
    SchemaName STRING, TableName STRING, FilterColumn STRING,
    FilterApplied STRING, RowCount INT64, ErrorMessage STRING,
    queryUsed STRING
);

INSERT INTO _Tables (Id, SchemaName, TableName, BQTable, FilterColumn, HasIsCurrent) VALUES
-- InterimStaging
(1, 'InterimStaging', 'TrackAndTraceData_SignatureAI_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.InterimStaging_TrackAndTraceData_SignatureAI_Stg', 'ScanDate', FALSE),
(2, 'InterimStaging', 'TrackAndTrace_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.InterimStaging_TrackAndTrace_Stg', 'ScanDate', FALSE),
-- Staging
(3, 'Staging', 'API_RF_AdHocLabel_AllocationHistory_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_API_RF_AdHocLabel_AllocationHistory_Stg', 'DateAllocatedUTC', FALSE),
(4, 'Staging', 'API_RF_AdHocLabel_AllocationHistory_Stg_Weekly', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_API_RF_AdHocLabel_AllocationHistory_Stg_Weekly', 'DateAllocatedUTC', FALSE),
(5, 'Staging', 'BLK_ContainerManifestContents_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_BLK_ContainerManifestContents_Stg', 'ScanDate', FALSE),
(6, 'Staging', 'BLK_ContainerManifest_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_BLK_ContainerManifest_Stg', 'ActionDate', FALSE),
(7, 'Staging', 'BLK_Container_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_BLK_Container_Stg', 'LastActionDate', FALSE),
(8, 'Staging', 'BLK_TransitManifestContents_stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_BLK_TransitManifestContents_stg', NULL, FALSE),
(9, 'Staging', 'BLK_TransitManifest_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_BLK_TransitManifest_Stg', 'DateOpened', FALSE),
(10, 'Staging', 'CF_Productivity_Stg_AU', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CF_Productivity_Stg_AU', 'WorkDate', FALSE),
(11, 'Staging', 'CF_Productivity_Stg_NZ', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CF_Productivity_Stg_NZ', 'WorkDate', FALSE),
(12, 'Staging', 'ConsignmentItem_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_ConsignmentItem_Stg', 'CreatedOn', FALSE),
(13, 'Staging', 'Courier_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Courier_Stg', NULL, FALSE),
(14, 'Staging', 'CustomerCommissionOverride_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CustomerCommissionOverride_Stg', NULL, FALSE),
(15, 'Staging', 'CustomerLinks_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_CustomerLinks_Stg', NULL, FALSE),
(16, 'Staging', 'Ebay_Labels_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Ebay_Labels_Stg', 'OrderClosedDateUTC', FALSE),
(17, 'Staging', 'FMS_Customer_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_FMS_Customer_Stg', 'StartDate', FALSE),
(18, 'Staging', 'FMS_InvoiceBooks_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_FMS_InvoiceBooks_Stg', NULL, FALSE),
(19, 'Staging', 'FMS_InvoiceHead_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_FMS_InvoiceHead_Stg', 'SystemDate', FALSE),
(20, 'Staging', 'FMS_InvoiceLines_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_FMS_InvoiceLines_Stg', 'InvoiceDateInvLine', FALSE),
(21, 'Staging', 'FMS_UndTcktInvoice_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_FMS_UndTcktInvoice_Stg', 'Date', FALSE),
(22, 'Staging', 'FWFastlabel_ClickAndCollect_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_FWFastlabel_ClickAndCollect_Stg', 'CreatedOn', FALSE),
(23, 'Staging', 'Fact_KPI_Src_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_KPI_Src_Stg', 'ScanDate', FALSE),
(24, 'Staging', 'Fact_KPI_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_KPI_Stg', 'RealisedDate', FALSE),
(25, 'Staging', 'Fact_Scan_KPI_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_KPI_Stg', 'LastScanDate', FALSE),
(26, 'Staging', 'Fact_Scan_Stg2', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_Stg2', 'ScanDate', FALSE),
(27, 'Staging', 'Fact_Scan_Stg2_NZ', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Fact_Scan_Stg2_NZ', 'ScanDate', FALSE),
(28, 'Staging', 'FastwayLabels_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_FastwayLabels_Stg', NULL, FALSE),
(29, 'Staging', 'Franchisee_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Franchisee_Stg', NULL, FALSE),
(30, 'Staging', 'HDManifests_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_HDManifests_Stg', NULL, FALSE),
(31, 'Staging', 'IFSCustomers_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_IFSCustomers_Stg', NULL, FALSE),
(32, 'Staging', 'KPI_Labels_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_KPI_Labels_Stg', NULL, FALSE),
(33, 'Staging', 'LA_RuralOnforwards_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_LA_RuralOnforwards_Stg', 'Date', FALSE),
(34, 'Staging', 'LNK_Scan_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_LNK_Scan_Stg', 'ScanDate', FALSE),
(35, 'Staging', 'LabelMaster_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_LabelMaster_Stg', 'Distribution_Date', FALSE),
(36, 'Staging', 'Label_Address_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Label_Address_Stg', NULL, FALSE),
(37, 'Staging', 'Label_Interbranch_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Label_Interbranch_Stg', 'InvoiceDate', FALSE),
(38, 'Staging', 'Label_Product_ServiceItem_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Label_Product_ServiceItem_Stg', 'FMSInvoiceDate', FALSE),
(39, 'Staging', 'Label_Product_ServiceItem_Stg_Interim', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Label_Product_ServiceItem_Stg_Interim', 'FMSInvoiceDate', FALSE),
(40, 'Staging', 'LoadControl', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_LoadControl', NULL, FALSE),
(41, 'Staging', 'LoadLog', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_LoadLog', NULL, FALSE),
(42, 'Staging', 'PickupRequest_AU_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_PickupRequest_AU_Stg', 'CollectionDate', FALSE),
(43, 'Staging', 'PickupRequest_NZ_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_PickupRequest_NZ_Stg', 'CollectionDate', FALSE),
(44, 'Staging', 'PickupRequest_SA_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_PickupRequest_SA_Stg', 'CollectionDate', FALSE),
(45, 'Staging', 'PickupRequest_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_PickupRequest_Stg', 'CollectionDate', FALSE),
(46, 'Staging', 'Product_ServiceCon_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Product_ServiceCon_Stg', 'FMSInvoiceDate', FALSE),
(47, 'Staging', 'Product_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Product_Stg', NULL, FALSE),
(48, 'Staging', 'SAT_Label_Allocation_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_SAT_Label_Allocation_Stg', 'CreateDateLocal', FALSE),
(49, 'Staging', 'STK_RFProducts_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_STK_RFProducts_Stg', NULL, FALSE),
(50, 'Staging', 'ScanStatus_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_ScanStatus_Stg', NULL, FALSE),
(51, 'Staging', 'Scans_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_Scans_Stg', 'ScanDate', FALSE),
(52, 'Staging', 'fl_ConItemSrv_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_fl_ConItemSrv_Stg', 'FMSInvoiceDate', FALSE),
(53, 'Staging', 'fl_ConItemSrv_Stg_Interim', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_fl_ConItemSrv_Stg_Interim', 'FMSInvoiceDate', FALSE),
(54, 'Staging', 'fl_ConItem_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_fl_ConItem_Stg', 'FMSInvoiceDate', FALSE),
(55, 'Staging', 'fl_ConSrv_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_fl_ConSrv_Stg', 'FMSInvoiceDate', FALSE),
(56, 'Staging', 'fl_InvoiceHeader_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_fl_InvoiceHeader_Stg', 'InvoiceDate', FALSE),
(57, 'Staging', 'fl_InvoicePayment_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_fl_InvoicePayment_Stg', NULL, FALSE),
(58, 'Staging', 'fl_MF_Interim_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_fl_MF_Interim_Stg', 'RealisedDate', FALSE),
(59, 'Staging', 'fl_ServiceItem_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_fl_ServiceItem_Stg', NULL, FALSE),
(60, 'Staging', 'tblCustomer_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_tblCustomer_Stg', 'Undelivered_Labels_Report_LastReportDate', FALSE),
(61, 'Staging', 'tblFastLabel_Consignment_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_tblFastLabel_Consignment_Stg', 'DateConsumed', FALSE),
(62, 'Staging', 'tblOnlineEnquiry_RP_Stg', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.Staging_tblOnlineEnquiry_RP_Stg', 'PickupDateLocal', FALSE),
-- dbo
(63, 'dbo', 'AmazonDomesticSLA', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_AmazonDomesticSLA', NULL, FALSE),
(64, 'dbo', 'AmazonInternationalSLA', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_AmazonInternationalSLA', NULL, FALSE),
(65, 'dbo', 'CF_Productivity_AU', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_CF_Productivity_AU', 'WorkDate', FALSE),
(66, 'dbo', 'CF_Productivity_NZ', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_CF_Productivity_NZ', 'WorkDate', FALSE),
(67, 'dbo', 'ControlTarget', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_ControlTarget', NULL, FALSE),
(68, 'dbo', 'Customer_Grouping', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Customer_Grouping', NULL, FALSE),
(69, 'dbo', 'DLBSInvoiceHeader', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_DLBSInvoiceHeader', 'DeliveryRFInvoiceDate', FALSE),
(70, 'dbo', 'DLBSRFBatching', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_DLBSRFBatching', 'Date', FALSE),
(71, 'dbo', 'DLS_InvoiceRFHeader', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_DLS_InvoiceRFHeader', 'PeriodStart', FALSE),
(72, 'dbo', 'Dim_Country', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Country', NULL, FALSE),
(73, 'dbo', 'Dim_Label', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Label', 'CreateDate', FALSE),
(74, 'dbo', 'Dim_Time', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Dim_Time', 'Calendar_Date', FALSE),
(75, 'dbo', 'FMS_UndTcktInvoice', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_FMS_UndTcktInvoice', 'Date', FALSE),
(76, 'dbo', 'FWFastlabel_ClickAndCollect', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_FWFastlabel_ClickAndCollect', 'CreatedOn', FALSE),
(77, 'dbo', 'Fact_Delivery_Performance', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Delivery_Performance', 'DeliveryDate', FALSE),
(78, 'dbo', 'Fact_KPI_Daily', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI_Daily', 'RealisedDate', FALSE),
(79, 'dbo', 'Fact_KPI_Daily_Priority', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI_Daily_Priority', 'RealisedDate', FALSE),
(80, 'dbo', 'Fact_KPI_Delivery_Performance', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_KPI_Delivery_Performance', 'DeliveryDate', FALSE),
(81, 'dbo', 'Fact_Scan_KPI', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Fact_Scan_KPI', 'FirstScanDate', FALSE),
(82, 'dbo', 'KPIBulkCustomer', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIBulkCustomer', NULL, FALSE),
(83, 'dbo', 'KPIBulkLocalCustomer', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIBulkLocalCustomer', NULL, FALSE),
(84, 'dbo', 'KPICodes', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPICodes', NULL, FALSE),
(85, 'dbo', 'KPICustomerMatrix', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPICustomerMatrix', 'ValidFrom', TRUE),
(86, 'dbo', 'KPIExcludedDates', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIExcludedDates', 'Date', FALSE),
(87, 'dbo', 'KPIExcludedLabels', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIExcludedLabels', NULL, FALSE),
(88, 'dbo', 'KPIGroupDet', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIGroupDet', NULL, FALSE),
(89, 'dbo', 'KPIGroupHead', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIGroupHead', NULL, FALSE),
(90, 'dbo', 'KPIMatrix', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIMatrix', NULL, FALSE),
(91, 'dbo', 'KPIPickupCutoffs', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIPickupCutoffs', NULL, FALSE),
(92, 'dbo', 'KPIRate', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIRate', 'DateBOM', FALSE),
(93, 'dbo', 'KPIScanGroups', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_KPIScanGroups', NULL, FALSE),
(94, 'dbo', 'LocalKPIMatrix', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_LocalKPIMatrix', NULL, FALSE),
(95, 'dbo', 'NonLocalKPIMatrix', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_NonLocalKPIMatrix', NULL, FALSE),
(96, 'dbo', 'PLBSInvoiceHeader', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_PLBSInvoiceHeader', 'PickupRFInvoiceDate', FALSE),
(97, 'dbo', 'Payzone_Agents', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Payzone_Agents', NULL, FALSE),
(98, 'dbo', 'Payzone_Regions', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Payzone_Regions', NULL, FALSE),
(99, 'dbo', 'Product_Grouping', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Product_Grouping', NULL, FALSE),
(100, 'dbo', 'ProformaInvoices', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_ProformaInvoices', NULL, FALSE),
(101, 'dbo', 'SPK_SprinklRTickets', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_SPK_SprinklRTickets', 'CreatedDate', FALSE),
(102, 'dbo', 'SubDepot_Grouping', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_SubDepot_Grouping', NULL, FALSE),
(103, 'dbo', 'TSS_PostCodeMaster', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_TSS_PostCodeMaster', NULL, FALSE),
(104, 'dbo', 'Tssdetail', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_Tssdetail', NULL, FALSE),
(105, 'dbo', 'fl_CustomerLabelAliasScannedNoCon', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_fl_CustomerLabelAliasScannedNoCon', NULL, FALSE),
(106, 'dbo', 'fl_CustomerZoneOverrideHeader', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_fl_CustomerZoneOverrideHeader', 'FromDate', FALSE),
(107, 'dbo', 'fl_CustomerZoneOverrides', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_fl_CustomerZoneOverrides', NULL, FALSE),
(108, 'dbo', 'fl_CustomerZoneSatchelOverrides', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_fl_CustomerZoneSatchelOverrides', NULL, FALSE),
(109, 'dbo', 'fl_PriceListZones', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_fl_PriceListZones', NULL, FALSE),
(110, 'dbo', 'fl_PriceLists', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dbo_fl_PriceLists', NULL, FALSE),
-- dv
(111, 'dv', 'AgingExcludedLabels', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_AgingExcludedLabels', NULL, FALSE),
(112, 'dv', 'HUB_Address', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_Address', NULL, FALSE),
(113, 'dv', 'HUB_CF', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_CF', NULL, FALSE),
(114, 'dv', 'HUB_Customer', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_Customer', NULL, FALSE),
(115, 'dv', 'HUB_Invoice', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_Invoice', NULL, FALSE),
(116, 'dv', 'HUB_Label', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_Label', NULL, FALSE),
(117, 'dv', 'HUB_Product', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_Product', NULL, FALSE),
(118, 'dv', 'HUB_RF', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_RF', NULL, FALSE),
(119, 'dv', 'HUB_ScanStatus', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_ScanStatus', NULL, FALSE),
(120, 'dv', 'HUB_ServiceItem', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_HUB_ServiceItem', NULL, FALSE),
(121, 'dv', 'LNK_InvoiceLine', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_InvoiceLine', NULL, FALSE),
(122, 'dv', 'LNK_Invoice_Label', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Invoice_Label', NULL, FALSE),
(123, 'dv', 'LNK_Label_Address', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Label_Address', NULL, FALSE),
(124, 'dv', 'LNK_Label_Product_ServiceItem', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Label_Product_ServiceItem', NULL, FALSE),
(125, 'dv', 'LNK_Product_ServiceCon', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Product_ServiceCon', NULL, FALSE),
(126, 'dv', 'LNK_RFBatchingInvoiceLog', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_RFBatchingInvoiceLog', 'InvoiceDate', FALSE),
(127, 'dv', 'LNK_RuralOnforwards', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_RuralOnforwards', 'CreatedDate', FALSE),
(128, 'dv', 'LNK_Scan', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Scan', 'ScanDate', FALSE),
(129, 'dv', 'LNK_Scan_Signature', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Scan_Signature', NULL, FALSE),
(130, 'dv', 'LNK_Scan_SignatureAI', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LNK_Scan_SignatureAI', 'ScanDate', FALSE),
(131, 'dv', 'LSAT_FL_InvoiceHeader', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_FL_InvoiceHeader', 'InvoiceDate', FALSE),
(132, 'dv', 'LSAT_FL_InvoicePayment', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_FL_InvoicePayment', NULL, FALSE),
(133, 'dv', 'LSAT_InvoiceHead', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_InvoiceHead', 'EnteredDate', FALSE),
(134, 'dv', 'LSAT_InvoiceLine', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_InvoiceLine', 'InvoiceDateInvLine', FALSE),
(135, 'dv', 'LSAT_Label_Interbranch', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Interbranch', 'InvoiceDate', FALSE),
(136, 'dv', 'LSAT_Label_Product_ServiceItem', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Label_Product_ServiceItem', 'CreatedOn', TRUE),
(137, 'dv', 'LSAT_Product_ServiceCon', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_LSAT_Product_ServiceCon', 'CreatedOn', TRUE),
(138, 'dv', 'SAL_Customer', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAL_Customer', NULL, FALSE),
(139, 'dv', 'SAT_Address', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Address', 'ValidFrom', TRUE),
(140, 'dv', 'SAT_Assura_AffectedPerson', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Assura_AffectedPerson', NULL, FALSE),
(141, 'dv', 'SAT_Assura_EventDetail', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Assura_EventDetail', 'EventDateTime', FALSE),
(142, 'dv', 'SAT_BLKContainer', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_BLKContainer', 'LastActionDate', FALSE),
(143, 'dv', 'SAT_BLKContainerManifest', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_BLKContainerManifest', 'ActionDate', FALSE),
(144, 'dv', 'SAT_BLKContainerManifestContents', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_BLKContainerManifestContents', 'ScanDate', FALSE),
(145, 'dv', 'SAT_BLKTransitManifest', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_BLKTransitManifest', 'DateOpened', FALSE),
(146, 'dv', 'SAT_BLKTransitManifestContents', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_BLKTransitManifestContents', NULL, FALSE),
(147, 'dv', 'SAT_CF', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_CF', NULL, TRUE),
(148, 'dv', 'SAT_Customer', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Customer', 'StartDate', TRUE),
(149, 'dv', 'SAT_CustomerCommissionOverride', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_CustomerCommissionOverride', NULL, FALSE),
(150, 'dv', 'SAT_Customer_OES', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Customer_OES', 'Undelivered_Labels_Report_LastReportDate', FALSE),
(151, 'dv', 'SAT_FL_PriceListCustomerOverride', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_FL_PriceListCustomerOverride', NULL, FALSE),
(152, 'dv', 'SAT_FL_ServiceZoneOverride', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_FL_ServiceZoneOverride', NULL, FALSE),
(153, 'dv', 'SAT_FL_Zones', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_FL_Zones', NULL, FALSE),
(154, 'dv', 'SAT_Label_Allocation', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation', 'CreateDateLocal', TRUE),
(155, 'dv', 'SAT_Label_Allocation_DL', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_DL', 'CreateDateLocal', TRUE),
(156, 'dv', 'SAT_Label_Allocation_EBAY', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_EBAY', 'CreateDateUTC', TRUE),
(157, 'dv', 'SAT_Label_Allocation_FL', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_FL', 'CreateDate', TRUE),
(158, 'dv', 'SAT_Label_Allocation_FLE', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_FLE', 'ValidFrom', TRUE),
(159, 'dv', 'SAT_Label_Allocation_IFS', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_IFS', 'DateInserted', TRUE),
(160, 'dv', 'SAT_Label_Allocation_MF', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_MF', 'CreatedOn', TRUE),
(161, 'dv', 'SAT_Label_Allocation_RP', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Allocation_RP', 'CreateDateUTC', TRUE),
(162, 'dv', 'SAT_Label_Distribution', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_Distribution', 'Distribution_Date', TRUE),
(163, 'dv', 'SAT_Label_PickupRequest', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Label_PickupRequest', 'CollectionDate', FALSE),
(164, 'dv', 'SAT_Product', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_Product', NULL, TRUE),
(165, 'dv', 'SAT_RF', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_RF', NULL, TRUE),
(166, 'dv', 'SAT_STK_RFProducts', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_STK_RFProducts', NULL, FALSE),
(167, 'dv', 'SAT_ScanStatus', 'prj-drgfly-prod-sp-01.bq_ds_prod_euw2_oceania_cube_gold_1.dv_SAT_ScanStatus', NULL, TRUE);

SET max_id = (SELECT MAX(Id) FROM _Tables);

WHILE i < max_id DO
    SET i = i + 1;
    SET schema_name = (SELECT SchemaName   FROM _Tables WHERE Id = i);
    SET table_name  = (SELECT TableName    FROM _Tables WHERE Id = i);
    SET bq_table    = (SELECT BQTable      FROM _Tables WHERE Id = i);
    SET filter_col  = (SELECT FilterColumn FROM _Tables WHERE Id = i);
    SET has_is_current = (SELECT HasIsCurrent FROM _Tables WHERE Id = i);

    BEGIN
        IF filter_col IS NOT NULL AND has_is_current THEN
            SET dyn_sql = FORMAT(
                "SELECT COUNT(*) FROM `%s` WHERE `%s` >= '%s' AND `%s` <= '%s' AND IsCurrent = 1",
                bq_table, filter_col, StartDate, filter_col, EndDateExclusive
            );
            EXECUTE IMMEDIATE dyn_sql INTO row_cnt;
        ELSEIF filter_col IS NOT NULL THEN
            SET dyn_sql = FORMAT(
                "SELECT COUNT(*) FROM `%s` WHERE `%s` >= '%s' AND `%s` <= '%s'",
                bq_table, filter_col, StartDate, filter_col, EndDateExclusive
            );
            EXECUTE IMMEDIATE dyn_sql INTO row_cnt;
        ELSEIF has_is_current THEN
            SET dyn_sql = FORMAT("SELECT COUNT(*) FROM `%s` WHERE IsCurrent = 1", bq_table);
            EXECUTE IMMEDIATE dyn_sql INTO row_cnt;
        ELSE
            SET dyn_sql = FORMAT("SELECT COUNT(*) FROM `%s`", bq_table);
            EXECUTE IMMEDIATE dyn_sql INTO row_cnt;
        END IF;

        INSERT INTO _Results VALUES (
            schema_name, table_name, IFNULL(filter_col, 'N/A'),
            IF(filter_col IS NOT NULL, 'Yes', 'No'), row_cnt, NULL,
            dyn_sql
        );
    EXCEPTION WHEN ERROR THEN
        INSERT INTO _Results VALUES (
            schema_name, table_name, IFNULL(filter_col, 'N/A'),
            IF(filter_col IS NOT NULL, 'Yes', 'No'), 0, @@error.message,
            dyn_sql
        );
    END;
    SELECT schema_name, table_name, filter_col, has_is_current, row_cnt, dyn_sql;
END WHILE;

SELECT SchemaName AS `Schema`, TableName AS `Table`, FilterColumn AS `Filter_Column`,
       FilterApplied AS `Filter_Applied`, IFNULL(RowCount, 0) AS `Row_Count`,
       IFNULL(ErrorMessage, '') AS `Error`, dyn_sql AS `query_used`
FROM _Results ORDER BY SchemaName, TableName;
