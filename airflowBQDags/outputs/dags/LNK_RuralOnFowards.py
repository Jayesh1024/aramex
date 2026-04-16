"""
Skeleton DAG for SSIS package: LNK_RuralOnFowards
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "LNK_RuralOnFowards"

with DAG(
    dag_id="ssis_skeleton_lnk_ruralonfowards",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "lnk_ruralonfowards"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_load_la_ruraonforwards"):
        # STOCK:SEQUENCE — ref_id: Package\\Load LA_RuraOnForwards
        op_0 = EmptyOperator(task_id="package_load_la_ruraonforwards")

        # ref_id: Package\\Load LA_RuraOnForwards\\Data Flow Task
        op_1 = EmptyOperator(task_id="package_load_la_ruraonforwards_data_flow_task")

        # ref_id: Package\\Load LA_RuraOnForwards\\Execute SQL Task
        op_2 = EmptyOperator(task_id="package_load_la_ruraonforwards_execute_sql_task")

        # ref_id: Package\\Load LA_RuraOnForwards\\Get LastDate (LA_RuralOnforwards)
        op_3 = EmptyOperator(task_id="package_load_la_ruraonforwards_get_lastdate_la_ruralonforwards")

        # ref_id: Package\\Load LA_RuraOnForwards\\Set LastDate
        op_4 = EmptyOperator(task_id="package_load_la_ruraonforwards_set_lastdate")

        # ref_id: Package\\Load LA_RuraOnForwards\\Truncate Staging Tables
        op_5 = EmptyOperator(task_id="package_load_la_ruraonforwards_truncate_staging_tables")

    with TaskGroup(group_id="tg_package_sequence_container"):
        # STOCK:SEQUENCE — ref_id: Package\\Sequence Container
        op_6 = EmptyOperator(task_id="package_sequence_container")

        # ref_id: Package\\Sequence Container\\Get ProcessID
        op_7 = EmptyOperator(task_id="package_sequence_container_get_processid")

    # --- precedence (upstream >> downstream) ---
    op_6 >> op_0
    op_3 >> op_1
    op_1 >> op_2
    op_5 >> op_3
    op_2 >> op_4
