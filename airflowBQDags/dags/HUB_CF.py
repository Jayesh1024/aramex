"""
Completed DAG for SSIS package: HUB_CF
Migration: SSIS -> BigQuery
Formatting: Jinja2 Templating for Parameters

Table / procedure names use schema_object from metadata (e.g. Staging_Courier_Stg, dv_Load_HUB_CF).
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator

from airflow.utils.task_group import TaskGroup

# --- Project Configuration ---
PROJECT_ID = "prj-drgfly-dev-sp-01"
SP_DATASET_ID = "bq_ds_dev_euw2_store_procedure"
TARGET_DATASET_ID = "bq_ds_dev_euw2_oceania_cube_gold_1"
PACKAGE_NAME = "HUB_CF"
RECORD_SOURCE_1 = "RecordSource"


with DAG(
    dag_id="ssis_skeleton_hub_cf",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_cf"],
    params={
        "process_id": 1,
        "record_source": RECORD_SOURCE_1
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
                    "query": f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_Courier_Stg`",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging\Load Courier_Stg — destination Staging.Courier_Stg (BQ: SP replaces SSIS pipeline)
        op_3 = BigQueryInsertJobOperator(
            task_id="package_staging_load_courier_stg",
            configuration={
                "query": {
                    "query": f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.sp_load_Staging_Courier_Stg`();",
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
                    "query": f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_HUB_CF`({{ params.process_id }}, '{{ params.record_source }}');",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final\Load CF_SAT — Exec [dv].[Load_SAT_CF] ?,?
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_load_cf_sat",
            configuration={
                "query": {
                    "query": f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_SAT_CF`({{ params.process_id }}, '{{ params.record_source }}');",
                    "useLegacySql": False,
                }
            },
        )

    # --- Precedence ---
    op_4 >> op_3 >> [op_1, op_2]

    # TaskGroup-level precedence
    tg_staging >> tg_final
