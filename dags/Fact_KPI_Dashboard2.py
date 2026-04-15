"""
Skeleton DAG for SSIS package: Fact_KPI_Dashboard2
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "Fact_KPI_Dashboard2"

with DAG(
    dag_id="ssis_skeleton_fact_kpi_dashboard2",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "fact_kpi_dashboard2"],
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

        # ref_id: Package\\Staging\\Get Next ProcessID
        op_5 = EmptyOperator(task_id="package_staging_get_next_processid")

        with TaskGroup(group_id="tg_package_staging_staging_1"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Staging 1
            op_6 = EmptyOperator(task_id="package_staging_staging_1")

            # ref_id: Package\\Staging\\Staging 1\\Get LastDate (MyFastway)
            op_7 = EmptyOperator(task_id="package_staging_staging_1_get_lastdate_myfastway")

            # ref_id: Package\\Staging\\Staging 1\\Load fl_MF_Interim_Stg
            op_8 = EmptyOperator(task_id="package_staging_staging_1_load_fl_mf_interim_stg")

            # ref_id: Package\\Staging\\Staging 1\\Truncate fl_MF_Interim_Stg
            op_9 = EmptyOperator(task_id="package_staging_staging_1_truncate_fl_mf_interim_stg")

        with TaskGroup(group_id="tg_package_staging_staging_2"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Staging 2
            op_10 = EmptyOperator(task_id="package_staging_staging_2")

            # ref_id: Package\\Staging\\Staging 2\\Defrag TrackAndTrace_stg Indexes
            op_11 = EmptyOperator(task_id="package_staging_staging_2_defrag_trackandtrace_stg_indexes")

            # ref_id: Package\\Staging\\Staging 2\\Get LastScanDate (TrackAndTrace)
            op_12 = EmptyOperator(task_id="package_staging_staging_2_get_lastscandate_trackandtrace")

            # ref_id: Package\\Staging\\Staging 2\\Load TrackAndTrace_Stg
            op_13 = EmptyOperator(task_id="package_staging_staging_2_load_trackandtrace_stg")

            # ref_id: Package\\Staging\\Staging 2\\Truncate Staging tables
            op_14 = EmptyOperator(task_id="package_staging_staging_2_truncate_staging_tables")

        with TaskGroup(group_id="tg_package_staging_staging_3"):
            # STOCK:SEQUENCE — ref_id: Package\\Staging\\Staging 3
            op_15 = EmptyOperator(task_id="package_staging_staging_3")

            # ref_id: Package\\Staging\\Staging 3\\Get Start Date
            op_16 = EmptyOperator(task_id="package_staging_staging_3_get_start_date")

            # ref_id: Package\\Staging\\Staging 3\\Load fl_ConItemSrv_Stg
            op_18 = EmptyOperator(task_id="package_staging_staging_3_load_fl_conitemsrv_stg")

            # ref_id: Package\\Staging\\Staging 3\\Load Product ServiceItem_Stg
            op_17 = EmptyOperator(task_id="package_staging_staging_3_load_product_serviceitem_stg")

            # ref_id: Package\\Staging\\Staging 3\\Truncate fl_conitmsrv_stg
            op_19 = EmptyOperator(task_id="package_staging_staging_3_truncate_fl_conitmsrv_stg")

    # --- precedence (upstream >> downstream) ---
    op_4 >> op_0
    op_3 >> op_1
    op_1 >> op_2
    op_5 >> op_6
    op_9 >> op_7
    op_7 >> op_8
    op_5 >> op_10
    op_13 >> op_11
    op_14 >> op_12
    op_12 >> op_13
    op_5 >> op_15
    op_19 >> op_16
    op_16 >> op_18
    op_18 >> op_17
