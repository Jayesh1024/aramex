"""
Skeleton DAG for SSIS package: Interim_LNK_Scan
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "Interim_LNK_Scan"

with DAG(
    dag_id="ssis_skeleton_interim_lnk_scan",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "interim_lnk_scan"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_final"):
        # STOCK:SEQUENCE — ref_id: Package\\Final
        op_0 = EmptyOperator(task_id="package_final")

        # ref_id: Package\\Final\\Defrag HUB_Location Indexes
        op_1 = EmptyOperator(task_id="package_final_defrag_hub_location_indexes")

        # ref_id: Package\\Final\\Load HUB_Location
        op_2 = EmptyOperator(task_id="package_final_load_hub_location")

        with TaskGroup(group_id="tg_package_final_load_lnk"):
            # STOCK:SEQUENCE — ref_id: Package\\Final\\Load LNK
            op_3 = EmptyOperator(task_id="package_final_load_lnk")

            # ref_id: Package\\Final\\Load LNK\\Defrag LNK_Scan Indexes
            op_4 = EmptyOperator(task_id="package_final_load_lnk_defrag_lnk_scan_indexes")

            # ref_id: Package\\Final\\Load LNK\\Interim Load_Scans_Stg
            op_5 = EmptyOperator(task_id="package_final_load_lnk_interim_load_scans_stg")

            # ref_id: Package\\Final\\Load LNK\\Load LNK_Scan
            op_6 = EmptyOperator(task_id="package_final_load_lnk_load_lnk_scan")

            # ref_id: Package\\Final\\Load LNK\\Load LNK_Scan_Signatures
            op_7 = EmptyOperator(task_id="package_final_load_lnk_load_lnk_scan_signatures")

            # ref_id: Package\\Final\\Load LNK\\Load LNK_Scan_Stg
            op_8 = EmptyOperator(task_id="package_final_load_lnk_load_lnk_scan_stg")

            # ref_id: Package\\Final\\Load LNK\\Set Last ID (TrackAndTraceID) Now in Interim_Fact_Scan_KPI
            op_9 = EmptyOperator(task_id="package_final_load_lnk_set_last_id_trackandtraceid_now_in_interim_fact_scan_kpi")

            # ref_id: Package\\Final\\Load LNK\\Truncate Staging Tables
            op_10 = EmptyOperator(task_id="package_final_load_lnk_truncate_staging_tables")

        with TaskGroup(group_id="tg_package_final_load_signatureai"):
            # STOCK:SEQUENCE — ref_id: Package\\Final\\Load SignatureAI
            op_11 = EmptyOperator(task_id="package_final_load_signatureai")

            # ref_id: Package\\Final\\Load SignatureAI\\Load LNK_SignatureAI
            op_12 = EmptyOperator(task_id="package_final_load_signatureai_load_lnk_signatureai")

            # ref_id: Package\\Final\\Load SignatureAI\\Set Last ID (SignatureAI)
            op_13 = EmptyOperator(task_id="package_final_load_signatureai_set_last_id_signatureai")

    with TaskGroup(group_id="tg_package_staging"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging
        op_14 = EmptyOperator(task_id="package_staging")

        # ref_id: Package\\Staging\\Defrag TrackAndTrace_stg Indexes
        op_15 = EmptyOperator(task_id="package_staging_defrag_trackandtrace_stg_indexes")

        # ref_id: Package\\Staging\\Get Last Date (SignatureAI)
        op_16 = EmptyOperator(task_id="package_staging_get_last_date_signatureai")

        # ref_id: Package\\Staging\\Get Last ID (TrackAndTraceID)
        op_17 = EmptyOperator(task_id="package_staging_get_last_id_trackandtraceid")

        # ref_id: Package\\Staging\\Get ProcessID
        op_18 = EmptyOperator(task_id="package_staging_get_processid")

        # ref_id: Package\\Staging\\Load TrackAndTrace SignatureAI
        op_19 = EmptyOperator(task_id="package_staging_load_trackandtrace_signatureai")

        # ref_id: Package\\Staging\\Load TrackAndTrace_Stg
        op_20 = EmptyOperator(task_id="package_staging_load_trackandtrace_stg")

        # ref_id: Package\\Staging\\Truncate Staging tables
        op_21 = EmptyOperator(task_id="package_staging_truncate_staging_tables")

    # --- precedence (upstream >> downstream) ---
    op_14 >> op_0
    op_2 >> op_1
    op_1 >> op_3
    op_6 >> op_4
    op_10 >> op_5
    op_8 >> op_6
    op_6 >> op_7
    op_5 >> op_8
    op_7 >> op_9
    op_3 >> op_11
    op_12 >> op_13
    op_20 >> op_15
    op_21 >> op_16
    op_21 >> op_17
    op_16 >> op_19
    op_17 >> op_20
    op_18 >> op_21
