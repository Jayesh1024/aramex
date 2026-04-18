"""
Completed DAG for SSIS package: Interim_Fact_Scan_KPI
Migration: SSIS -> BigQuery

Mirrors Fact_Scan_KPI but:
  * Allocates a *negative sentinel* ProcessID (MIN(ProcessID) - 1 WHERE
    ProcessID < -99999) same as HUB_BLKContainerManifest.
  * Set Last ID target is [InterimStaging].[Interim_Set_LastValue]
    (InterimStaging_Interim_Set_LastValue). Other three args (ColumnName,
    LastValue, Force) are all NULL/0 in SSIS.
  * Uses the same Staging_Load_KPI_Labels_Stg / Staging_Load_Fact_Scan_KPI_Stg
    / dbo_Load_Fact_Scan_KPI SPs as the non-interim package.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup

PROJECT_ID = "searce-sandbox-da-delivery"
SP_DATASET_ID = "Aramex_oceania_SP"
TARGET_DATASET_ID = "Aramex_oceania"
PACKAGE_NAME = "Interim_Fact_Scan_KPI"

RECORD_SOURCE_3 = "RecordSource"

_TASK_ID_GET_PROCESS_ID = "tg_package_staging.package_staging_get_processid"


def _allocate_processid(project_id: str, dataset_id: str) -> int:
    hook = BigQueryHook(project_id=project_id)
    query = (
        "SELECT IFNULL(MIN(ProcessID), -99999) - 1 AS ProcessID "
        f"FROM `{project_id}.{dataset_id}.Staging_LoadLog` "
        "WHERE ProcessID < -99999"
    )
    df = hook.get_df(sql=query, dialect="standard")
    return int(df.iloc[0, 0])


with DAG(
    dag_id="ssis_skeleton_interim_fact_scan_kpi",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "interim_fact_scan_kpi"],
    params={
        "record_source_3": RECORD_SOURCE_3,
        "since_scan_date": "2019-01-01",
        "until_scan_date": "2019-01-01",
        "use_scan_dates": 0,
    },
) as dag:

    _xcom_processid = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_PROCESS_ID}') }}}}"

    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE — ref_id: Package\Staging

        # ref_id: Package\Staging\Get ProcessID — negative sentinel (< -99999)
        op_5 = PythonOperator(
            task_id="package_staging_get_processid",
            python_callable=_allocate_processid,
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
                        f"'{{{{ params.since_scan_date }}}}', "
                        f"'{{{{ params.until_scan_date }}}}', "
                        f"{{{{ params.use_scan_dates }}}});"
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

        # ref_id: Package\Staging\Defrag Indexes — BQ no-op
        op_4 = EmptyOperator(task_id="package_staging_defrag_indexes")

        op_5 >> op_8 >> op_7 >> op_6 >> op_4

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

        # ref_id: Package\Final\Set Last ID (TrackAndTraceID) — InterimStaging_Interim_Set_LastValue(RecordSource, NULL, NULL, 0)
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_set_last_id_trackandtraceid",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.InterimStaging_Interim_Set_LastValue`("
                        f"'{{{{ params.record_source_3 }}}}', NULL, NULL, FALSE);"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        op_1 >> op_2

    tg_staging >> tg_final
