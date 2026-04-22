"""
Completed DAG for SSIS package: Interim_Fact_Scan_KPI
Migration: SSIS -> BigQuery

Mirrors Fact_Scan_KPI but:
  * Allocates a *negative sentinel* ProcessID (MIN(ProcessID) - 1 WHERE
    ProcessID < -99999) same as HUB_BLKContainerManifest.
  * Set Last ID target is [InterimStaging].[Interim_Set_LastValue]
    (interimStaging_Set_LastValue). Other three args (ColumnName,
    LastValue, Force) are all NULL/0 in SSIS.
  * Uses the same Staging_Load_KPI_Labels_Stg / Staging_Load_Fact_Scan_KPI_Stg
    / dbo_Load_Fact_Scan_KPI SPs as the non-interim package.
"""
from __future__ import annotations

from datetime import datetime
import os

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup
from utils.getValue import allocate_negative_sentinel_processid

PROJECT_ID = os.getenv("PROJECT_ID")
SP_DATASET_ID = os.getenv("SP_DATASET_ID")
TARGET_DATASET_ID = os.getenv("TARGET_DATASET_ID")

_TASK_ID_GET_PROCESS_ID = "tg_package_staging.package_staging_get_processid"


with DAG(
    dag_id="ssis_skeleton_interim_fact_scan_kpi",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "interim_fact_scan_kpi"],
    params={
        "DisableFinal": 0,
        "DisableStaging": 0,
        "ProcessId": 706,
        "RecordSource3": 'TrackAndTraceID',
        "SinceScanDate": "1900-01-01 00:00:00",
        "UntilScanDate": "1900-01-01 00:00:00",
        "UseScanDates": 0,
    },
) as dag:

    _xcom_processid = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_PROCESS_ID}') }}}}"

    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE — ref_id: Package\Staging

        # ref_id: Package\Staging\Get ProcessID — negative sentinel (< -99999)
        op_5 = PythonOperator(
            task_id="package_staging_get_processid",
            python_callable=allocate_negative_sentinel_processid,
            op_kwargs={
                "project_id": PROJECT_ID,
                "dataset_id": TARGET_DATASET_ID,
            },
        )

        # ref_id: Package\Staging\Truncate KPI Staging Tables
        op_8 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_kpi_staging_tables",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_KPI_Labels_Stg`;\n"
                        f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_Fact_Scan_KPI_Stg`;"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging\Load KPI_Labels_Stg — Staging_Load_KPI_Labels_Stg(ProcessId, SinceScanDate, UntilScanDate, UseScanDates)
        op_7 = BigQueryInsertJobOperator(
            task_id="package_staging_load_kpi_labels_stg",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_Load_KPI_Labels_Stg`("
                        f"{_xcom_processid}, "
                        f"'{{{{ params.SinceScanDate }}}}', "
                        f"'{{{{ params.UntilScanDate }}}}', "
                        f"{{{{ params.UseScanDates }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging\Load Fact_Scan_KPI_Stg — Staging_Load_Fact_Scan_KPI_Stg(ProcessId)
        op_6 = BigQueryInsertJobOperator(
            task_id="package_staging_load_fact_scan_kpi_stg",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_Load_Fact_Scan_KPI_Stg`("
                        f"{_xcom_processid});"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        op_5 >> op_8 >> op_7 >> op_6

    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\Final

        # ref_id: Package\Final\Load Fact_Scan_KPI — dbo_Load_Fact_Scan_KPI(ProcessId)
        op_1 = BigQueryInsertJobOperator(
            task_id="package_final_load_fact_scan_kpi",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dbo_Load_Fact_Scan_KPI`("
                        f"{_xcom_processid});"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final\Set Last ID (TrackAndTraceID) — interimStaging_Set_LastValue(RecordSource, NULL, NULL, 0)
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_set_last_id_trackandtraceid",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.interimStaging_Set_LastValue`("
                        f"'{{{{ params.RecordSource3 }}}}', NULL, NULL, FALSE);"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        op_1 >> op_2

    tg_staging >> tg_final
