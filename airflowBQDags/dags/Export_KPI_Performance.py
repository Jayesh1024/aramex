"""
Completed DAG for SSIS package: Export_KPI_Performance
Migration: SSIS -> BigQuery

Converted tasks:
  - Get Next ProcessID                   -> PythonOperator (MAX(ProcessId)+1)
  - Truncate Staging Tables              -> BigQuery TRUNCATE
  - Load Staging Export                  -> BigQuery CALL dbo_Load_FMS_RFBatchingPerformanceBonus
  - Get Summary Data                     -> BigQuery CALL Staging_Get_ExportReportHtml

Not directly translatable from the `.dtsx` package metadata:
  - Export to KRILLIN (cross-system write to SQL Server target)
  - Send Email (Microsoft.ScriptTask)

Those two remain explicit placeholders (`EmptyOperator`) to preserve control flow.
"""
from __future__ import annotations

from datetime import datetime
import os

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup

from utils.getValue import get_next_process_id

GCP_PROJECT_ID = os.getenv("GCP_PROJECT_ID")
SP_DATASET_ID = os.getenv("SP_DATASET_ID")
TARGET_DATASET_ID = os.getenv("TARGET_DATASET_ID")

_TASK_ID_GET_NEXT_PROCESS_ID = (
    "tg_package_sequence_container.package_sequence_container_get_next_processid"
)
_PROCESS_ID_XCOM = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_NEXT_PROCESS_ID}') }}}}"

with DAG(
    dag_id="ssis_skeleton_export_kpi_performance",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "export_kpi_performance"],
    params={
        "SendLoadEmailTo": "barry_woods@bigpond.com",
    },
) as dag:
    with TaskGroup(group_id="tg_package_sequence_container") as tg_package_sequence_container:
        # ref_id: Package\Sequence Container\Get Next ProcessID
        op_5 = PythonOperator(
            task_id="package_sequence_container_get_next_processid",
            python_callable=get_next_process_id,
            op_kwargs={
                "project_id": GCP_PROJECT_ID,
                "dataset_id": TARGET_DATASET_ID,
            },
        )

        # ref_id: Package\Sequence Container\Truncate Staging Tables
        op_7 = BigQueryInsertJobOperator(
            task_id="package_sequence_container_truncate_staging_tables",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE "
                        f"`{TARGET_DATASET_ID}.Staging_Export_KPI_Delivery_Perf_Data`;"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Sequence Container\Load Staging Export
        # SSIS source SQL: EXEC [dbo].[Load_FMS_RFBatchingPerformanceBonus] @ProcessID
        op_6 = BigQueryInsertJobOperator(
            task_id="package_sequence_container_load_staging_export",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dbo_Load_FMS_RFBatchingPerformanceBonus`("
                        f"{_PROCESS_ID_XCOM});"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Sequence Container\Export to KRILLIN
        # SSIS target is SQL Server dbo.FMS_RFBatchingPerformanceBonus (external to BigQuery migration target).
        op_4 = EmptyOperator(task_id="package_sequence_container_export_to_krillin")

        op_5 >> op_7 >> op_6 >> op_4

    with TaskGroup(group_id="tg_package_send_notification_email") as tg_package_send_notification_email:
        # ref_id: Package\Send Notification Email\Get Summary Data
        # SSIS SQL: Exec [Staging].[Get_ExportReportHtml] ?
        op_1 = BigQueryInsertJobOperator(
            task_id="package_send_notification_email_get_summary_data",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.Staging_Get_ExportReportHtml`("
                        f"{_PROCESS_ID_XCOM});"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Send Notification Email\Send Email
        # Microsoft.ScriptTask from SSIS; requires bespoke SMTP implementation.
        op_2 = EmptyOperator(task_id="package_send_notification_email_send_email")

        op_1 >> op_2

    tg_package_sequence_container >> tg_package_send_notification_email
