"""
Completed DAG for SSIS package: DB_Maintenance
Migration: SSIS -> BigQuery

ExecuteSQL tasks map to CALL ...schema_proc patterns from metadata (e.g. dbo_MaintainIndexes).
Release Space (DBCC / file shrink) maps to a dedicated BigQuery maintenance procedure dbo_ReleaseSpace.
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
PACKAGE_NAME = "DB_Maintenance"

with DAG(
    dag_id="ssis_skeleton_db_maintenance",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "db_maintenance"],
) as dag:
    # ref_id: Package\Database Maintenance\Release Space — SQL Server shrink script -> BQ maintenance SP
    op_1 = BigQueryInsertJobOperator(
        task_id="package_database_maintenance_release_space",
        configuration={
            "query": {
                "query": f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dbo_ReleaseSpace`();",
                "useLegacySql": False,
            }
        },
    )
    op_1
