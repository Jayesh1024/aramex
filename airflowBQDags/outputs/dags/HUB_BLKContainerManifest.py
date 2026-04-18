"""
Skeleton DAG for SSIS package: HUB_BLKContainerManifest
Generated from executable_dependencies.json — EmptyOperator only, no business logic.
Sequence containers (STOCK:SEQUENCE) are wrapped in TaskGroup.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.utils.task_group import TaskGroup

PACKAGE_NAME = "HUB_BLKContainerManifest"

with DAG(
    dag_id="ssis_skeleton_hub_blkcontainermanifest",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_blkcontainermanifest"],
) as dag:

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_final"):
        # STOCK:SEQUENCE — ref_id: Package\\Final
        op_0 = EmptyOperator(task_id="package_final")

        # ref_id: Package\\Final\\Load HUB_BLKContainerManifestLabel
        op_1 = EmptyOperator(task_id="package_final_load_hub_blkcontainermanifestlabel")

        # ref_id: Package\\Final\\Load SAT_BLKContainerManifest
        op_2 = EmptyOperator(task_id="package_final_load_sat_blkcontainermanifest")

        # ref_id: Package\\Final\\Load SAT_BLKContainerManifestContent
        op_3 = EmptyOperator(task_id="package_final_load_sat_blkcontainermanifestcontent")

        # ref_id: Package\\Final\\Update LoadControl LastScanDate (BLK_ManifestID)
        op_4 = EmptyOperator(task_id="package_final_update_loadcontrol_lastscandate_blk_manifestid")

    # ref_id: Package\\Get ProcessID
    op_5 = EmptyOperator(task_id="package_get_processid")

    with TaskGroup(group_id="tg_package_staging"):
        # STOCK:SEQUENCE — ref_id: Package\\Staging
        op_6 = EmptyOperator(task_id="package_staging")

        # ref_id: Package\\Staging\\Get Last ContainerContents LastScanDate
        op_7 = EmptyOperator(task_id="package_staging_get_last_containercontents_lastscandate")

        # ref_id: Package\\Staging\\Load ContainerContents
        op_8 = EmptyOperator(task_id="package_staging_load_containercontents")

        # ref_id: Package\\Staging\\Load ContainerManifest
        op_9 = EmptyOperator(task_id="package_staging_load_containermanifest")

        # ref_id: Package\\Staging\\Truncate BLK_Manifest_Stg
        op_10 = EmptyOperator(task_id="package_staging_truncate_blk_manifest_stg")

    # --- precedence (upstream >> downstream) ---
    op_6 >> op_0
    op_2 >> op_3
    op_1 >> op_4
    op_3 >> op_4
    op_5 >> op_6
    op_9 >> op_7
    op_7 >> op_8
    op_10 >> op_9
