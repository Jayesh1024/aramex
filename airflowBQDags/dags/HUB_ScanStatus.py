"""
Completed DAG for SSIS package: HUB_ScanStatus
Migration: SSIS -> BigQuery
Formatting: Jinja2 Templating for Parameters
"""
from __future__ import annotations

from datetime import datetime
import os

from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup

# --- Project Configuration ---
PROJECT_ID = os.getenv("PROJECT_ID")
SP_DATASET_ID = os.getenv("SP_DATASET_ID")
TARGET_DATASET_ID = os.getenv("TARGET_DATASET_ID")

with DAG(
    dag_id="ssis_skeleton_hub_scanstatus",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_scanstatus"],
    # Jinja placeholders defined here
    params={
        "DisableFinal": 0,
        "DisableStaging": 0,
        "ProcessId": 18,
        "RecordSource": 'Fastway',
    },
) as dag:

    # --- Package\\Staging ---
    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE — ref_id: Package\\Staging

        # ref_id: Package\\Staging\\Truncate ScanStatus_Stg
        op_4 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_scanstatus_stg",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_ScanStatus_Stg`",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\\Staging\\Load ScanStatus_Stg
        op_3 = BigQueryInsertJobOperator(
            task_id="package_staging_load_scanstatus_stg",
            configuration={
                "query": {
                    "query": f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.sp_load_Staging_ScanStatus_Stg`();",
                    "useLegacySql": False,
                }
            },
        )

        

    # --- Package\\Final ---
    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\\Final

        # ref_id: Package\\Final\\Load HUB_ScanStatus
        op_1 = BigQueryInsertJobOperator(
            task_id="package_final_load_hub_scanstatus",
            configuration={
                "query": {
                    "query": f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_HUB_ScanStatus`({{ params.ProcessId }}, '{{ params.RecordSource }}');",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\\Final\\Load SAT_ScanStatus
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_load_sat_scanstatus",
            configuration={
                "query": {
                    "query": f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_SAT_ScanStatus`({{ params.ProcessId }}, '{{ params.RecordSource }}');",
                    "useLegacySql": False,
                }
            },
        )

    # --- Precedence ---
    op_4 >> op_3 >> [op_1, op_2]

    # TaskGroup-level precedence
    tg_staging >> tg_final