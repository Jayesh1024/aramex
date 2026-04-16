"""
Skeleton DAG for SSIS package: HUB_Label_2
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "HUB_Label_2"

with DAG(
    dag_id="ssis_skeleton_hub_label_2",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_label_2"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_final"):
        # STOCK:SEQUENCE — ref_id: Package\\Final
        op_0 = EmptyOperator(task_id="package_final")

        # ref_id: Package\\Final\\Load LNK_Label_InterBranch
        op_1 = EmptyOperator(task_id="package_final_load_lnk_label_interbranch")

        # ref_id: Package\\Final\\Load LSAT_Label_InterBranch
        op_2 = EmptyOperator(task_id="package_final_load_lsat_label_interbranch")

    with TaskGroup(group_id="tg_package_monthly_miscellaneous"):
        # STOCK:SEQUENCE — ref_id: Package\\Monthly Miscellaneous
        op_3 = EmptyOperator(task_id="package_monthly_miscellaneous")

        # ref_id: Package\\Monthly Miscellaneous\\Maintain DLBS RFBatching
        op_4 = EmptyOperator(task_id="package_monthly_miscellaneous_maintain_dlbs_rfbatching")

        # ref_id: Package\\Monthly Miscellaneous\\Truncate DLBS RF Batching
        op_5 = EmptyOperator(task_id="package_monthly_miscellaneous_truncate_dlbs_rf_batching")

    with TaskGroup(group_id="tg_package_staging_2"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging 2
        op_6 = EmptyOperator(task_id="package_staging_2")

        # ref_id: Package\\Staging 2\\Get LastId (InterBranch)
        op_7 = EmptyOperator(task_id="package_staging_2_get_lastid_interbranch")

        # ref_id: Package\\Staging 2\\Load Label_Interbranch_Stg
        op_8 = EmptyOperator(task_id="package_staging_2_load_label_interbranch_stg")

        # ref_id: Package\\Staging 2\\Set LastValue (InterBranch)
        op_9 = EmptyOperator(task_id="package_staging_2_set_lastvalue_interbranch")

        # ref_id: Package\\Staging 2\\Truncate Label_Interbranch_Stg
        op_10 = EmptyOperator(task_id="package_staging_2_truncate_label_interbranch_stg")

    # --- precedence (upstream >> downstream) ---
    op_6 >> op_0
    op_1 >> op_2
    op_5 >> op_4
    op_10 >> op_7
    op_7 >> op_8
    op_8 >> op_9
