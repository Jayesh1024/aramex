"""
Completed DAG for SSIS package: DB_Copy_Table
Migration: SSIS -> BigQuery

Top-level tasks have no edges in executable_dependencies.json; Load FMS_InvoiceHead must precede Data Flow Task
(metadata: Data Flow reads Staging.FMS_InvoiceHead_Stg_All filled by Load FMS_InvoiceHead). Copy Table and
FMS_UndTcktInvoice_Load are modeled as independent loads. Sequence Container: Truncate → Get Next ID (inline SELECT)
→ Load iLocate → Update LNK_Scan (CALL SPs). SSIS binds Get Next ID result to Load/Update; use params.ilocate_last_id
until you wire XCom or merge logic in BigQuery.

Schema_table / schema_proc naming (e.g. Working_Load_iLocate_Stg, dv_Load_Copy_SAT_Label_Allocation_DL).
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup

# --- Project Configuration ---
PROJECT_ID = "searce-sandbox-da-delivery"
SP_DATASET_ID = "Aramex_oceania_SP"
TARGET_DATASET_ID = "Aramex_oceania"
PACKAGE_NAME = "DB_Copy_Table"

with DAG(
    dag_id="ssis_skeleton_db_copy_table",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "db_copy_table"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    # ref_id: Package\\Copy Table
    op_0 = EmptyOperator(task_id="package_copy_table")

    # ref_id: Package\\Data Flow Task
    op_1 = EmptyOperator(task_id="package_data_flow_task")

    # ref_id: Package\\FMS_UndTcktInvoice_Load
    op_2 = EmptyOperator(task_id="package_fms_undtcktinvoice_load")

    # ref_id: Package\\Load FMS_InvoiceHead
    op_3 = EmptyOperator(task_id="package_load_fms_invoicehead")

    with TaskGroup(group_id="tg_package_sequence_container"):
        # STOCK:SEQUENCE — ref_id: Package\\Sequence Container
        op_4 = EmptyOperator(task_id="package_sequence_container")

        # ref_id: Package\\Sequence Container\\Get Next ID
        op_5 = EmptyOperator(task_id="package_sequence_container_get_next_id")

        # ref_id: Package\\Sequence Container\\Load iLocate
        op_6 = EmptyOperator(task_id="package_sequence_container_load_ilocate")

        # ref_id: Package\\Sequence Container\\Truncate Stg
        op_7 = EmptyOperator(task_id="package_sequence_container_truncate_stg")

        # ref_id: Package\\Sequence Container\\Update LNK_Scan
        op_8 = EmptyOperator(task_id="package_sequence_container_update_lnk_scan")

    # --- precedence (upstream >> downstream) ---
    op_5 >> op_6
    op_6 >> op_8
