-- =============================================================================
-- Reset LoadControl.LastValue
-- Dates  → '2026-04-01 00:00:00'
-- Integers → '0'
-- NULLs / empty strings: type inferred from ColumnName
-- =============================================================================

-- ─── DATE RESETS ─────────────────────────────────────────────────────────────

-- MyFastway | ColumnName: CreatedOn | LastValue was: None (inferred → date)
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'MyFastway';

-- MyFastwaySrv | ColumnName: CreatedOn | LastValue was: 2020-08-15 0:16:42
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'MyFastwaySrv';

-- FastLabelEnterprise | ColumnName: CreatedOn | LastValue was: 2026-04-20 23:57:33
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'FastLabelEnterprise';

-- FMS_Invoice | ColumnName: EnteredDate | LastValue was: NULL (inferred → date)
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'FMS_Invoice';

-- FMSUndTcktInvoice | ColumnName: Date | LastValue was: 2026-04-21 11:52:12
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'FMSUndTcktInvoice';

-- HDManifest | ColumnName: DateInserted | LastValue was: Jul 3 2025 1:29 AM
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'HDManifest';

-- LabelMaster | ColumnName: UploadDate | LastValue was: Aug 13 2025 12:00 AM
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'LabelMaster';

-- FastLabel | ColumnName: CreateDate | LastValue was: 2026-04-20 23:59:14
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'FastLabel';

-- Fact_KPI_Scan | ColumnName: ScanDateTime | LastValue was: 2026-04-25 0:00:00
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'Fact_KPI_Scan';

-- fl_InvoiceHeader | ColumnName: InvoiceDate | LastValue was: Aug 11 2025 12:00 AM
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'fl_InvoiceHeader';

-- fl_InvoicePayment | ColumnName: UpdatedOn | LastValue was: 2025-08-13 16:15:00
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'fl_InvoicePayment';

-- BLK_ManifestContents | ColumnName: ScanDate | LastValue was: '' (empty, inferred → date)
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'BLK_ManifestContents';

-- Label_Invoices | ColumnName: FMS_InvoiceID | LastValue was: 2024-06-04 0:00:00 (value is date)
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'Label_Invoices';

-- Labels | ColumnName: Date | LastValue was: Dec 16 2020 12:00 AM
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'Labels';

-- tsections | ColumnName: UploadDate | LastValue was: Dec 16 2020 12:00 AM
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'tsections';

-- TrackAndTrace | ColumnName: CONVERT(datetime,RecordCreateDate) | LastValue was: Dec 12 2023 11:59 PM
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'TrackAndTrace';

-- TrackAndTraceData_SignatureAI | ColumnName: LastUpdatedOn | LastValue was: Jul 24 2025 7:31 PM
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'TrackAndTraceData_SignatureAI';

-- ZenLog | ColumnName: SysLastUpdatedUtc | LastValue was: '' (empty, inferred → date)
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'ZenLog';

-- Fact_KPI_DPFM_Export | ColumnName: n/a | LastValue was: 2025-08-01 0:00:00 (value is date)
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'Fact_KPI_DPFM_Export';

-- LA_RuralOnforwards | ColumnName: Date | LastValue was: Aug 12 2025 12:00 AM
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'LA_RuralOnforwards';

-- CF_devuctivity_NZ | ColumnName: ID | LastValue was: 2025-08-12 0:00:00 (value is date)
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'CF_devuctivity_NZ';

-- CF_devuctivity | ColumnName: ID | LastValue was: 2025-08-11 0:00:00 (value is date)
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '2026-04-01 00:00:00'
WHERE RecordSource = 'CF_devuctivity';

-- ─── INTEGER RESETS ───────────────────────────────────────────────────────────

-- DynamicLabel | ColumnName: HistoryID | LastValue was: 287340045
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '0'
WHERE RecordSource = 'DynamicLabel';

-- Temando | ColumnName: globalRequestID | LastValue was: 3027118
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '0'
WHERE RecordSource = 'Temando';

-- EBAY | ColumnName: ID | LastValue was: 320454
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '0'
WHERE RecordSource = 'EBAY';

-- ReceiverPays | ColumnName: RPID | LastValue was: 2301749
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '0'
WHERE RecordSource = 'ReceiverPays';

-- Tasman | ColumnName: TasmanID | LastValue was: 53871
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '0'
WHERE RecordSource = 'Tasman';

-- MISSING_HDManifest | ColumnName: RecordId | LastValue was: 499021943
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '0'
WHERE RecordSource = 'MISSING_HDManifest';

-- HDManifestID | ColumnName: RecordId | LastValue was: 549540204
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '0'
WHERE RecordSource = 'HDManifestID';

-- INITLOAD_HDManifest | ColumnName: RecordId | LastValue was: 496796559
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '0'
WHERE RecordSource = 'INITLOAD_HDManifest';

-- InterBranchAU | ColumnName: BatchID | LastValue was: 292
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '0'
WHERE RecordSource = 'InterBranchAU';

-- InterBranchIE | ColumnName: BatchID | LastValue was: 125
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '0'
WHERE RecordSource = 'InterBranchIE';

-- InterBranchNZ | ColumnName: BatchID | LastValue was: 294
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '0'
WHERE RecordSource = 'InterBranchNZ';

-- InterBranchSA | ColumnName: BatchID | LastValue was: 213
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '0'
WHERE RecordSource = 'InterBranchSA';

-- TrackAndTraceID | ColumnName: ID | LastValue was: 4119792212
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '0'
WHERE RecordSource = 'TrackAndTraceID';

-- devuct_ServiceItems_ToProcess | ColumnName: ID | LastValue was: 35500000
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '0'
WHERE RecordSource = 'devuct_ServiceItems_ToProcess';

-- Allocation_MF_LabelsToProcess | ColumnName: ID | LastValue was: 28000000
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '0'
WHERE RecordSource = 'Allocation_MF_LabelsToProcess';

-- FactScanKPI | ColumnName: TrackAndTraceID | LastValue was: 4119792212
UPDATE `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_oceania_cube_gold_1.Staging_LoadControl`
SET LastValue = '0'
WHERE RecordSource = 'FactScanKPI';
