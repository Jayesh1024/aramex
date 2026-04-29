"""
Completed DAG for SSIS package: Load FWFastLabel_Invoices
Migration: SSIS -> BigQuery

Two parallel staging pipelines (InvoiceHeader / InvoicePayment), each with
its own Get LastDate -> Load Stg -> Final Load -> Set Last Value.

ProcessId is accepted as a DAG param (SSIS does not allocate one here).
"""
from __future__ import annotations

from datetime import datetime
import os

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup
from utils.getValue import get_last_value

GCP_PROJECT_ID = os.getenv("GCP_PROJECT_ID")
SP_DATASET_ID = os.getenv("SP_DATASET_ID")
TARGET_DATASET_ID = os.getenv("TARGET_DATASET_ID")


_TASK_ID_GET_LAST_HEADER = "tg_package_staging.package_staging_get_last_invoiceheaderdate"
_TASK_ID_GET_LAST_PAYMENT = "tg_package_staging.package_staging_get_last_invoicepaymentdate"

with DAG(
    dag_id="ssis_skeleton_load_fwfastlabel_invoices",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "load fwfastlabel_invoices"],
    params={
        "DisableFinal": 0,
        "DisableStaging": 0,
        "ProcessId": 0,
        "RecordSource1": 'fl_InvoiceHeader',
        "RecordSource2": 'fl_InvoicePayment',
    },
) as dag:

    _xcom_last_header = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_LAST_HEADER}') }}}}"
    _xcom_last_payment = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_LAST_PAYMENT}') }}}}"

    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE — ref_id: Package\Staging

        # ref_id: Package\Staging\Truncate Staging tables
        op_10 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_staging_tables",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_fl_InvoiceHeader_Stg`;\n"
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_fl_InvoicePayment_Stg`;"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging\Get Last InvoiceHeaderDate — [Staging].[Get_LastValue] RecordSource1
        op_6 = PythonOperator(
            task_id="package_staging_get_last_invoiceheaderdate",
            python_callable=get_last_value,
            op_kwargs={
                "project_id": GCP_PROJECT_ID,
                "dataset_id": SP_DATASET_ID,
                "record_source": "{{ params.RecordSource1 }}",
            },
        )

        # ref_id: Package\Staging\Get Last InvoicePaymentDate — [Staging].[Get_LastValue] RecordSource2
        op_7 = PythonOperator(
            task_id="package_staging_get_last_invoicepaymentdate",
            python_callable=get_last_value,
            op_kwargs={
                "project_id": GCP_PROJECT_ID,
                "dataset_id": SP_DATASET_ID,
                "record_source": "{{ params.RecordSource2 }}",
            },
        )

        # ref_id: Package\Staging\Load fl_InvoiceHeader_Stg — pipeline -> inferred SP (LastHeaderDate)
        op_8 = BigQueryInsertJobOperator(
            task_id="package_staging_load_fl_invoiceheader_stg",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.sp_load_Staging_fl_InvoiceHeader_Stg`("
                        f"SAFE_CAST('{_xcom_last_header}' AS DATETIME));"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging\Load fl_InvoicePayment_Stg — pipeline -> inferred SP (LastPaymentDate)
        op_9 = BigQueryInsertJobOperator(
            task_id="package_staging_load_fl_invoicepayment_stg",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.sp_load_Staging_fl_InvoicePayment_Stg`("
                        f"SAFE_CAST('{_xcom_last_payment}' AS DATETIME));"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        op_10 >> op_6 >> op_8
        op_10 >> op_7 >> op_9

    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\Final

        # ref_id: Package\Final\Load LSAT_FL_InvoiceHeader — [dv].[Load_FL_InvoiceHeader] ProcessId, RecordSource1
        op_1 = BigQueryInsertJobOperator(
            task_id="package_final_load_lsat_fl_invoiceheader",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_FL_InvoiceHeader`("
                        f"{{{{ dag_run.conf.get('process_id', params.ProcessId) }}}}, '{{{{ params.RecordSource1 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final\Set Last InvoiceHeaderDate — Staging_Set_LastValue(4 args)
        op_3 = BigQueryInsertJobOperator(
            task_id="package_final_set_last_invoiceheaderdate",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.Staging_Set_LastValue`("
                        f"'{{{{ params.RecordSource1 }}}}', CAST(NULL AS STRING), CAST(NULL AS STRING), FALSE);"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final\Load LSAT_FL_InvoicePayment — [dv].[Load_FL_InvoicePayment] ProcessId, RecordSource2
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_load_lsat_fl_invoicepayment",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_FL_InvoicePayment`("
                        f"{{{{ dag_run.conf.get('process_id', params.ProcessId) }}}}, '{{{{ params.RecordSource2 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final\Set Last InvoicePaymentDate — Staging_Set_LastValue(4 args)
        op_4 = BigQueryInsertJobOperator(
            task_id="package_final_set_last_invoicepaymentdate",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.Staging_Set_LastValue`("
                        f"'{{{{ params.RecordSource2 }}}}', CAST(NULL AS STRING), CAST(NULL AS STRING), FALSE);"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        op_1 >> op_3
        op_2 >> op_4

    tg_staging >> tg_final
