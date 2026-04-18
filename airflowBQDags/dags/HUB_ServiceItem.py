"""
Completed DAG for SSIS package: HUB_ServiceItem
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
PACKAGE_NAME = "HUB_ServiceItem"
RECORD_SOURCE_1 = "RecordSource"

with DAG(
    dag_id="ssis_skeleton_hub_serviceitem",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_serviceitem"],
    params={
        "process_id": 1,
        "record_source": RECORD_SOURCE_1,
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
                    "query": f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_fl_ServiceItem_Stg`",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging\Load fl_ServiceItem_Stg (BQ: SP replaces SSIS pipeline)
        op_3 = BigQueryInsertJobOperator(
            task_id="package_staging_load_fl_serviceitem_stg",
            configuration={
                "query": {
                    "query": f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_Load_fl_ServiceItem_Stg`();",
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
                    "query": f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_HUB_ServiceItem`({{ params.process_id }}, '{{ params.record_source }}');",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final\Load SAT_ServiceItem — [dv].[Load_SAT_ServiceItem] ?,?
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_load_sat_serviceitem",
            configuration={
                "query": {
                    "query": f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_SAT_ServiceItem`({{ params.process_id }}, '{{ params.record_source }}');",
                    "useLegacySql": False,
                }
            },
        )

    # --- Precedence ---
    op_4 >> op_3 >> [op_1, op_2]

    # TaskGroup-level precedence
    tg_staging >> tg_final