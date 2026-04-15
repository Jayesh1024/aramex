"""
Skeleton DAG for SSIS package: DLS_Manual_Pricing
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "DLS_Manual_Pricing"

with DAG(
    dag_id="ssis_skeleton_dls_manual_pricing",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "dls_manual_pricing"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_source2_dynamiclabel_dl"):
        # STOCK:SEQUENCE — ref_id: Package\\Source2 (DynamicLabel) _DL
        op_0 = EmptyOperator(task_id="package_source2_dynamiclabel_dl")

        # ref_id: Package\\Source2 (DynamicLabel) _DL\\Get LastId (DynamicLabel)
        op_1 = EmptyOperator(task_id="package_source2_dynamiclabel_dl_get_lastid_dynamiclabel")

        # ref_id: Package\\Source2 (DynamicLabel) _DL\\Get Next ProcessID
        op_2 = EmptyOperator(task_id="package_source2_dynamiclabel_dl_get_next_processid")

        # ref_id: Package\\Source2 (DynamicLabel) _DL\\Insert Into API_RF_AdHocLabel_AllocationHistory_Stg
        op_3 = EmptyOperator(task_id="package_source2_dynamiclabel_dl_insert_into_api_rf_adhoclabel_allocationhistory_stg")

        # ref_id: Package\\Source2 (DynamicLabel) _DL\\Load API_RF_AdHocLabel_AllocationHistory_Stg_Weekly
        op_4 = EmptyOperator(task_id="package_source2_dynamiclabel_dl_load_api_rf_adhoclabel_allocationhistory_stg_weekly")

        # ref_id: Package\\Source2 (DynamicLabel) _DL\\Load Lastest Priced Invoices
        op_5 = EmptyOperator(task_id="package_source2_dynamiclabel_dl_load_lastest_priced_invoices")

        # ref_id: Package\\Source2 (DynamicLabel) _DL\\Truncate API_RF_AdHocLabel_AllocationHistory_Stg_Weekly
        op_6 = EmptyOperator(task_id="package_source2_dynamiclabel_dl_truncate_api_rf_adhoclabel_allocationhistory_stg_weekly")

        # ref_id: Package\\Source2 (DynamicLabel) _DL\\Update Dim_Label
        op_7 = EmptyOperator(task_id="package_source2_dynamiclabel_dl_update_dim_label")

    # --- precedence (upstream >> downstream) ---
    op_6 >> op_1
    op_3 >> op_2
    op_4 >> op_3
    op_1 >> op_4
    op_2 >> op_5
    op_5 >> op_7
