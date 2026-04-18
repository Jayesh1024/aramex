"""
Skeleton DAG for SSIS package: HUB_Label_MF_ONLY
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "HUB_Label_MF_ONLY"

with DAG(
    dag_id="ssis_skeleton_hub_label_mf_only",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_label_mf_only"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_sequence_container"):
        # STOCK:SEQUENCE — ref_id: Package\\Sequence Container
        op_0 = EmptyOperator(task_id="package_sequence_container")

        # ref_id: Package\\Sequence Container\\Load SAT_Label_Allocation
        op_1 = EmptyOperator(task_id="package_sequence_container_load_sat_label_allocation")

        # ref_id: Package\\Sequence Container\\Load SAT_Label_Allocation_MF
        op_2 = EmptyOperator(task_id="package_sequence_container_load_sat_label_allocation_mf")

        # ref_id: Package\\Sequence Container\\Load SAT_Label_Allocation_Stg
        op_3 = EmptyOperator(task_id="package_sequence_container_load_sat_label_allocation_stg")

        # ref_id: Package\\Sequence Container\\Set LastDate (MyFastway)
        op_4 = EmptyOperator(task_id="package_sequence_container_set_lastdate_myfastway")

        # ref_id: Package\\Sequence Container\\Truncate SAT_Label_Allocation_Stg
        op_5 = EmptyOperator(task_id="package_sequence_container_truncate_sat_label_allocation_stg")

    with TaskGroup(group_id="tg_package_source4_myfastway_mf"):
        # STOCK:SEQUENCE — ref_id: Package\\Source4 (MyFastway) _MF
        op_6 = EmptyOperator(task_id="package_source4_myfastway_mf")

        # ref_id: Package\\Source4 (MyFastway) _MF\\Load fl_ConItem_Stg
        op_7 = EmptyOperator(task_id="package_source4_myfastway_mf_load_fl_conitem_stg")

        # ref_id: Package\\Source4 (MyFastway) _MF\\Rebuild Indexes 4
        op_8 = EmptyOperator(task_id="package_source4_myfastway_mf_rebuild_indexes_4")

        # ref_id: Package\\Source4 (MyFastway) _MF\\Truncate fl_ConItem_Stg
        op_9 = EmptyOperator(task_id="package_source4_myfastway_mf_truncate_fl_conitem_stg")

    # --- precedence (upstream >> downstream) ---
    op_6 >> op_0
    op_3 >> op_1
    op_1 >> op_2
    op_5 >> op_3
    op_2 >> op_4
    op_9 >> op_7
    op_7 >> op_8
