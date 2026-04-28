"""
Completed DAG for SSIS package: HUB_ServiceItem
Migration: SSIS -> BigQuery
Formatting: Jinja2 Templating for Parameters
"""
from __future__ import annotations

from datetime import datetime
import os

from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup

GCP_PROJECT_ID = os.getenv("GCP_PROJECT_ID")
SP_DATASET_ID = os.getenv("SP_DATASET_ID")
TARGET_DATASET_ID = os.getenv("TARGET_DATASET_ID")


# --- Project Configuration ---
with DAG(
    dag_id="ssis_skeleton_hub_serviceitem",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_serviceitem"],
    params={
        "DisableFinal": 0,
        "DisableStaging": 0,
        "ProcessId": 659,
        "RecordSource": 'Fastway',
    },
) as dag:

    # --- Package\Staging ---
    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE — ref_id: Package\Staging

        # ref_id: Package\Staging\Truncate fl_ServiceItem_Stg
        op_4 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_fl_serviceitem_stg",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_fl_ServiceItem_Stg`",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging\Load fl_ServiceItem_Stg (BQ: SP replaces SSIS pipeline)
        op_3 = BigQueryInsertJobOperator(
            task_id="package_staging_load_fl_serviceitem_stg",
            configuration={
                "query": {
                    "query": f"CALL `{SP_DATASET_ID}.sp_load_Staging_fl_ServiceItem_Stg`();",
                    "useLegacySql": False,
                }
            },
        )
        

    # --- Package\Final ---
    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\Final

        # ref_id: Package\Final\Load HUB_ServiceItem — [dv].[Load_HUB_ServiceItem] ?,?
        op_1 = BigQueryInsertJobOperator(
            task_id="package_final_load_hub_serviceitem",
            configuration={
                "query": {
                    "query": f"CALL `{SP_DATASET_ID}.dv_Load_HUB_ServiceItem`({{{{ params.ProcessId }}}}, '{{{{ params.RecordSource }}}}');",
                    "useLegacySql": False,
                }
            },
        )

    # --- Precedence ---
    op_4 >> op_3 >> op_1

    # TaskGroup-level precedence
    tg_staging >> tg_final