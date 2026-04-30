"""
Completed DAG for SSIS package: Fact_Scan_KPI
Migration: SSIS -> BigQuery

Table names use schema_tablename (e.g. Staging_KPI_Labels_Stg). Procedures use schema_proc (e.g. dbo_Load_Fact_Scan_KPI,
Staging_Load_KPI_Labels_Stg). Precedence follows executable_dependencies.json (Staging chain, then Final).

No RecordSource in package metadata.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.models import Variable
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup

GCP_PROJECT_ID = Variable.get("PROJECT_ID")
SP_DATASET_ID = Variable.get("SP_DATASET_ID")
TARGET_DATASET_ID = Variable.get("TARGET_DATASET_ID")


# --- Project Configuration ---
with DAG(
    dag_id="ssis_skeleton_fact_scan_kpi",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "fact_scan_kpi"],
    params={
        "DisableFinal": 0,
        "DisableStaging": 0,
        "ProcessId": 706,
        # BigQuery DATETIME parsing expects 24h datetime text (not AM/PM time-only values).
        "SinceScanDate": "1900-01-01 00:00:00",
        "UntilScanDate": "1900-01-01 00:00:00",
        "UseScanDates": 0,
    },
) as dag:

    # --- Package\Staging ---
    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE — ref_id: Package\Staging

        # ref_id: Package\Staging\Truncate KPI Staging Tables — [Staging].[KPI_Labels_Stg], [Staging].[Fact_Scan_KPI_Stg]
        op_1 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_kpi_staging_tables",
            gcp_conn_id="oceania_target_sa_connection",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_KPI_Labels_Stg`;\n"
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_Fact_Scan_KPI_Stg`;"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Staging\Load KPI_Labels_Stg — Exec [Staging].[Load_KPI_Labels_Stg] (ProcessId, SinceScanDate, UntilScanDate, UseScanDates)
        op_2 = BigQueryInsertJobOperator(
            task_id="package_staging_load_kpi_labels_stg",
            gcp_conn_id="oceania_target_sa_connection",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.Staging_Load_KPI_Labels_Stg`({{{{ dag_run.conf.get('process_id', params.ProcessId) }}}}, '{{{{ params.SinceScanDate }}}}', '{{{{ params.UntilScanDate }}}}', {{{{ params.UseScanDates }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Staging\Load Fact_Scan_KPI_Stg — Exec [Staging].[Load_Fact_Scan_KPI_Stg]
        op_3 = BigQueryInsertJobOperator(
            task_id="package_staging_load_fact_scan_kpi_stg",
            gcp_conn_id="oceania_target_sa_connection",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.Staging_Load_Fact_Scan_KPI_Stg`({{{{ dag_run.conf.get('process_id', params.ProcessId) }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )


    # --- Package\Final ---
    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\Final

        # ref_id: Package\Final\Load Fact_Scan_KPI — Exec [dbo].[Load_Fact_Scan_KPI]
        op_4 = BigQueryInsertJobOperator(
            task_id="package_final_load_fact_scan_kpi",
            gcp_conn_id="oceania_target_sa_connection",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dbo_Load_Fact_Scan_KPI`({{{{ dag_run.conf.get('process_id', params.ProcessId) }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

    # --- Precedence (executable_dependencies: Truncate → KPI_Labels → Fact_Scan_KPI_Stg → Defrag → Final) ---
    op_1 >> op_2 >> op_3 >> op_4

    # TaskGroup-level precedence
    tg_staging >> tg_final
