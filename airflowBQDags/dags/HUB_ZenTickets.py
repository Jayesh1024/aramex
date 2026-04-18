"""
Completed DAG for SSIS package: HUB_ZenTickets
Migration: SSIS -> BigQuery

Mirrors the HUB_BLKContainerManifest pattern:
  * Custom negative-sentinel ProcessID allocation.
  * Staging_Get_LastValue for the incremental watermark.
  * OLEDB pipeline with a `LastDate` parameter, wrapped as a BQ SP.
  * Custom UPDATE on Staging.LoadControl after the Finals complete — SSIS
    `(ZENLog)` task uses a literal RecordSource = 'ZenLog'.

The two Final loads (HUB and SAT) both feed the ZENLog updater; HUB and SAT
have no edge between them in the SSIS dependency graph, so they run in
parallel.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup
from utils.getValue import get_last_value

PROJECT_ID = "searce-sandbox-da-delivery"
SP_DATASET_ID = "Aramex_oceania_SP"
TARGET_DATASET_ID = "Aramex_oceania"
PACKAGE_NAME = "HUB_ZenTickets"
RECORD_SOURCE_1 = "RecordSource"
# Hardcoded inside the SSIS "(ZENLog)" task body — not a $Package parameter.
ZENLOG_RECORD_SOURCE = "ZenLog"

_TASK_ID_GET_PROCESS_ID = "tg_package_staging.package_staging_get_processid"
_TASK_ID_GET_LAST_RUN = "tg_package_staging.package_staging_get_last_run_date_zenlog"


def _allocate_zen_processid(project_id: str, dataset_id: str) -> int:
    """Same negative-sentinel scheme as HUB_BLKContainerManifest:
        SELECT MIN(ProcessID) - 1 FROM Staging.LoadLog WHERE ProcessID < -99999."""
    hook = BigQueryHook(project_id=project_id)
    query = (
        "SELECT IFNULL(MIN(ProcessID), -99999) - 1 AS ProcessID "
        f"FROM `{project_id}.{dataset_id}.Staging_LoadLog` "
        "WHERE ProcessID < -99999"
    )
    df = hook.get_df(sql=query, dialect="standard")
    return int(df.iloc[0, 0])


with DAG(
    dag_id="ssis_skeleton_hub_zentickets",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_zentickets"],
    params={
        "record_source": RECORD_SOURCE_1,
    },
) as dag:

    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE — ref_id: Package\Staging

        op_6 = PythonOperator(
            task_id="package_staging_get_processid",
            python_callable=_allocate_zen_processid,
            op_kwargs={
                "project_id": PROJECT_ID,
                "dataset_id": TARGET_DATASET_ID,
            },
        )

        op_8 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_zen_ticket_stg",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_ZEN_Ticket_Stg`;",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging\Get Last Run Date (ZENLog) — Staging_Get_LastValue
        op_5 = PythonOperator(
            task_id="package_staging_get_last_run_date_zenlog",
            python_callable=get_last_value,
            op_kwargs={
                "project_id": PROJECT_ID,
                "dataset_id": SP_DATASET_ID,
                "record_source": "{{ params.record_source }}",
            },
        )

        # ref_id: Package\Staging\Load Zen_Ticket_Stg (Pipeline -> SP, takes LastDate)
        op_7 = BigQueryInsertJobOperator(
            task_id="package_staging_load_zen_ticket_stg",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_Load_ZEN_Ticket_Stg`("
                        f"SAFE_CAST('{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_LAST_RUN}') }}}}' AS DATETIME));"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        op_6 >> op_8 >> op_5 >> op_7

    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\Final

        _xcom_processid = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_PROCESS_ID}') }}}}"

        # ref_id: Package\Final\Load HUB_Zen_Tickets — EXEC [dv].[Load_HUB_ZEN_Ticket] ProcessId, RecordSource
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_load_hub_zen_tickets",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_HUB_ZEN_Ticket`("
                        f"{_xcom_processid}, '{{{{ params.record_source }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final\Load SAT_Zen_Tickets — EXEC [dv].[Load_SAT_ZEN_Ticket] ProcessId, RecordSource
        op_3 = BigQueryInsertJobOperator(
            task_id="package_final_load_sat_zen_tickets",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_SAT_ZEN_Ticket`("
                        f"{_xcom_processid}, '{{{{ params.record_source }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final\(ZENLog) — UPDATE Staging.LoadControl LastValue
        #   with MAX(SysLastUpdatedUtc) from Staging.ZEN_Ticket_Stg, WHERE RecordSource = 'ZenLog'.
        op_1 = BigQueryInsertJobOperator(
            task_id="package_final_zenlog",
            configuration={
                "query": {
                    "query": (
                        f"UPDATE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_LoadControl` "
                        "SET LastValue = CAST(("
                        "SELECT FORMAT_DATETIME('%Y-%m-%d %H:%M:%E3S', MAX(SysLastUpdatedUtc)) "
                        f"FROM `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_ZEN_Ticket_Stg`"
                        ") AS STRING) "
                        f"WHERE RecordSource = '{ZENLOG_RECORD_SOURCE}';"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        [op_2, op_3] >> op_1

    tg_staging >> tg_final
