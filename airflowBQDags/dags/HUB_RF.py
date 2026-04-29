"""
Completed DAG for SSIS package: HUB_RF
Migration: SSIS -> BigQuery
Formatting: Jinja2 Templating for Parameters

Table / procedure names use schema_object from metadata (e.g. Staging_Franchisee_Stg, dv_Load_HUB_RF).
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
    dag_id="ssis_skeleton_hub_rf",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_rf"],
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

        # ref_id: Package\Staging\Truncate Franchisee_Stg — metadata: TRUNCATE TABLE [Staging].[Franchisee_Stg]
        op_4 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_franchisee_stg",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_Franchisee_Stg`",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Staging\Load Franchisee_Stg — destination Staging.Franchisee_Stg (BQ: SP replaces SSIS pipeline)
        op_3 = BigQueryInsertJobOperator(
            task_id="package_staging_load_franchisee_stg",
            configuration={
                "query": {
                    "query": f"CALL `{SP_DATASET_ID}.sp_load_Staging_Franchisee_Stg`();",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

    # --- Package\Final ---
    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\Final

        # ref_id: Package\Final\Load HUB_RF — Exec [dv].[Load_HUB_RF] ?,? (param_1 → params.RecordSource)
        op_1 = BigQueryInsertJobOperator(
            task_id="package_final_load_hub_rf",
            configuration={
                "query": {
                    "query": f"CALL `{SP_DATASET_ID}.dv_Load_HUB_RF`({{{{ dag_run.conf.get('process_id', params.ProcessId) }}}}, '{{{{ params.RecordSource }}}}');",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Final\Load SAT_RF — Exec [dv].[Load_SAT_RF] ?,? (param_1 → params.RecordSource)
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_load_sat_rf",
            configuration={
                "query": {
                    "query": f"CALL `{SP_DATASET_ID}.dv_Load_SAT_RF`({{{{ dag_run.conf.get('process_id', params.ProcessId) }}}}, '{{{{ params.RecordSource }}}}');",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

    # --- Precedence ---
    op_4 >> op_3 >> [op_1, op_2]

    # TaskGroup-level precedence
    tg_staging >> tg_final
