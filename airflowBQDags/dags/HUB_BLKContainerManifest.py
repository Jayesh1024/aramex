"""
Completed DAG for SSIS package: HUB_BLKContainerManifest
Migration: SSIS -> BigQuery
Formatting: Jinja2 Templating + XCom for runtime values

Notes on the non-standard pieces of this package:
  * `Package\Get ProcessID` is NOT the usual LoadControl `Get Next ProcessID`
    logic. SSIS runs:
        SELECT MIN(ProcessID) - 1 FROM Staging.LoadLog WHERE ProcessID < -99999
    to allocate a *negative* sentinel ProcessId exclusive to this package.
    Implemented here as a PythonOperator that mirrors that query verbatim and
    pushes the result through XCom (downstream tasks read via
    `ti.xcom_pull`). If `params.ProcessId` is non-null on a manual trigger
    it wins; otherwise the task computes one.
  * `Package\Staging\Get Last ContainerContents LastScanDate` calls the
    shared Staging_Get_LastValue SP (mirroring HUB_Invoice) and feeds the
    result into the ContainerContents staging pipeline.
  * `Update LoadControl LastScanDate (BLK_ManifestID)` is an SSIS ExecuteSQL
    task that recomputes MAX(ScanDate) on the staging table and writes it
    back into Staging.LoadControl. Translated directly to a BQ UPDATE
    statement with a correlated subquery.
  * The two staging pipelines (`Load ContainerContents`, `Load ContainerManifest`)
    are wrapped as BQ SPs following the HUB_CF convention; the
    ContainerContents pipeline takes a LastScanDate argument because the
    SSIS OLEDBSource does.
"""
from __future__ import annotations

from datetime import datetime
import os

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup
from utils.getValue import allocate_negative_sentinel_processid, get_last_value

PROJECT_ID = os.getenv("PROJECT_ID")
SP_DATASET_ID = os.getenv("SP_DATASET_ID")
TARGET_DATASET_ID = os.getenv("TARGET_DATASET_ID")
_TASK_ID_GET_PROCESS_ID = "package_get_processid"
_TASK_ID_GET_LAST_SCAN = "tg_package_staging.package_staging_get_last_containercontents_lastscandate"


with DAG(
    dag_id="ssis_skeleton_hub_blkcontainermanifest",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_blkcontainermanifest"],
    params={
        "DisableFinal": 0,
        "DisableStage": 0,
        "ManifestContentsBatchSize": 200000,
        "Minimum_ManifestId": 65000,
        "RecordSource1": 'BLK_ContainerManifest',
        "RecordSource2": 'BLK_ManifestContents',
        "RecordSource3": 'BLK_Container',
        "RecordSource4": 'BLK_TransitManifest',
        "RecordSource5": 'BLK_TransitContents',
    },
) as dag:

    # ref_id: Package\Get ProcessID — negative sentinel scheme (min - 1 over < -99999).
    op_5 = PythonOperator(
        task_id=_TASK_ID_GET_PROCESS_ID,
        python_callable=allocate_negative_sentinel_processid,
        op_kwargs={
            "project_id": PROJECT_ID,
            "dataset_id": TARGET_DATASET_ID,
        },
    )

    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE — ref_id: Package\Staging

        # ref_id: Package\Staging\Truncate BLK_Manifest_Stg
        # SSIS truncates both staging tables in one task.
        op_10 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_blk_manifest_stg",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_BLK_ContainerManifest_Stg`;\n"
                        f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_BLK_ContainerManifestContents_Stg`;"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging\Load ContainerManifest (Pipeline -> SP, no params)
        op_9 = BigQueryInsertJobOperator(
            task_id="package_staging_load_containermanifest",
            configuration={
                "query": {
                    "query": f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.sp_load_Staging_BLK_ContainerManifest_Stg`();",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging\Get Last ContainerContents LastScanDate
        # SSIS: Exec [Staging].[Get_LastValue] RecordSource -> scalar LastScanDate.
        op_7 = PythonOperator(
            task_id="package_staging_get_last_containercontents_lastscandate",
            python_callable=get_last_value,
            op_kwargs={
                "project_id": PROJECT_ID,
                "dataset_id": SP_DATASET_ID,
                "record_source": "{{ params.RecordSource1 }}",
            },
        )

        # ref_id: Package\Staging\Load ContainerContents (Pipeline -> SP, takes LastScanDate)
        op_8 = BigQueryInsertJobOperator(
            task_id="package_staging_load_containercontents",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.sp_load_Staging_BLK_ContainerManifestContents_Stg`("
                        f"SAFE_CAST('{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_LAST_SCAN}') }}}}' AS DATETIME));"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        op_10 >> op_9 >> op_7 >> op_8

    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\Final

        _xcom_processid = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_PROCESS_ID}') }}}}"

        # ref_id: Package\Final\Load HUB_BLKContainerManifestLabel
        # SSIS: EXEC [dv].[Load_HUB_BLKContainerManifestContents] ProcessId, RecordSource
        op_1 = BigQueryInsertJobOperator(
            task_id="package_final_load_hub_blkcontainermanifestlabel",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_HUB_BLKContainerManifestContents`("
                        f"{_xcom_processid}, '{{{{ params.RecordSource1 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final\Load SAT_BLKContainerManifest — EXEC [dv].[Load_SAT_BLKContainerManifest] ?,?
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_load_sat_blkcontainermanifest",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_SAT_BLKContainerManifest`("
                        f"{_xcom_processid}, '{{{{ params.RecordSource1 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final\Load SAT_BLKContainerManifestContent — EXEC [dv].[Load_SAT_BLKContainerManifestContents] ?,?
        op_3 = BigQueryInsertJobOperator(
            task_id="package_final_load_sat_blkcontainermanifestcontent",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_SAT_BLKContainerManifestContents`("
                        f"{_xcom_processid}, '{{{{ params.RecordSource1 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final\Update LoadControl LastScanDate (BLK_ManifestID)
        # SSIS: correlated UPDATE of Staging.LoadControl.LastValue with
        #        MAX(ScanDate) from Staging.BLK_ContainerManifestContents_Stg.
        op_4 = BigQueryInsertJobOperator(
            task_id="package_final_update_loadcontrol_lastscandate_blk_manifestid",
            configuration={
                "query": {
                    "query": (
                        f"UPDATE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_LoadControl` lc "
                        "SET lc.LastValue = CAST(("
                        "SELECT CAST(MAX(ScanDate) AS STRING) "
                        f"FROM `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_BLK_ContainerManifestContents_Stg`"
                        ") AS STRING) "
                        "WHERE lc.RecordSource = '{{ params.RecordSource1 }}';"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        op_2 >> op_3
        [op_1, op_3] >> op_4

    op_5 >> tg_staging >> tg_final
