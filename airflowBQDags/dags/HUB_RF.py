"""
Completed DAG for SSIS package: HUB_RF
Migration: SSIS -> BigQuery
Formatting: Jinja2 Templating for Parameters

Table / procedure names use schema_object from metadata (e.g. Staging_Franchisee_Stg, dv_Load_HUB_RF).
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
PACKAGE_NAME = "HUB_RF"
RECORD_SOURCE_1 = "RecordSource"

with DAG(
    dag_id="ssis_skeleton_hub_rf",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_rf"],
    params={
        "process_id": 1,
        "record_source_1": RECORD_SOURCE_1,
    },
) as dag:

    # --- Package\Staging ---
    with TaskGroup(group_id="tg_package_staging"):
        # STOCK:SEQUENCE — ref_id: Package\Staging

        # ref_id: Package\Staging\Truncate Franchisee_Stg — metadata: TRUNCATE TABLE [Staging].[Franchisee_Stg]
        op_4 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_franchisee_stg",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_Franchisee_Stg`",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging\Load Franchisee_Stg — destination Staging.Franchisee_Stg (BQ: SP replaces SSIS pipeline)
        op_3 = BigQueryInsertJobOperator(
            task_id="package_staging_load_franchisee_stg",
            configuration={
                "query": {
                    "query": f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_Load_Franchisee_Stg`();",
                    "useLegacySql": False,
                }
            },
        )

    # --- Package\Final ---
    with TaskGroup(group_id="tg_package_final"):
        # STOCK:SEQUENCE — ref_id: Package\Final

        # ref_id: Package\Final\Load HUB_RF — Exec [dv].[Load_HUB_RF] ?,? (param_1 → RECORD_SOURCE_1)
        op_1 = BigQueryInsertJobOperator(
            task_id="package_final_load_hub_rf",
            configuration={
                "query": {
                    "query": f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_HUB_RF`({{ params.process_id }}, '{{ params.record_source_1 }}');",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final\Load SAT_RF — Exec [dv].[Load_SAT_RF] ?,? (param_1 → RECORD_SOURCE_1)
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_load_sat_rf",
            configuration={
                "query": {
                    "query": f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_SAT_RF`({{ params.process_id }}, '{{ params.record_source_1 }}');",
                    "useLegacySql": False,
                }
            },
        )

    # --- Precedence ---
    op_4 >> op_3 >> [op_1, op_2]
