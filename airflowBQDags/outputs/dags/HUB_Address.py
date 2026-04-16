"""
Skeleton DAG for SSIS package: HUB_Address
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "HUB_Address"

with DAG(
    dag_id="ssis_skeleton_hub_address",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_address"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_final_load_hub_address"):
        # STOCK:SEQUENCE — ref_id: Package\\Final (Load HUB_Address)
        op_0 = EmptyOperator(task_id="package_final_load_hub_address")

        # ref_id: Package\\Final (Load HUB_Address)\\Load HUB_Address
        op_1 = EmptyOperator(task_id="package_final_load_hub_address_load_hub_address")

        # ref_id: Package\\Final (Load HUB_Address)\\Load LNK_Label_Address
        op_2 = EmptyOperator(task_id="package_final_load_hub_address_load_lnk_label_address")

        # ref_id: Package\\Final (Load HUB_Address)\\Load SAT_Address
        op_3 = EmptyOperator(task_id="package_final_load_hub_address_load_sat_address")

        # ref_id: Package\\Final (Load HUB_Address)\\Rebuild Indexes
        op_4 = EmptyOperator(task_id="package_final_load_hub_address_rebuild_indexes")

    with TaskGroup(group_id="tg_package_staging"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging
        op_5 = EmptyOperator(task_id="package_staging")

        # ref_id: Package\\Staging\\Load SAT_Label_Address_Stg
        op_6 = EmptyOperator(task_id="package_staging_load_sat_label_address_stg")

        # ref_id: Package\\Staging\\Truncate Label_Address_Stg
        op_7 = EmptyOperator(task_id="package_staging_truncate_label_address_stg")

    # --- precedence (upstream >> downstream) ---
    op_5 >> op_0
    op_4 >> op_1
    op_3 >> op_2
    op_4 >> op_3
    op_7 >> op_6
