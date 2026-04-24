"""
Completed DAG for SSIS package: Fact_Delivery_Performance
Migration: SSIS -> BigQuery

Get Next ProcessID (Staging.LoadLog / NextProcessId logic) maps to a BigQuery procedure Staging_GetNextProcessId.
Load_Fact_Delivery_Performance maps to dbo_Load_Fact_Delivery_Performance (schema_proc from [dbo].[Load_Fact_Delivery_Performance]).

No RecordSource in package metadata — only ProcessId-related parameters.
"""
from __future__ import annotations

from datetime import datetime
import os

from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator

PROJECT_ID = os.getenv("PROJECT_ID")
SP_DATASET_ID = os.getenv("SP_DATASET_ID")
TARGET_DATASET_ID = os.getenv("TARGET_DATASET_ID")


# --- Project Configuration ---
with DAG(
    dag_id="ssis_skeleton_fact_delivery_performance",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "fact_delivery_performance"],
    params={
        "ProcessId": 0,
        "Force":1,
    },
) as dag:

    # ref_id: Package\Get Next ProcessID — metadata ExecuteSQLTask (DECLARE + MAX from Staging.LoadLog + CASE NextProcessId)
    op_0 = BigQueryInsertJobOperator(
        task_id="package_get_next_processid",
        configuration={
            "query": {
                "query": (
                    f"SELECT CASE WHEN {{{{ params.ProcessId }}}} > 0 THEN {{{{ params.ProcessId }}}} "
                    f"ELSE COALESCE((SELECT MAX(ProcessId) FROM `{TARGET_DATASET_ID}.Staging_LoadLog`), 0) + 1 "
                    f"END AS NextProcessId"
                ),
                "useLegacySql": False,
            }
        },
    )

    # ref_id: Package\Load_Fact_Delivery_Performance — metadata: Exec [dbo].[Load_Fact_Delivery_Performance] (ReturnCode + ProcessId)
    op_1 = BigQueryInsertJobOperator(
        task_id="package_load_fact_delivery_performance",
        configuration={
            "query": {
                "query": f"CALL `{SP_DATASET_ID}.dbo_Load_Fact_Delivery_Performance`({{{{ params.ProcessId }}}}, {{{{ params.Force }}}});",
                "useLegacySql": False,
            }
        },
    )

    op_0 >> op_1
