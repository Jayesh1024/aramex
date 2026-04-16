"""
Skeleton DAG for SSIS package: LNK_Label_Product_ServiceItem
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "LNK_Label_Product_ServiceItem"

with DAG(
    dag_id="ssis_skeleton_lnk_label_product_serviceitem",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "lnk_label_product_serviceitem"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_final"):
        # STOCK:SEQUENCE — ref_id: Package\\Final
        op_0 = EmptyOperator(task_id="package_final")

        # ref_id: Package\\Final\\Load LNK_Label_Product_ServiceItem
        op_1 = EmptyOperator(task_id="package_final_load_lnk_label_product_serviceitem")

        # ref_id: Package\\Final\\Load LSAT_Label_Product_ServiceItem
        op_2 = EmptyOperator(task_id="package_final_load_lsat_label_product_serviceitem")

    with TaskGroup(group_id="tg_package_staging"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging
        op_3 = EmptyOperator(task_id="package_staging")

        # ref_id: Package\\Staging\\Load Label_Product_ServiceItem_Stg
        op_4 = EmptyOperator(task_id="package_staging_load_label_product_serviceitem_stg")

        # ref_id: Package\\Staging\\Truncate Label_Product_ServiceItem_Stg
        op_5 = EmptyOperator(task_id="package_staging_truncate_label_product_serviceitem_stg")

    # --- precedence (upstream >> downstream) ---
    op_3 >> op_0
    op_1 >> op_2
    op_5 >> op_4
