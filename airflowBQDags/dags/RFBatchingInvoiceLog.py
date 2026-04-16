"""
Skeleton DAG for SSIS package: RFBatchingInvoiceLog
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "RFBatchingInvoiceLog"

with DAG(
    dag_id="ssis_skeleton_rfbatchinginvoicelog",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "rfbatchinginvoicelog"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_final"):
        # STOCK:SEQUENCE — ref_id: Package\\Final
        op_0 = EmptyOperator(task_id="package_final")

        # ref_id: Package\\Final\\Load  LNK_RFBatchingInvoiceLog
        op_1 = EmptyOperator(task_id="package_final_load_lnk_rfbatchinginvoicelog")

    with TaskGroup(group_id="tg_package_staging"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging
        op_2 = EmptyOperator(task_id="package_staging")

        # ref_id: Package\\Staging\\Load RFBatchingInvoice_Stg
        op_3 = EmptyOperator(task_id="package_staging_load_rfbatchinginvoice_stg")

        # ref_id: Package\\Staging\\Truncate RFBatchingInvoiceLog_Stg
        op_4 = EmptyOperator(task_id="package_staging_truncate_rfbatchinginvoicelog_stg")

    # --- precedence (upstream >> downstream) ---
    op_2 >> op_0
    op_4 >> op_3
