"""
Skeleton DAG for SSIS package: LoadControl
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "LoadControl"

with DAG(
    dag_id="ssis_skeleton_loadcontrol",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "loadcontrol"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_database_maintenance"):
        # STOCK:SEQUENCE — ref_id: Package\\Database Maintenance
        op_0 = EmptyOperator(task_id="package_database_maintenance")

        # ref_id: Package\\Database Maintenance\\DB Maintenance
        op_1 = EmptyOperator(task_id="package_database_maintenance_db_maintenance")

    # ref_id: Package\\Get Misceallaneous data
    op_2 = EmptyOperator(task_id="package_get_misceallaneous_data")

    # ref_id: Package\\Get Next ProcessID
    op_3 = EmptyOperator(task_id="package_get_next_processid")

    with TaskGroup(group_id="tg_package_load_dim_tables"):
        # STOCK:SEQUENCE — ref_id: Package\\Load Dim tables
        op_4 = EmptyOperator(task_id="package_load_dim_tables")

        # ref_id: Package\\Load Dim tables\\Fact_KPI
        op_5 = EmptyOperator(task_id="package_load_dim_tables_fact_kpi")

        # ref_id: Package\\Load Dim tables\\Load Dim_Label
        op_6 = EmptyOperator(task_id="package_load_dim_tables_load_dim_label")

    with TaskGroup(group_id="tg_package_load_hub_tables"):
        # STOCK:SEQUENCE — ref_id: Package\\Load HUB tables
        op_7 = EmptyOperator(task_id="package_load_hub_tables")

        with TaskGroup(group_id="tg_package_load_hub_tables_full_reload"):
            # STOCK:SEQUENCE — ref_id: Package\\Load HUB tables\\Full Reload
            op_8 = EmptyOperator(task_id="package_load_hub_tables_full_reload")

            # ref_id: Package\\Load HUB tables\\Full Reload\\HUB_CF
            op_9 = EmptyOperator(task_id="package_load_hub_tables_full_reload_hub_cf")

            # ref_id: Package\\Load HUB tables\\Full Reload\\HUB_Customer
            op_10 = EmptyOperator(task_id="package_load_hub_tables_full_reload_hub_customer")

            # ref_id: Package\\Load HUB tables\\Full Reload\\HUB_Product
            op_11 = EmptyOperator(task_id="package_load_hub_tables_full_reload_hub_product")

            # ref_id: Package\\Load HUB tables\\Full Reload\\HUB_RF
            op_12 = EmptyOperator(task_id="package_load_hub_tables_full_reload_hub_rf")

            # ref_id: Package\\Load HUB tables\\Full Reload\\HUB_ScanStatus
            op_13 = EmptyOperator(task_id="package_load_hub_tables_full_reload_hub_scanstatus")

            # ref_id: Package\\Load HUB tables\\Full Reload\\HUB_ServiceItem
            op_14 = EmptyOperator(task_id="package_load_hub_tables_full_reload_hub_serviceitem")

        # ref_id: Package\\Load HUB tables\\HUB_Invoice
        op_15 = EmptyOperator(task_id="package_load_hub_tables_hub_invoice")

        # ref_id: Package\\Load HUB tables\\HUB_Label
        op_16 = EmptyOperator(task_id="package_load_hub_tables_hub_label")

        # ref_id: Package\\Load HUB tables\\HUB_ServiceCon
        op_17 = EmptyOperator(task_id="package_load_hub_tables_hub_servicecon")

    # ref_id: Package\\Reserve ProcessID
    op_18 = EmptyOperator(task_id="package_reserve_processid")

    with TaskGroup(group_id="tg_package_send_notification_email"):
        # STOCK:SEQUENCE — ref_id: Package\\Send Notification Email
        op_19 = EmptyOperator(task_id="package_send_notification_email")

        # ref_id: Package\\Send Notification Email\\Get Summary Data
        op_20 = EmptyOperator(task_id="package_send_notification_email_get_summary_data")

        # ref_id: Package\\Send Notification Email\\Send Email
        op_21 = EmptyOperator(task_id="package_send_notification_email_send_email")

    # --- precedence (upstream >> downstream) ---
    op_4 >> op_0
    op_3 >> op_2
    op_7 >> op_4
    op_18 >> op_7
    op_8 >> op_15
    op_8 >> op_16
    op_8 >> op_17
    op_3 >> op_18
    op_0 >> op_19
    op_20 >> op_21
