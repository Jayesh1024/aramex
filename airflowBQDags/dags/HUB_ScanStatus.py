"""
Completed DAG for SSIS package: HUB_ScanStatus
Migration: SSIS -> BigQuery
Formatting: Jinja2 Templating for Parameters
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup

# --- Project Configuration ---
PROJECT_ID = "searce-sandbox-da-delivery"
SP_DATASET_ID = "Aramex_oceania_SP"
TARGET_DATASET_ID = "Aramex_oceania"
PACKAGE_NAME = "HUB_ScanStatus"

with DAG(
    dag_id="ssis_skeleton_hub_scanstatus",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_scanstatus"],
    # Jinja placeholders defined here
    params={
        "process_id": 1,
        "record_source": "Fastway",
    },
) as dag:

    # --- Package\\Staging ---
    with TaskGroup(group_id="tg_package_staging"):
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
                    "query": f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_Load_ScanStatus_Stg`();",
                    "useLegacySql": False,
                }
            },
        )

        

    # --- Package\\Final ---
    with TaskGroup(group_id="tg_package_final"):
        # STOCK:SEQUENCE — ref_id: Package\\Final

        # ref_id: Package\\Final\\Load HUB_ScanStatus
        op_1 = BigQueryInsertJobOperator(
            task_id="package_final_load_hub_scanstatus",
            configuration={
                "query": {
                    "query": f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_HUB_ScanStatus`({{ params.process_id }}, '{{ params.record_source }}');",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\\Final\\Load SAT_ScanStatus
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_load_sat_scanstatus",
            configuration={
                "query": {
                    "query": f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_SAT_ScanStatus`({{ params.process_id }}, '{{ params.record_source }}');",
                    "useLegacySql": False,
                }
            },
        )

    # --- Precedence ---
    op_4 >> op_3 >> [op_1, op_2]