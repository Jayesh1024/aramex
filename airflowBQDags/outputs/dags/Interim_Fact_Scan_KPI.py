"""
Skeleton DAG for SSIS package: Interim_Fact_Scan_KPI
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "Interim_Fact_Scan_KPI"

with DAG(
    dag_id="ssis_skeleton_interim_fact_scan_kpi",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "interim_fact_scan_kpi"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_final"):
        # STOCK:SEQUENCE — ref_id: Package\\Final
        op_0 = EmptyOperator(task_id="package_final")

        # ref_id: Package\\Final\\Load Fact_Scan_KPI
        op_1 = EmptyOperator(task_id="package_final_load_fact_scan_kpi")

        # ref_id: Package\\Final\\Set Last ID (TrackAndTraceID)
        op_2 = EmptyOperator(task_id="package_final_set_last_id_trackandtraceid")

    with TaskGroup(group_id="tg_package_staging"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging
        op_3 = EmptyOperator(task_id="package_staging")

        # ref_id: Package\\Staging\\Defrag Indexes
        op_4 = EmptyOperator(task_id="package_staging_defrag_indexes")

        # ref_id: Package\\Staging\\Get ProcessID
        op_5 = EmptyOperator(task_id="package_staging_get_processid")

        # ref_id: Package\\Staging\\Load Fact_Scan_KPI_Stg
        op_6 = EmptyOperator(task_id="package_staging_load_fact_scan_kpi_stg")

        # ref_id: Package\\Staging\\Load KPI_Labels_Stg
        op_7 = EmptyOperator(task_id="package_staging_load_kpi_labels_stg")

        # ref_id: Package\\Staging\\Truncate KPI Staging Tables
        op_8 = EmptyOperator(task_id="package_staging_truncate_kpi_staging_tables")

    # --- precedence (upstream >> downstream) ---
    op_3 >> op_0
    op_1 >> op_2
    op_6 >> op_4
    op_7 >> op_6
    op_8 >> op_7
    op_5 >> op_8
