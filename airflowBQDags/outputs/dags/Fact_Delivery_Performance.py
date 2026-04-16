"""
Skeleton DAG for SSIS package: Fact_Delivery_Performance
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "Fact_Delivery_Performance"

with DAG(
    dag_id="ssis_skeleton_fact_delivery_performance",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "fact_delivery_performance"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    # ref_id: Package\\Get Next ProcessID
    op_0 = EmptyOperator(task_id="package_get_next_processid")

    # ref_id: Package\\Load_Fact_Delivery_Performance
    op_1 = EmptyOperator(task_id="package_load_fact_delivery_performance")

    # --- precedence (upstream >> downstream) ---
    op_0 >> op_1
