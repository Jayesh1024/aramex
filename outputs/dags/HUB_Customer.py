"""
Skeleton DAG for SSIS package: HUB_Customer
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "HUB_Customer"

with DAG(
    dag_id="ssis_skeleton_hub_customer",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_customer"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_final"):
        # STOCK:SEQUENCE — ref_id: Package\\Final
        op_0 = EmptyOperator(task_id="package_final")

        # ref_id: Package\\Final\\Load HUB_Customer
        op_1 = EmptyOperator(task_id="package_final_load_hub_customer")

        # ref_id: Package\\Final\\Load SAL_Customer
        op_2 = EmptyOperator(task_id="package_final_load_sal_customer")

        # ref_id: Package\\Final\\Load SAT_Customer
        op_3 = EmptyOperator(task_id="package_final_load_sat_customer")

        # ref_id: Package\\Final\\Load SAT_Customer_OES
        op_4 = EmptyOperator(task_id="package_final_load_sat_customer_oes")

    with TaskGroup(group_id="tg_package_staging"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging
        op_5 = EmptyOperator(task_id="package_staging")

        # ref_id: Package\\Staging\\Load CustomerLinks_Stg
        op_6 = EmptyOperator(task_id="package_staging_load_customerlinks_stg")

        # ref_id: Package\\Staging\\Load FMS_Customer_Stg
        op_7 = EmptyOperator(task_id="package_staging_load_fms_customer_stg")

        # ref_id: Package\\Staging\\Load IFSCustomers_Stg
        op_8 = EmptyOperator(task_id="package_staging_load_ifscustomers_stg")

        # ref_id: Package\\Staging\\Load tblCustomer_Stg
        op_9 = EmptyOperator(task_id="package_staging_load_tblcustomer_stg")

        # ref_id: Package\\Staging\\Truncate CustomerLinks_Stg
        op_10 = EmptyOperator(task_id="package_staging_truncate_customerlinks_stg")

        # ref_id: Package\\Staging\\Truncate FMS_Customer_Stg
        op_11 = EmptyOperator(task_id="package_staging_truncate_fms_customer_stg")

        # ref_id: Package\\Staging\\Truncate IFSCustomers_Stg
        op_12 = EmptyOperator(task_id="package_staging_truncate_ifscustomers_stg")

        # ref_id: Package\\Staging\\Truncate tblCustomer_Stg
        op_13 = EmptyOperator(task_id="package_staging_truncate_tblcustomer_stg")

    # --- precedence (upstream >> downstream) ---
    op_5 >> op_0
    op_1 >> op_3
    op_2 >> op_4
    op_10 >> op_6
    op_11 >> op_7
    op_12 >> op_8
    op_13 >> op_9
