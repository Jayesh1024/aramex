"""
Skeleton DAG for SSIS package: LoadGokuTables
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime
from airflow import DAG
from airflow.models import Variable
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup


GCP_PROJECT_ID = Variable.get("PROJECT_ID")

with DAG(
    dag_id="ssis_skeleton_loadgokutables",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "loadgokutables"],
    params={
        "Disable_ClickAndCollect": 0,
        "Disable_PayZone": 0,
        "IsReload": 0,
        "ProcessID": -7,
    },
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    # ref_id: Package\\Check if Secondary
    op_0 = EmptyOperator(task_id="package_check_if_secondary")

    with TaskGroup(group_id="tg_package_clickandcollect_table"):
        # STOCK:SEQUENCE — ref_id: Package\\ClickAndCollect Table
        op_1 = EmptyOperator(task_id="package_clickandcollect_table")

        # ref_id: Package\\ClickAndCollect Table\\Get ClickAndConnect
        op_2 = EmptyOperator(task_id="package_clickandcollect_table_get_clickandconnect")

        # ref_id: Package\\ClickAndCollect Table\\Load Target Table
        op_3 = EmptyOperator(task_id="package_clickandcollect_table_load_target_table")

        # ref_id: Package\\ClickAndCollect Table\\Truncate FWFastlabel_ClickAndCollect_Stg
        op_4 = EmptyOperator(task_id="package_clickandcollect_table_truncate_fwfastlabel_clickandcollect_stg")

    # ref_id: Package\\Get Last CT Version
    op_5 = EmptyOperator(task_id="package_get_last_ct_version")

    # ref_id: Package\\Get Next CT Version
    op_6 = EmptyOperator(task_id="package_get_next_ct_version")

    with TaskGroup(group_id="tg_package_payzone_agents"):
        # STOCK:SEQUENCE — ref_id: Package\\Payzone_agents
        op_7 = EmptyOperator(task_id="package_payzone_agents")

        # ref_id: Package\\Payzone_agents\\Load Target Table
        op_8 = EmptyOperator(task_id="package_payzone_agents_load_target_table")

        # ref_id: Package\\Payzone_agents\\payzone_agents
        op_10 = EmptyOperator(task_id="package_payzone_agents_payzone_agents")

        # ref_id: Package\\Payzone_agents\\Truncate payzone_agents_stg
        op_9 = EmptyOperator(task_id="package_payzone_agents_truncate_payzone_agents_stg")

    with TaskGroup(group_id="tg_package_payzone_regions"):
        # STOCK:SEQUENCE — ref_id: Package\\Payzone_regions
        op_11 = EmptyOperator(task_id="package_payzone_regions")

        # ref_id: Package\\Payzone_regions\\Load Target Table
        op_12 = EmptyOperator(task_id="package_payzone_regions_load_target_table")

        # ref_id: Package\\Payzone_regions\\payzone_regions
        op_14 = EmptyOperator(task_id="package_payzone_regions_payzone_regions")

        # ref_id: Package\\Payzone_regions\\Truncate payzone_regions_stg
        op_13 = EmptyOperator(task_id="package_payzone_regions_truncate_payzone_regions_stg")

    # ref_id: Package\\Set Next CT_Version
    op_15 = EmptyOperator(task_id="package_set_next_ct_version")

    # --- precedence (upstream >> downstream) ---
    op_6 >> op_1
    op_4 >> op_2
    op_2 >> op_3
    op_0 >> op_5
    op_5 >> op_6
    op_6 >> op_7
    op_10 >> op_8
    op_9 >> op_10
    op_6 >> op_11
    op_14 >> op_12
    op_13 >> op_14
    op_11 >> op_15
    op_1 >> op_15
    op_7 >> op_15
