"""
Completed DAG for SSIS package: Fact_Delivery_Performance
Migration: SSIS -> BigQuery

Get Next ProcessID (Staging.LoadLog / NextProcessId logic) maps to a BigQuery procedure Staging_GetNextProcessId.
Load_Fact_Delivery_Performance maps to dbo_Load_Fact_Delivery_Performance (schema_proc from [dbo].[Load_Fact_Delivery_Performance]).

No RecordSource in package metadata — only ProcessId-related parameters.
"""
from __future__ import annotations


from airflow import DAG
from airflow.models import Variable
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
import pendulum

GCP_PROJECT_ID = Variable.get("PROJECT_ID")
SP_DATASET_ID = Variable.get("SP_DATASET_ID")
TARGET_DATASET_ID = Variable.get("TARGET_DATASET_ID")


# --- Project Configuration ---
with DAG(
    dag_id="ssis_skeleton_fact_delivery_performance",
    start_date=pendulum.datetime(2026, 4, 1, tz="Pacific/Auckland"),
    schedule_interval="10 0 * * *",
    catchup=False,
    tags=["ssis", "skeleton", "fact_delivery_performance"],
    params={
        "process_id": 0,
        "Force":1,
    },
) as dag:

    # ref_id: Package\Get Next ProcessID — metadata ExecuteSQLTask (DECLARE + MAX from Staging.LoadLog + CASE NextProcessId)
    op_0 = BigQueryInsertJobOperator(
        task_id="package_get_next_processid",
        gcp_conn_id="oceania_target_sa_connection",
        location="europe-west2",
        configuration={
            "query": {
                "query": (
                    f"SELECT CASE WHEN {{{{ dag_run.conf.get('process_id', params.process_id) }}}} > 0 THEN {{{{ dag_run.conf.get('process_id', params.process_id) }}}} "
                    f"ELSE COALESCE((SELECT MAX(ProcessId) FROM `{TARGET_DATASET_ID}.Staging_LoadLog`), 0) + 1 "
                    f"END AS NextProcessId"
                ),
                "useLegacySql": False,
            }
        },
        job_id="bq_gold_transformation_oceania",
    )

    # ref_id: Package\Load_Fact_Delivery_Performance — metadata: Exec [dbo].[Load_Fact_Delivery_Performance] (ReturnCode + ProcessId)
    op_1 = BigQueryInsertJobOperator(
        task_id="package_load_fact_delivery_performance",
        gcp_conn_id="oceania_target_sa_connection",
        location="europe-west2",
        configuration={
            "query": {
                "query": f"CALL `{SP_DATASET_ID}.dbo_Load_Fact_Delivery_Performance`({{{{ dag_run.conf.get('process_id', params.process_id) }}}}, {{{{ params.Force }}}});",
                "useLegacySql": False,
            }
        },
        job_id="bq_gold_transformation_oceania",
    )

    op_0 >> op_1
