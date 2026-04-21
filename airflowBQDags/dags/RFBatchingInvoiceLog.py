"""
Completed DAG for SSIS package: RFBatchingInvoiceLog
Migration: SSIS -> BigQuery
Formatting: Jinja2 Templating for Parameters

Table / procedure names use schema_object from metadata.json (e.g. Staging_RFBatchingInvoiceLog_Stg, dv_Load_LNK_RFBatchingInvoiceLog).
"""
from __future__ import annotations

from datetime import datetime
import os

from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup
from utils.bq_env import PROJECT_ID, SP_DATASET_ID, TARGET_DATASET_ID

# --- Project Configuration ---
with DAG(
    dag_id="ssis_skeleton_rfbatchinginvoicelog",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "rfbatchinginvoicelog"],
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
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_RFBatchingInvoiceLog_Stg`;\n"
                        f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.dv_LNK_RFBatchingInvoiceLog`;"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging\Load RFBatchingInvoice_Stg — destination Staging.RFBatchingInvoiceLog_Stg (BQ: SP replaces SSIS pipeline)
        op_3 = BigQueryInsertJobOperator(
            task_id="package_staging_load_rfbatchinginvoice_stg",
            configuration={
                "query": {
                    "query": f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.sp_load_Staging_RFBatchingInvoiceLog_Stg`();",
                    "useLegacySql": False,
                }
            },
        )


    # --- Package\Final ---
    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\Final

        # ref_id: Package\Final\Load  LNK_RFBatchingInvoiceLog — destination dv.LNK_RFBatchingInvoiceLog (BQ: SP replaces SSIS pipeline)
        op_1 = BigQueryInsertJobOperator(
            task_id="package_final_load_lnk_rfbatchinginvoicelog",
            configuration={
                "query": {
                    "query": f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_LNK_RFBatchingInvoiceLog`();",
                    "useLegacySql": False,
                }
            },
        )

    # --- Precedence ---
    op_4 >> op_3 >> op_1

    # TaskGroup-level precedence
    tg_staging >> tg_final
