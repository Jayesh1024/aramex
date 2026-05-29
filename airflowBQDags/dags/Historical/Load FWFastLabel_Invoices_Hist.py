"""
Completed DAG for SSIS package: Load FWFastLabel_Invoices
Migration: SSIS -> BigQuery

Two parallel staging pipelines (InvoiceHeader / InvoicePayment), each with
Load Stg -> Final Load -> Set Last Value.

ProcessId is accepted as a DAG param (SSIS does not allocate one here).
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.models import Variable
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup

SP_DATASET_ID = Variable.get("SP_DATASET_ID")
TARGET_DATASET_ID = Variable.get("TARGET_DATASET_ID")

with DAG(
    dag_id="ssis_skeleton_load_fwfastlabel_invoices",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "load fwfastlabel_invoices", "Historical"],
    params={
        "DisableFinal": 0,
        "DisableStaging": 0,
        "process_id": 0,
        "RecordSource1": 'fl_InvoiceHeader',
        "RecordSource2": 'fl_InvoicePayment',
    },
) as dag:

    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE — ref_id: Package\Staging

        # ref_id: Package\Staging\Truncate Staging tables
        op_10 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_staging_tables",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_fl_InvoiceHeader_Stg`;\n"
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_fl_InvoicePayment_Stg`;"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Staging\Load fl_InvoiceHeader_Stg — pipeline -> inferred SP (_Hist)
        op_8 = BigQueryInsertJobOperator(
            task_id="package_staging_load_fl_invoiceheader_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.sp_load_Staging_fl_InvoiceHeader_Stg_Hist`();"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Staging\Load fl_InvoicePayment_Stg — pipeline -> inferred SP (_Hist)
        op_9 = BigQueryInsertJobOperator(
            task_id="package_staging_load_fl_invoicepayment_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.sp_load_Staging_fl_InvoicePayment_Stg_Hist`();"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        op_10 >> op_8
        op_10 >> op_9

    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\Final

        # ref_id: Package\Final\Load LSAT_FL_InvoiceHeader — [dv].[Load_FL_InvoiceHeader] ProcessId, RecordSource1
        op_1 = BigQueryInsertJobOperator(
            task_id="package_final_load_lsat_fl_invoiceheader",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_FL_InvoiceHeader`("
                        f"{{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSource1 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Final\Set Last InvoiceHeaderDate — Staging_Set_LastValue(4 args)
        op_3 = BigQueryInsertJobOperator(
            task_id="package_final_set_last_invoiceheaderdate",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.Staging_Set_LastValue`("
                        f"'{{{{ params.RecordSource1 }}}}', CAST(NULL AS STRING), CAST(NULL AS STRING), FALSE);"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Final\Load LSAT_FL_InvoicePayment — [dv].[Load_FL_InvoicePayment] ProcessId, RecordSource2
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_load_lsat_fl_invoicepayment",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_FL_InvoicePayment`("
                        f"{{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSource2 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Final\Set Last InvoicePaymentDate — Staging_Set_LastValue(4 args)
        op_4 = BigQueryInsertJobOperator(
            task_id="package_final_set_last_invoicepaymentdate",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.Staging_Set_LastValue`("
                        f"'{{{{ params.RecordSource2 }}}}', CAST(NULL AS STRING), CAST(NULL AS STRING), FALSE);"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        op_1 >> op_3
        op_2 >> op_4

    tg_staging >> tg_final
