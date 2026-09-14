"""
Completed DAG for SSIS package: RFBatchingInvoiceLog
Migration: SSIS -> BigQuery
Formatting: Jinja2 Templating for Parameters

Table / procedure names use schema_object from metadata.json (e.g. Staging_RFBatchingInvoiceLog_Stg, dv_Load_LNK_RFBatchingInvoiceLog).
"""
from __future__ import annotations

import pendulum

from airflow import DAG
from airflow.models import Variable
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup

GCP_PROJECT_ID = Variable.get("PROJECT_ID")
SP_DATASET_ID = Variable.get("SP_DATASET_ID")
TARGET_DATASET_ID = Variable.get("TARGET_DATASET_ID")


# --- Project Configuration ---

default_args = {
    'owner': 'airflow',
    'depends_on_past': True,
    'retries': 3,
}

with DAG(
    dag_id="ssis_skeleton_rfbatchinginvoicelog",
    start_date=pendulum.datetime(2026, 4, 1, tz="Pacific/Auckland"),
    schedule_interval='0 6 2 * *',
    catchup=False,
    default_args=default_args,
    tags=["ssis", "skeleton", "rfbatchinginvoicelog", "RecordSource_BatchingInvoiceLog", "Incremental"],
    params={
        "RecordSource": 'BatchingInvoiceLog',
    },
) as dag:

    # --- Package\Staging ---
    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE — ref_id: Package\Staging

        # ref_id: Package\Staging\Truncate RFBatchingInvoiceLog_Stg — metadata.json: [Staging].[RFBatchingInvoiceLog_Stg], [dv].[LNK_RFBatchingInvoiceLog]
        op_4 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_rfbatchinginvoicelog_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_RFBatchingInvoiceLog_Stg`;"
                        # f"TRUNCATE TABLE `{TARGET_DATASET_ID}.dv_LNK_RFBatchingInvoiceLog`;"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Staging\Load RFBatchingInvoice_Stg — destination Staging.RFBatchingInvoiceLog_Stg (BQ: SP replaces SSIS pipeline)
        op_3 = BigQueryInsertJobOperator(
            task_id="package_staging_load_rfbatchinginvoice_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"CALL `{SP_DATASET_ID}.sp_load_Staging_RFBatchingInvoiceLog_Stg`();",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )


    # --- Package\Final ---
    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\Final

        # ref_id: Package\Final\Load  LNK_RFBatchingInvoiceLog — destination dv.LNK_RFBatchingInvoiceLog (BQ: SP replaces SSIS pipeline)
        op_1 = BigQueryInsertJobOperator(
            task_id="package_final_load_lnk_rfbatchinginvoicelog",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"SELECT * FROM `{TARGET_DATASET_ID}.dv_LNK_RFBatchingInvoiceLog`;",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

    # --- Precedence ---
    op_4 >> op_3 >> op_1

    # TaskGroup-level precedence
    tg_staging >> tg_final
