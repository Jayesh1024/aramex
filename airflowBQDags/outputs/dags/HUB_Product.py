"""
Skeleton DAG for SSIS package: HUB_Product
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "HUB_Product"

with DAG(
    dag_id="ssis_skeleton_hub_product",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_product"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_final"):
        # STOCK:SEQUENCE — ref_id: Package\\Final
        op_0 = EmptyOperator(task_id="package_final")

        # ref_id: Package\\Final\\Load HUB_Product
        op_4 = EmptyOperator(task_id="package_final_load_hub_product")

        # ref_id: Package\\Final\\Load SAT_Product
        op_5 = EmptyOperator(task_id="package_final_load_sat_product")

    with TaskGroup(group_id="tg_package_final_2"):
        # STOCK:SEQUENCE — ref_id: Package\\Final 2
        op_1 = EmptyOperator(task_id="package_final_2")

        # ref_id: Package\\Final 2\\Load SAT_CustomerCommisionOverride
        op_2 = EmptyOperator(task_id="package_final_2_load_sat_customercommisionoverride")

        # ref_id: Package\\Final 2\\Load SAT_STK_RFProduct
        op_3 = EmptyOperator(task_id="package_final_2_load_sat_stk_rfproduct")

    with TaskGroup(group_id="tg_package_staging"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging
        op_6 = EmptyOperator(task_id="package_staging")

        # ref_id: Package\\Staging\\Load Product_Stg
        op_13 = EmptyOperator(task_id="package_staging_load_product_stg")

        # ref_id: Package\\Staging\\Truncate Prroduct_Stg
        op_14 = EmptyOperator(task_id="package_staging_truncate_prroduct_stg")

    with TaskGroup(group_id="tg_package_staging_2"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging 2
        op_7 = EmptyOperator(task_id="package_staging_2")

        # ref_id: Package\\Staging 2\\Load STK_RFPrroduct_Stg
        op_8 = EmptyOperator(task_id="package_staging_2_load_stk_rfprroduct_stg")

        # ref_id: Package\\Staging 2\\Truncate STK_RFPrroduct_Stg
        op_9 = EmptyOperator(task_id="package_staging_2_truncate_stk_rfprroduct_stg")

    with TaskGroup(group_id="tg_package_staging_3"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging 3
        op_10 = EmptyOperator(task_id="package_staging_3")

        # ref_id: Package\\Staging 3\\Load FMS_CustomerCommisionOverride
        op_11 = EmptyOperator(task_id="package_staging_3_load_fms_customercommisionoverride")

        # ref_id: Package\\Staging 3\\Truncate FMS_CustomerCommisionOverride
        op_12 = EmptyOperator(task_id="package_staging_3_truncate_fms_customercommisionoverride")

    # --- precedence (upstream >> downstream) ---
    op_6 >> op_0
    op_7 >> op_1
    op_10 >> op_1
    op_14 >> op_13
    op_9 >> op_8
    op_12 >> op_11
