"""
DAG for SSIS package: HUB_Invoice (GCP / BigQuery).
Staging + Final + UndTcktInvoice: BigQueryInsertJobOperator CALLs where implemented.
Sequence containers (STOCK:SEQUENCE) → TaskGroup.

GCP naming (from SQL Server metadata in outputs/ and Packages/):
  SSIS uses schemas such as dv, dbo, Staging (e.g. [dv].[Load_HUB_Invoice], [Staging].[Set_LastValue]).
  In BigQuery, replace only the dot: schema.object → schema_object, preserving casing from the source
  (e.g. dv_Load_HUB_Invoice, Staging_Set_LastValue, Staging_FMS_InvoiceHead_Stg). Same for routines (SPs).
"""
from __future__ import annotations

from datetime import datetime
import os

from airflow import DAG
from airflow.utils.task_group import TaskGroup
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from utils.getValue import get_last_value

# params.RecordSource2 is the HUB_Invoice.dtsx $Package::RecordSource2 value
# used by UndTckt Staging get-last + Final set-last.
SP_DATASET_ID = os.getenv("SP_DATASET_ID")
PROJECT_ID = os.getenv("PROJECT_ID")
# Full task id for XCom (Final is defined above Staging in this file; cannot reference op_16 at parse time).
_TASK_IDS_LASTDATE_FMS_INVOICE = "tg_package_staging.package_staging_get_lastdate_fms_invoice"

