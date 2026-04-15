"""
Skeleton DAG for SSIS package: Fact_KPI
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "Fact_KPI"

with DAG(
    dag_id="ssis_skeleton_fact_kpi",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "fact_kpi"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_final"):
        # STOCK:SEQUENCE — ref_id: Package\\Final
        op_0 = EmptyOperator(task_id="package_final")

        # ref_id: Package\\Final\\Load Fact KPI Labels
        op_1 = EmptyOperator(task_id="package_final_load_fact_kpi_labels")

        # ref_id: Package\\Final\\Load Fact KPI Performance
        op_2 = EmptyOperator(task_id="package_final_load_fact_kpi_performance")

        # ref_id: Package\\Final\\Load Fact_KPI_Priority
        op_3 = EmptyOperator(task_id="package_final_load_fact_kpi_priority")

    with TaskGroup(group_id="tg_package_staging"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging
        op_4 = EmptyOperator(task_id="package_staging")

        # ref_id: Package\\Staging\\Defrag Indexes
        op_5 = EmptyOperator(task_id="package_staging_defrag_indexes")

        # ref_id: Package\\Staging\\Load Fact_KPI_Daily_Stg
        op_6 = EmptyOperator(task_id="package_staging_load_fact_kpi_daily_stg")

        # ref_id: Package\\Staging\\Load KPI_Labels_Src_Stg
        op_7 = EmptyOperator(task_id="package_staging_load_kpi_labels_src_stg")

        # ref_id: Package\\Staging\\Truncate KPI Staging Tables
        op_8 = EmptyOperator(task_id="package_staging_truncate_kpi_staging_tables")

    # --- precedence (upstream >> downstream) ---
    op_4 >> op_0
    op_3 >> op_2
    op_1 >> op_3
    op_6 >> op_5
    op_7 >> op_6
    op_8 >> op_7
