"""
Completed DAG for SSIS package: Fact_KPI
Migration: SSIS -> BigQuery

Staging flow: Truncate -> Load KPI_Labels_Src_Stg -> Load Fact_KPI_Daily_Stg.
Final flow  : Load Fact KPI Labels -> Load Fact_KPI_Priority -> Load Fact KPI Performance.

The SSIS "Defrag Indexes" task has been dropped — BigQuery has no indexes.

SPs resolved against `ProceduresBQ/sp_json.json` and `SP.json`:
  * Staging_Load_Fact_KPI_Src_Stg(p_ProcessID INT64, p_StartDateOverRide STRING, p_EndDateOverRide STRING)
  * Staging_Load_Fact_KPI_Daily_Stg(p_ProcessID INT64, p_StartDateOverRide STRING, p_EndDateOverRide STRING)
      — sp_json.json declares 3 params; SSIS only binds ProcessId, so the two
        date overrides are passed through from DAG params (default to the
        SSIS default "1900-01-01" sentinel).
  * dbo_Load_Fact_KPI_Performance(p_ProcessID INT64)
  * dbo_Load_Fact_KPI_Priority(p_ProcessId INT64)
  * "Load Fact KPI Labels" calls [dbo].[Load_Fact_KPI_Daily] ProcessId —
    **`dbo_Load_Fact_KPI_Daily` is NOT in any SP JSON**; using
    `schema_object` naming convention. Flag for validation.
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


with DAG(
    dag_id="ssis_skeleton_fact_kpi",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "fact_kpi"],
    params={
        "DisableFinal": 0,
        "DisableStaging": 0,
        "EndDateOverRide": None,
        "ProcessId": 2574,
        "StartDateOverRide": None,
        "start_date_override": "1900-01-01",
        "end_date_override": "1900-01-01",
    },
) as dag:

    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE — ref_id: Package\Staging

        # ref_id: Package\Staging\Truncate KPI Staging Tables
        op_8 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_kpi_staging_tables",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_Fact_KPI_Src_Stg`;\n"
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_Fact_KPI_Stg`;"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Staging\Load KPI_Labels_Src_Stg — Exec [Staging].[Load_Fact_KPI_Src_Stg] ProcessId, StartDateOverRide, EndDateOverRide
        op_7 = BigQueryInsertJobOperator(
            task_id="package_staging_load_kpi_labels_src_stg",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.Staging_Load_Fact_KPI_Src_Stg`("
                        f"{{{{ dag_run.conf.get('process_id', params.ProcessId) }}}}, "
                        f"'{{{{ params.StartDateOverRide }}}}', "
                        f"'{{{{ params.EndDateOverRide }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Staging\Load Fact_KPI_Daily_Stg — Exec [Staging].[Load_Fact_KPI_Daily_Stg] ProcessId
        op_6 = BigQueryInsertJobOperator(
            task_id="package_staging_load_fact_kpi_daily_stg",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.Staging_Load_Fact_KPI_Daily_Stg`("
                        f"{{{{ dag_run.conf.get('process_id', params.ProcessId) }}}}, "
                        f"'{{{{ params.StartDateOverRide }}}}', "
                        f"'{{{{ params.EndDateOverRide }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        op_8 >> op_7 >> op_6

    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\Final

        # ref_id: Package\Final\Load Fact KPI Labels — Exec [dbo].[Load_Fact_KPI_Daily] ProcessId
        op_1 = BigQueryInsertJobOperator(
            task_id="package_final_load_fact_kpi_labels",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dbo_Load_Fact_KPI_Daily`("
                        f"{{{{ dag_run.conf.get('process_id', params.ProcessId) }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Final\Load Fact_KPI_Priority — EXEC [dbo].[Load_Fact_KPI_Priority] ProcessId
        op_3 = BigQueryInsertJobOperator(
            task_id="package_final_load_fact_kpi_priority",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dbo_Load_Fact_KPI_Priority`("
                        f"{{{{ dag_run.conf.get('process_id', params.ProcessId) }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Final\Load Fact KPI Performance — Exec [dbo].[Load_Fact_KPI_Performance] ProcessId
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_load_fact_kpi_performance",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dbo_Load_Fact_KPI_Performance`("
                        f"{{{{ dag_run.conf.get('process_id', params.ProcessId) }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        op_1 >> op_3 >> op_2

    tg_staging >> tg_final
