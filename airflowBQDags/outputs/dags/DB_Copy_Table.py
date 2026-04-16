"""
Skeleton DAG for SSIS package: DB_Copy_Table
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

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
