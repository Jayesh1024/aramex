"""
Completed DAG for SSIS package: HUB_CF
Migration: SSIS -> BigQuery
Formatting: Jinja2 Templating for Parameters

Table / procedure names use schema_object from metadata (e.g. Staging_Courier_Stg, dv_Load_HUB_CF).
"""
from __future__ import annotations

from datetime import datetime
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup
import os

# --- Project Configuration ---
GCP_PROJECT_ID = os.getenv("GCP_PROJECT_ID")
SP_DATASET_ID = os.getenv("SP_DATASET_ID")
TARGET_DATASET_ID = os.getenv("TARGET_DATASET_ID")

with DAG(
    dag_id="ssis_skeleton_hub_cf",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_cf"],
    params={
        "DisableFinal": 0,
        "DisableStaging": 0,
        "ProcessId": 8,
        "RecordSource": 'Fastway',
    },
) as dag:

    # --- Package\Staging ---

    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE — ref_id: Package\Staging

        # ref_id: Package\Staging\Truncate Courier_Stg — metadata: TRUNCATE TABLE [Staging].[Courier_Stg]
        op_4 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_courier_stg",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_Courier_Stg`",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging\Load Courier_Stg — destination Staging.Courier_Stg (BQ: SP replaces SSIS pipeline)
        op_3 = BigQueryInsertJobOperator(
            task_id="package_staging_load_courier_stg",
            configuration={
                "query": {
                    "query": f"CALL `{SP_DATASET_ID}.sp_load_Staging_Courier_Stg`();",
                    "useLegacySql": False,
                }
            },
        )

        

    # --- Package\Final ---
    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\Final

        # ref_id: Package\Final\Load CF_HUB — Exec [dv].[Load_HUB_CF] ?,?
        op_1 = BigQueryInsertJobOperator(
            task_id="package_final_load_cf_hub",
            configuration={
                "query": {
                    # In f-strings, `{{`/`}}` are escapes; quadruple braces so Airflow receives Jinja `{{ ... }}`.
                    "query": f"CALL `{SP_DATASET_ID}.dv_Load_HUB_CF`({{{{ params.ProcessId }}}}, '{{{{ params.RecordSource }}}}');",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final\Load CF_SAT — Exec [dv].[Load_SAT_CF] ?,?
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_load_cf_sat",
            configuration={
                "query": {
                    "query": f"CALL `{SP_DATASET_ID}.dv_Load_SAT_CF`({{{{ params.ProcessId }}}}, '{{{{ params.RecordSource }}}}');",
                    "useLegacySql": False,
                }
            },
        )

    
    # --- Precedence ---
    op_4 >> op_3 >> [op_1, op_2]

    # TaskGroup-level precedence
    tg_staging >> tg_final
