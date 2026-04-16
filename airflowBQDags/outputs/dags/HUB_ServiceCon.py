"""
Skeleton DAG for SSIS package: HUB_ServiceCon
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "HUB_ServiceCon"

with DAG(
    dag_id="ssis_skeleton_hub_servicecon",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_servicecon"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_final"):
        # STOCK:SEQUENCE — ref_id: Package\\Final
        op_0 = EmptyOperator(task_id="package_final")

        # ref_id: Package\\Final\\Load HUB_ServiceCon
        op_1 = EmptyOperator(task_id="package_final_load_hub_servicecon")

        # ref_id: Package\\Final\\Load SAT_ServiceCon
        op_2 = EmptyOperator(task_id="package_final_load_sat_servicecon")

        # ref_id: Package\\Final\\Truncate LNK_Product_ServiceCon
        op_3 = EmptyOperator(task_id="package_final_truncate_lnk_product_servicecon")

        # ref_id: Package\\Final\\Truncate LSAT_Product_ServiceCon
        op_4 = EmptyOperator(task_id="package_final_truncate_lsat_product_servicecon")

    with TaskGroup(group_id="tg_package_staging"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging
        op_5 = EmptyOperator(task_id="package_staging")

        # ref_id: Package\\Staging\\Load fl_ConSrv_Stg
        op_6 = EmptyOperator(task_id="package_staging_load_fl_consrv_stg")

        # ref_id: Package\\Staging\\Load_LSAT_Product_ServiceCon
        op_7 = EmptyOperator(task_id="package_staging_load_lsat_product_servicecon")

        # ref_id: Package\\Staging\\Rebuild Indexes 13
        op_8 = EmptyOperator(task_id="package_staging_rebuild_indexes_13")

        # ref_id: Package\\Staging\\Truncate fl_ConSrv_Stg
        op_10 = EmptyOperator(task_id="package_staging_truncate_fl_consrv_stg")

        # ref_id: Package\\Staging\\Truncate Product_ServiceCon_Stg
        op_9 = EmptyOperator(task_id="package_staging_truncate_product_servicecon_stg")

    # --- precedence (upstream >> downstream) ---
    op_5 >> op_0
    op_3 >> op_1
    op_4 >> op_2
    op_1 >> op_4
    op_10 >> op_6
    op_9 >> op_7
    op_6 >> op_8
    op_8 >> op_9
