"""
Skeleton DAG for SSIS package: HUB_ZenTickets
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "HUB_ZenTickets"

with DAG(
    dag_id="ssis_skeleton_hub_zentickets",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_zentickets"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_final"):
        # STOCK:SEQUENCE — ref_id: Package\\Final
        op_0 = EmptyOperator(task_id="package_final")

        # ref_id: Package\\Final\\(ZENLog)
        op_1 = EmptyOperator(task_id="package_final_zenlog")

        # ref_id: Package\\Final\\Load HUB_Zen_Tickets
        op_2 = EmptyOperator(task_id="package_final_load_hub_zen_tickets")

        # ref_id: Package\\Final\\Load SAT_Zen_Tickets
        op_3 = EmptyOperator(task_id="package_final_load_sat_zen_tickets")

    with TaskGroup(group_id="tg_package_staging"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging
        op_4 = EmptyOperator(task_id="package_staging")

        # ref_id: Package\\Staging\\Get Last Run Date (ZENLog)
        op_5 = EmptyOperator(task_id="package_staging_get_last_run_date_zenlog")

        # ref_id: Package\\Staging\\Get ProcessID
        op_6 = EmptyOperator(task_id="package_staging_get_processid")

        # ref_id: Package\\Staging\\Load Zen_Ticket_Stg
        op_7 = EmptyOperator(task_id="package_staging_load_zen_ticket_stg")

        # ref_id: Package\\Staging\\Truncate ZEN_Ticket_Stg
        op_8 = EmptyOperator(task_id="package_staging_truncate_zen_ticket_stg")

    # --- precedence (upstream >> downstream) ---
    op_4 >> op_0
    op_2 >> op_1
    op_3 >> op_1
    op_8 >> op_5
    op_5 >> op_7
    op_6 >> op_8
