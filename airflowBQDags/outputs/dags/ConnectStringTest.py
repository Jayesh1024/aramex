"""
Skeleton DAG for SSIS package: ConnectStringTest
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "ConnectStringTest"

with DAG(
    dag_id="ssis_skeleton_connectstringtest",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "connectstringtest"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    # ref_id: Package\\Execute SQL Task
    op_0 = EmptyOperator(task_id="package_execute_sql_task")

    # ref_id: Package\\Load tblCustomer_stg
    op_1 = EmptyOperator(task_id="package_load_tblcustomer_stg")

    # --- precedence (upstream >> downstream) ---
    op_0 >> op_1
