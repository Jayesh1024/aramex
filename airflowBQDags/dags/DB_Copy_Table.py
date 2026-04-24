"""
Completed DAG for SSIS package: DB_Copy_Table
Migration: SSIS -> BigQuery

Built from:
  - outputs/DB_Copy_Table/executable_dependencies.json
  - outputs/DB_Copy_Table/package_metadata.json

Top-level package executables are independent (no package-level edges in executable_dependencies.json).
Inside Sequence Container: Get Next ID -> Load iLocate -> Update LNK_Scan.
Truncate Stg has no dependency edges in executable_dependencies.json.
"""
from __future__ import annotations

from datetime import datetime
import os

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup

from utils.getValue import get_working_load_ilocate_next_id

# --- Project Configuration ---
PROJECT_ID = os.getenv("PROJECT_ID")
SP_DATASET_ID = os.getenv("SP_DATASET_ID")
TARGET_DATASET_ID = os.getenv("TARGET_DATASET_ID")

_TASK_ID_GET_NEXT_ID = "tg_package_sequence_container.package_sequence_container_get_next_id"

with DAG(
    dag_id="ssis_skeleton_db_copy_table",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "db_copy_table"],
    params={
        "LastUndTcktId": 896498,
        "NextId": 3346000000,
    },
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    # ref_id: Package\Copy Table
    op_0 = BigQueryInsertJobOperator(
        task_id="package_copy_table",
        configuration={
            "query": {
                "query": (
                    f"INSERT INTO `{TARGET_DATASET_ID}.dv_temp_SAT_Label_Allocation_DL_Copy` "
                    f"SELECT * FROM `{TARGET_DATASET_ID}.dv_SAT_Label_Allocation_DL`;"
                ),
                "useLegacySql": False,
            }
        },
    )

    # ref_id: Package\Data Flow Task
    op_1 = BigQueryInsertJobOperator(
        task_id="package_data_flow_task",
        configuration={
            "query": {
                "query": f"CALL `{SP_DATASET_ID}.sp_load_dv_LNK_InvoiceHead`();",
                "useLegacySql": False,
            }
        },
    )

    # ref_id: Package\FMS_UndTcktInvoice_Load
    op_2 = BigQueryInsertJobOperator(
        task_id="package_fms_undtcktinvoice_load",
        configuration={
            "query": {
                "query": (
                    f"CALL `{SP_DATASET_ID}.sp_load_Staging_FMS_UndTcktInvoice_Stg__2`("
                    f"{{{{ params.LastUndTcktId }}}});"
                ),
                "useLegacySql": False,
            }
        },
    )

    # ref_id: Package\Load FMS_InvoiceHead
    op_3 = BigQueryInsertJobOperator(
        task_id="package_load_fms_invoicehead",
        configuration={
            "query": {
                "query": f"CALL `{SP_DATASET_ID}.sp_load_Staging_FMS_InvoiceHead_Stg_All`();",
                "useLegacySql": False,
            }
        },
    )

    with TaskGroup(group_id="tg_package_sequence_container"):
        # STOCK:SEQUENCE — ref_id: Package\Sequence Container
        op_4 = EmptyOperator(task_id="package_sequence_container")

        # ref_id: Package\Sequence Container\Get Next ID
        op_5 = PythonOperator(
            task_id="package_sequence_container_get_next_id",
            python_callable=get_working_load_ilocate_next_id,
            op_kwargs={
                "project_id": PROJECT_ID,
                "dataset_id": TARGET_DATASET_ID,
            },
        )

        # ref_id: Package\Sequence Container\Load iLocate
        op_6 = BigQueryInsertJobOperator(
            task_id="package_sequence_container_load_ilocate",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.sp_load_working_Load_iLocate_Stg`("
                        f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_NEXT_ID}') }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Sequence Container\Truncate Stg
        op_7 = BigQueryInsertJobOperator(
            task_id="package_sequence_container_truncate_stg",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.working_Load_iLocate_Stg`;",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Sequence Container\Update LNK_Scan
        _end_id = f"{{{{ (ti.xcom_pull(task_ids='{_TASK_ID_GET_NEXT_ID}') | int) + 4000000 }}}}"
        op_8 = BigQueryInsertJobOperator(
            task_id="package_sequence_container_update_lnk_scan",
            configuration={
                "query": {
                    "query": (
                        f"DECLARE end_id INT64; "
                        f"SET end_id = {_end_id}; "
                        f"UPDATE `{TARGET_DATASET_ID}.dv_LNK_Scan` AS LNK "
                        f"SET iLocate = S.iLocate "
                        f"FROM `{TARGET_DATASET_ID}.working_Load_iLocate_Stg` AS S "
                        f"WHERE S.ID = LNK.TrackAndTraceID; "
                        f"UPDATE `{TARGET_DATASET_ID}.working_Load_iLocate_NextID` "
                        f"SET LastID = end_id;"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # executable_dependencies.json (sequence container)
        op_5 >> op_6 >> op_8
