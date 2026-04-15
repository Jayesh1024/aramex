"""
Skeleton DAG for SSIS package: HUB_ServiceItem
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "HUB_ServiceItem"

with DAG(
    dag_id="ssis_skeleton_hub_serviceitem",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_serviceitem"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_final"):
        # STOCK:SEQUENCE — ref_id: Package\\Final
        op_0 = EmptyOperator(task_id="package_final")

        # ref_id: Package\\Final\\Load HUB_ServiceItem
        op_1 = EmptyOperator(task_id="package_final_load_hub_serviceitem")

        # ref_id: Package\\Final\\Load SAT_ServiceItem
        op_2 = EmptyOperator(task_id="package_final_load_sat_serviceitem")

    with TaskGroup(group_id="tg_package_staging"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging
        op_3 = EmptyOperator(task_id="package_staging")

        # ref_id: Package\\Staging\\Load fl_ServiceItem_Stg
        op_4 = EmptyOperator(task_id="package_staging_load_fl_serviceitem_stg")

        # ref_id: Package\\Staging\\Truncate fl_ServiceItem_Stg
        op_5 = EmptyOperator(task_id="package_staging_truncate_fl_serviceitem_stg")

    # --- precedence (upstream >> downstream) ---
    op_3 >> op_0
    op_5 >> op_4
