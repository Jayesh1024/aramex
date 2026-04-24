"""
Completed DAG for SSIS package: HUB_Label_MF_ONLY
Migration: SSIS -> BigQuery

Shape:
  * Package\Source4 (MyFastway) _MF  -> Package\Sequence Container

The Source4 task group loads the `fl_ConItem_Stg` staging table from MyFastway
(pipeline wrapped as `sp_load_Staging_fl_ConItem_Stg`). The main Sequence
Container truncates ten staging tables (preserved as a single multi-statement
TRUNCATE to match SSIS), loads the SAT_Label_Allocation staging row set, runs
the two downstream dv.* loads, and finally calls `Staging_Set_LastValue`
bound to RecordSource4.

`Rebuild Indexes 4` and the inline `DISABLE` tail of `Truncate fl_ConItem_Stg`
both called [dbo].[MaintainIndexes] — dropped entirely, BigQuery has no
indexes.
"""
from __future__ import annotations

from datetime import datetime
import os

from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup
from utils.bq_env import PROJECT_ID, SP_DATASET_ID, TARGET_DATASET_ID

_STAGING_TABLES_TO_TRUNCATE = [
    "Staging_SAT_Label_Allocation_Stg",
    "Staging_LabelMaster_Stg",
    "Staging_API_RF_AdHocLabel_AllocationHistory_Stg",
    "Staging_tblFastLabel_Consignment_Stg",
    "Staging_HDManifests_Stg",
    "Staging_ConsignmentItem_Stg",
    "Staging_tblOnlineEnquiry_RP_Stg",
    "Staging_PickupRequest_Stg",
    "Staging_Ebay_labels_Stg",
    "Staging_fl_ConItemSrv_Stg",
]

with DAG(
    dag_id="ssis_skeleton_hub_label_mf_only",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_label_mf_only"],
    params={
        "BatchDays": -1,
        "DisableFinal": 0,
        "DisableStage": 0,
        "ProcessId": -4,
        "RecordSource4": 'MyFastway',
        "StartDate": '1/1/1900',
    },
) as dag:

    with TaskGroup(group_id="tg_package_source4_myfastway_mf") as tg_source4:
        # STOCK:SEQUENCE — ref_id: Package\Source4 (MyFastway) _MF

        op_9 = BigQueryInsertJobOperator(
            task_id="package_source4_myfastway_mf_truncate_fl_conitem_stg",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_fl_ConItem_Stg`;",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Source4 (MyFastway) _MF\Load fl_ConItem_Stg (Pipeline -> SP)
        op_7 = BigQueryInsertJobOperator(
            task_id="package_source4_myfastway_mf_load_fl_conitem_stg",
            configuration={
                "query": {
                    "query": f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.sp_load_Staging_fl_ConItem_Stg`();",
                    "useLegacySql": False,
                }
            },
        )

        op_9 >> op_7

    with TaskGroup(group_id="tg_package_sequence_container") as tg_sequence:
        # STOCK:SEQUENCE — ref_id: Package\Sequence Container

        op_5 = BigQueryInsertJobOperator(
            task_id="package_sequence_container_truncate_sat_label_allocation_stg",
            configuration={
                "query": {
                    "query": "\n".join(
                        f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.{tbl}`;"
                        for tbl in _STAGING_TABLES_TO_TRUNCATE
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Sequence Container\Load SAT_Label_Allocation_Stg — Exec [Staging].[Load_SAT_Label_Allocation_Stg] ProcessId
        op_3 = BigQueryInsertJobOperator(
            task_id="package_sequence_container_load_sat_label_allocation_stg",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.staging_Load_SAT_Label_Allocation_Stg2`("
                        f"{{{{ params.ProcessId }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Sequence Container\Load SAT_Label_Allocation — Exec [dv].[Load_SAT_Label_Allocation] ProcessId
        op_1 = BigQueryInsertJobOperator(
            task_id="package_sequence_container_load_sat_label_allocation",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_SAT_Label_Allocation`("
                        f"{{{{ params.ProcessId }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Sequence Container\Load SAT_Label_Allocation_MF — Exec [dv].[Load_SAT_Label_Allocation_MF] ProcessId, RecordSource4
        op_2 = BigQueryInsertJobOperator(
            task_id="package_sequence_container_load_sat_label_allocation_mf",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_SAT_Label_Allocation_MF`("
                        f"{{{{ params.ProcessId }}}}, '{{{{ params.RecordSource4 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Sequence Container\Set LastDate (MyFastway) — Staging_Set_LastValue(RecordSource4)
        op_4 = BigQueryInsertJobOperator(
            task_id="package_sequence_container_set_lastdate_myfastway",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_Set_LastValue`("
                        f"'{{{{ params.RecordSource4 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        op_5 >> op_3 >> op_1 >> op_2 >> op_4

    tg_source4 >> tg_sequence
