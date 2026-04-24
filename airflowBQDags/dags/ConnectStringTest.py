"""
Completed DAG for SSIS package: ConnectStringTest
Migration: SSIS -> BigQuery

Table / procedure names use schema_object from metadata.json (e.g. Staging_tblCustomer_Stg, sp_load_Staging_tblCustomer_Stg).
"""
from __future__ import annotations

from datetime import datetime
import os

from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator

GCP_PROJECT = os.getenv("GCP_PROJECT")
SP_DATASET_ID = os.getenv("SP_DATASET_ID")
TARGET_DATASET_ID = os.getenv("TARGET_DATASET_ID")


# --- Project Configuration ---
with DAG(
    dag_id="ssis_skeleton_connectstringtest",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "connectstringtest"],
) as dag:

    # ref_id: Package\Execute SQL Task — metadata.json: TRUNCATE TABLE [Staging].[tblCustomer_Stg]
    op_0 = BigQueryInsertJobOperator(
        task_id="package_execute_sql_task",
        configuration={
            "query": {
                "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_tblCustomer_Stg`;",
                "useLegacySql": False,
            }
        },
    )

    # ref_id: Package\Load tblCustomer_stg — destination Staging.tblCustomer_Stg (BQ: SP replaces SSIS pipeline)
    op_1 = BigQueryInsertJobOperator(
        task_id="package_load_tblcustomer_stg",
        configuration={
            "query": {
                "query": f"CALL `{SP_DATASET_ID}.sp_load_Staging_tblCustomer_Stg`();",
                "useLegacySql": False,
            }
        },
    )

    op_0 >> op_1
