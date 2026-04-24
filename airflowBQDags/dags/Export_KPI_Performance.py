"""
Skeleton DAG for SSIS package: Export_KPI_Performance
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime
import os
from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup


GCP_PROJECT_ID = os.getenv("GCP_PROJECT_ID")

with DAG(
    dag_id="ssis_skeleton_export_kpi_performance",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "export_kpi_performance"],
    params={
        "SendLoadEmailTo": 'barry_woods@bigpond.com',
    },
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_send_notification_email"):
        # STOCK:SEQUENCE — ref_id: Package\\Send Notification Email
        op_0 = EmptyOperator(task_id="package_send_notification_email")

        # ref_id: Package\\Send Notification Email\\Get Summary Data
        op_1 = EmptyOperator(task_id="package_send_notification_email_get_summary_data")

        # ref_id: Package\\Send Notification Email\\Send Email
        op_2 = EmptyOperator(task_id="package_send_notification_email_send_email")

    with TaskGroup(group_id="tg_package_sequence_container"):
        # STOCK:SEQUENCE — ref_id: Package\\Sequence Container
        op_3 = EmptyOperator(task_id="package_sequence_container")

        # ref_id: Package\\Sequence Container\\Export to KRILLIN
        op_4 = EmptyOperator(task_id="package_sequence_container_export_to_krillin")

        # ref_id: Package\\Sequence Container\\Get Next ProcessID
        op_5 = EmptyOperator(task_id="package_sequence_container_get_next_processid")

        # ref_id: Package\\Sequence Container\\Load Staging Export
        op_6 = EmptyOperator(task_id="package_sequence_container_load_staging_export")

        # ref_id: Package\\Sequence Container\\Truncate Staging Tables
        op_7 = EmptyOperator(task_id="package_sequence_container_truncate_staging_tables")

    # --- precedence (upstream >> downstream) ---
    op_3 >> op_0
    op_1 >> op_2
    op_6 >> op_4
    op_7 >> op_6
    op_5 >> op_7