with DAG(
    dag_id="ssis_skeleton_hub_invoice",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_invoice"],
    params={
        "DisableFinal": 0,
        "DisableStaging": 0,
        "DisableUndTcktFinal": 0,
        "DisableUndTcktStaging": 0,
        "ProcessId": -453,
        "RecordSource": 'FMS_Invoice',
        "RecordSource2": 'FMSUndTcktInvoice',
    },
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\\Final (no package_final empty; staging loads >> first task)

        # ref_id: Package\\Final\\Load HUB_Invoice — SSIS: Exec [dv].[Load_HUB_Invoice] ProcessId, RecordSource
        op_4 = BigQueryInsertJobOperator(
            task_id="package_final_load_hub_invoice",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_HUB_Invoice`("
                        f"{{{{ params.ProcessId }}}}, '{{{{ params.RecordSource }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="google_cloud_default",
        )

        # ref_id: Package\\Final\\Load_Label_Invoices — SSIS: EXEC dv.Load_Label_Invoices ProcessId, LastDate
        op_9 = BigQueryInsertJobOperator(
            task_id="package_final_load_label_invoices",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_Label_Invoices`("
                        f"{{{{ params.ProcessId }}}}, "
                        f"SAFE_CAST('{{{{ ti.xcom_pull(task_ids='{_TASK_IDS_LASTDATE_FMS_INVOICE}') }}}}' AS DATETIME));"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="google_cloud_default",
        )

        # ref_id: Package\\Final\\Load_LNK_InvoiceLine — SSIS: Exec [dv].[Load_LNK_InvoiceLine] ProcessId
        op_5 = BigQueryInsertJobOperator(
            task_id="package_final_load_lnk_invoiceline",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_LNK_InvoiceLine`({{{{ params.ProcessId }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="google_cloud_default",
        )

        # ref_id: Package\\Final\\Load_LNK_Invoice_Label — SSIS: Exec [dv].[Load_LNK_Invoice_Label] ProcessId
        op_6 = BigQueryInsertJobOperator(
            task_id="package_final_load_lnk_invoice_label",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_LNK_Invoice_Label`({{{{ params.ProcessId }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="google_cloud_default",
        )

        # ref_id: Package\\Final\\Load_LSAT_InvoiceHead — SSIS: EXEC dv.Load_LSAT_InvoiceHead ProcessId
        op_7 = BigQueryInsertJobOperator(
            task_id="package_final_load_lsat_invoicehead",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_LSAT_InvoiceHead`({{{{ params.ProcessId }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="google_cloud_default",
        )

        # ref_id: Package\\Final\\Load_LSAT_InvoiceLine — SSIS: Exec [dv].[Load_LSAT_InvoiceLine] ProcessId
        op_8 = BigQueryInsertJobOperator(
            task_id="package_final_load_lsat_invoiceline",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_LSAT_InvoiceLine`({{{{ params.ProcessId }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="google_cloud_default",
        )

        # ref_id: Package\\Final\\Set LastDate (FMS_Invoice) — SSIS: Exec [Staging].[Set_LastValue]; BQ: Staging_Set_LastValue
        op_10 = BigQueryInsertJobOperator(
            task_id="package_final_set_lastdate_fms_invoice",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_Set_LastValue`('{{{{ params.RecordSource }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="google_cloud_default",
        )

    with TaskGroup(group_id="tg_package_final_undtcktinvoice") as tg_final_undtckt:
        # STOCK:SEQUENCE — ref_id: Package\\Final UndTcktInvoice (no package_final_undtcktinvoice empty; staging load >> first task)

        # ref_id: Package\\Final UndTcktInvoice\\Load UndTckt Invoice — SSIS: Exec [dbo].[Load_UndTckt_Invoice] ProcessId
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_undtcktinvoice_load_undtckt_invoice",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dbo_Load_UndTckt_Invoice`({{{{ params.ProcessId }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="google_cloud_default",
        )

        # ref_id: Package\\Final UndTcktInvoice\\Set LastDate (UndTckt Invoice) — SSIS binds $RecordSource2; BQ: params.RecordSource2
        op_3 = BigQueryInsertJobOperator(
            task_id="package_final_undtcktinvoice_set_lastdate_undtckt_invoice",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_Set_LastValue`('{{{{ params.RecordSource2 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="google_cloud_default",
        )

    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE — ref_id: Package\\Staging (no package_staging empty; parallel loads >> package_final_load_hub_invoice)

        # ref_id: Package\\Staging\\Truncate Staging tables
        op_20 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_staging_tables",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE `{PROJECT_ID}.{SP_DATASET_ID}.Staging_FMS_InvoiceHead_Stg`;\n"
                        f"TRUNCATE TABLE `{PROJECT_ID}.{SP_DATASET_ID}.Staging_FMS_InvoiceLines_Stg`;\n"
                        f"TRUNCATE TABLE `{PROJECT_ID}.{SP_DATASET_ID}.Staging_FMS_InvoiceBooks_Stg`;\n"
                        f"TRUNCATE TABLE `{PROJECT_ID}.{SP_DATASET_ID}.Staging_FastwayLabels_Stg`;"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="google_cloud_default",
        )

        # ref_id: Package\\Staging\\Get LastDate (FMS_Invoice)
        op_16 = PythonOperator(
            task_id="package_staging_get_lastdate_fms_invoice",
            python_callable=get_last_value,
            op_kwargs={
                "project_id": PROJECT_ID,
                "dataset_id": SP_DATASET_ID,
                "record_source": "{{ params.RecordSource }}",
            },
        )

        # ref_id: Package\\Staging\\Load FMS_InvoiceBooks_Stg
        # SSIS: OLE DB … → [Staging].[FMS_InvoiceBooks_Stg]; BQ: sp_load_Staging_FMS_InvoiceBooks_Stg
        op_17 = BigQueryInsertJobOperator(
            task_id="package_staging_load_fms_invoicebooks_stg",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.sp_load_Staging_FMS_InvoiceBooks_Stg`("
                        f"SAFE_CAST('{{{{ ti.xcom_pull(task_ids='{op_16.task_id}') }}}}' AS DATETIME));"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="google_cloud_default",
        )

        # ref_id: Package\\Staging\\Load FMS_InvoiceHead_Stg
        # SSIS: … → [Staging].[FMS_InvoiceHead_Stg]; BQ: sp_load_Staging_FMS_InvoiceHead_Stg
        op_18 = BigQueryInsertJobOperator(
            task_id="package_staging_load_fms_invoicehead_stg",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.sp_load_Staging_FMS_InvoiceHead_Stg`("
                        f"SAFE_CAST('{{{{ ti.xcom_pull(task_ids='{op_16.task_id}') }}}}' AS DATETIME));"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="google_cloud_default",
        )

        # ref_id: Package\\Staging\\Load FMS_InvoiceLines_Stg
        # SSIS: … → [Staging].[FMS_InvoiceLines_Stg]; BQ: sp_load_Staging_FMS_InvoiceLines_Stg
        op_19 = BigQueryInsertJobOperator(
            task_id="package_staging_load_fms_invoicelines_stg",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.sp_load_Staging_FMS_InvoiceLines_Stg`("
                        f"SAFE_CAST('{{{{ ti.xcom_pull(task_ids='{op_16.task_id}') }}}}' AS DATETIME));"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="google_cloud_default",
        )


    with TaskGroup(group_id="tg_package_staging_undtcktinvoice") as tg_staging_undtckt:
        # STOCK:SEQUENCE — ref_id: Package\\Staging UndTcktInvoice (no package_staging_undtcktinvoice empty)

        # ref_id: Package\\Staging UndTcktInvoice\\Truncate Staging tables — SSIS: TRUNCATE [Staging].[FMS_UndTcktInvoice_Stg]
        op_15 = BigQueryInsertJobOperator(
            task_id="package_staging_undtcktinvoice_truncate_staging_tables",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE `{PROJECT_ID}.{SP_DATASET_ID}.Staging_FMS_UndTcktInvoice_Stg`;"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="google_cloud_default",
        )

        # ref_id: Package\\Staging UndTcktInvoice\\Get LastDate (UndTckt Invoice) — SSIS $RecordSource2 → params.RecordSource2
        op_14 = PythonOperator(
            task_id="package_staging_undtcktinvoice_get_lastdate_undtckt_invoice",
            python_callable=get_last_value,
            op_kwargs={
                "project_id": PROJECT_ID,
                "dataset_id": SP_DATASET_ID,
                "record_source": "{{ params.RecordSource2 }}",
            },
        )

        # ref_id: Package\\Staging UndTcktInvoice\\FMS_UndTcktInvoice_Load — SSIS: … → [Staging].[FMS_UndTcktInvoice_Stg]; BQ: sp_load_Staging_FMS_UndTcktInvoice_Stg
        op_13 = BigQueryInsertJobOperator(
            task_id="package_staging_undtcktinvoice_fms_undtcktinvoice_load",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.sp_load_Staging_FMS_UndTcktInvoice_Stg`("
                        f"SAFE_CAST('{{{{ ti.xcom_pull(task_ids='{op_14.task_id}') }}}}' AS DATETIME));"
                    ),
                    "useLegacySql": False,
                }
            },
            gcp_conn_id="google_cloud_default",
        )

    # --- precedence (upstream >> downstream) ---
    op_7 >> op_9
    op_4 >> op_5
    op_4 >> op_6
    op_6 >> op_7
    op_5 >> op_8
    op_8 >> op_10
    op_9 >> op_10
    op_2 >> op_3
    op_20 >> op_16
    op_16 >> op_17
    op_16 >> op_18
    op_16 >> op_19
    [op_17, op_18, op_19] >> op_4
    op_15 >> op_14
    op_14 >> op_13
    op_13 >> op_2

    # TaskGroup-level precedence (cross-group edges are already encoded above
    # via task-level wiring; this makes the overall flow explicit in the DAG graph).
    tg_staging >> tg_final
    tg_staging_undtckt >> tg_final_undtckt
