"""
Completed DAG for SSIS package: ConnectStringTest
Migration: SSIS -> BigQuery

Table / procedure names use schema_object from metadata.json (e.g. Staging_tblCustomer_Stg, sp_load_Staging_tblCustomer_Stg).
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.models import Variable
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator

GCP_PROJECT_ID = Variable.get("PROJECT_ID")
SP_DATASET_ID = Variable.get("SP_DATASET_ID")
TARGET_DATASET_ID = Variable.get("TARGET_DATASET_ID")


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
        gcp_conn_id="oceania_target_sa_connection",
        configuration={
            "query": {
                "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_tblCustomer_Stg`;",
                "useLegacySql": False,
            }
        },
        job_id="bq_gold_transformation_oceania",
    )

    # ref_id: Package\Load tblCustomer_stg — destination Staging.tblCustomer_Stg (BQ: SP replaces SSIS pipeline)
    op_1 = BigQueryInsertJobOperator(
        task_id="package_load_tblcustomer_stg",
        gcp_conn_id="oceania_target_sa_connection",
        configuration={
            "query": {
                "query": f"CALL `{SP_DATASET_ID}.sp_load_Staging_tblCustomer_Stg`();",
                "useLegacySql": False,
            }
        },
        job_id="bq_gold_transformation_oceania",
    )

    op_0 >> op_1
