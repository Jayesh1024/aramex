"""
Skeleton DAG for SSIS package: Fact_KPI_Dashboard
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "Fact_KPI_Dashboard"

with DAG(
    dag_id="ssis_skeleton_fact_kpi_dashboard",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "fact_kpi_dashboard"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_load_interim_labels"):
        # STOCK:SEQUENCE — ref_id: Package\\Load Interim Labels
        op_0 = EmptyOperator(task_id="package_load_interim_labels")

        # ref_id: Package\\Load Interim Labels\\Load Fact_KPI_Daily_Stg
        op_1 = EmptyOperator(task_id="package_load_interim_labels_load_fact_kpi_daily_stg")

        # ref_id: Package\\Load Interim Labels\\Load Fact_KPI_Interim
        op_2 = EmptyOperator(task_id="package_load_interim_labels_load_fact_kpi_interim")

        # ref_id: Package\\Load Interim Labels\\Load Interim_KPI_Labels_Src_Stg
        op_3 = EmptyOperator(task_id="package_load_interim_labels_load_interim_kpi_labels_src_stg")

    with TaskGroup(group_id="tg_package_staging"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging
        op_4 = EmptyOperator(task_id="package_staging")

        with TaskGroup(group_id="tg_package_staging_initial"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Initial
            op_10 = EmptyOperator(task_id="package_staging_initial")

            # ref_id: Package\\Staging\\Initial\\Get Next ProcessID
            op_11 = EmptyOperator(task_id="package_staging_initial_get_next_processid")

        with TaskGroup(group_id="tg_package_staging_staging_1"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Staging 1
            op_12 = EmptyOperator(task_id="package_staging_staging_1")

            # ref_id: Package\\Staging\\Staging 1\\Data Flow Task
            op_13 = EmptyOperator(task_id="package_staging_staging_1_data_flow_task")

            # ref_id: Package\\Staging\\Staging 1\\Get LastDate (MyFastway)
            op_14 = EmptyOperator(task_id="package_staging_staging_1_get_lastdate_myfastway")

            # ref_id: Package\\Staging\\Staging 1\\Load fl_MF_Interim_Stg
            op_15 = EmptyOperator(task_id="package_staging_staging_1_load_fl_mf_interim_stg")

            # ref_id: Package\\Staging\\Staging 1\\Truncate fl_MF_Interim_Stg
            op_16 = EmptyOperator(task_id="package_staging_staging_1_truncate_fl_mf_interim_stg")

        with TaskGroup(group_id="tg_package_staging_staging_2"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Staging 2
            op_17 = EmptyOperator(task_id="package_staging_staging_2")

            # ref_id: Package\\Staging\\Staging 2\\Defrag TrackAndTrace_stg Indexes
            op_18 = EmptyOperator(task_id="package_staging_staging_2_defrag_trackandtrace_stg_indexes")

            # ref_id: Package\\Staging\\Staging 2\\Get LastScanID (TrackAndTrace)
            op_19 = EmptyOperator(task_id="package_staging_staging_2_get_lastscanid_trackandtrace")

            # ref_id: Package\\Staging\\Staging 2\\Load TrackAndTrace_Stg
            op_20 = EmptyOperator(task_id="package_staging_staging_2_load_trackandtrace_stg")

            # ref_id: Package\\Staging\\Staging 2\\Truncate Staging tables
            op_21 = EmptyOperator(task_id="package_staging_staging_2_truncate_staging_tables")

    with TaskGroup(group_id="tg_package_staging_3"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging 3
        op_5 = EmptyOperator(task_id="package_staging_3")

        # ref_id: Package\\Staging 3\\Get Start Date
        op_6 = EmptyOperator(task_id="package_staging_3_get_start_date")

        # ref_id: Package\\Staging 3\\Load fl_ConItemSrv_Stg
        op_8 = EmptyOperator(task_id="package_staging_3_load_fl_conitemsrv_stg")

        # ref_id: Package\\Staging 3\\Load Product ServiceItem_Stg
        op_7 = EmptyOperator(task_id="package_staging_3_load_product_serviceitem_stg")

        # ref_id: Package\\Staging 3\\Truncate fl_conitmsrv_stg
        op_9 = EmptyOperator(task_id="package_staging_3_truncate_fl_conitmsrv_stg")

    # --- precedence (upstream >> downstream) ---
    op_5 >> op_0
    op_3 >> op_1
    op_1 >> op_2
    op_10 >> op_12
    op_16 >> op_14
    op_14 >> op_15
    op_10 >> op_17
    op_20 >> op_18
    op_21 >> op_19
    op_19 >> op_20
    op_4 >> op_5
    op_9 >> op_6
    op_6 >> op_8
    op_8 >> op_7
