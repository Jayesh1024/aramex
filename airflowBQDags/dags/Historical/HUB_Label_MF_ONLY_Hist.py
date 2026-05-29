"""
Completed DAG for SSIS package: HUB_Label_MF_ONLY_Hist
Migration: SSIS -> BigQuery

Shape:
  * Package\Source4 (MyFastway) _MF  -> Package\Sequence Container

The Source4 task group loads the `fl_ConItem_Stg` staging table from MyFastway
(pipeline wrapped as `sp_load_Staging_fl_ConItem_Stg_Hist`). The main Sequence
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

from airflow import DAG
from airflow.models import Variable
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup

GCP_PROJECT_ID = Variable.get("PROJECT_ID")
SP_DATASET_ID = Variable.get("SP_DATASET_ID")
TARGET_DATASET_ID = Variable.get("TARGET_DATASET_ID")


_STAGING_TABLES_TO_TRUNCATE = [
    "Staging_SAT_Label_Allocation_Stg",
    "Staging_LabelMaster_Stg",
    "Staging_API_RF_AdHocLabel_AllocationHistory_Stg",
    "Staging_tblFastLabel_Consignment_Stg",
    "Staging_HDManifests_Stg",
    "Staging_ConsignmentItem_Stg",
    "Staging_tblOnlineEnquiry_RP_Stg",
    "Staging_PickupRequest_Stg",
    "Staging_Ebay_Labels_Stg",
    "Staging_fl_ConItemSrv_Stg",
]

with DAG(
    dag_id="ssis_skeleton_hub_label_mf_only_Hist",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_label_mf_only", "Historical"],
    params={
        "BatchDays": -1,
        "DisableFinal": 0,
        "DisableStage": 0,
        "process_id": -4,
        "RecordSource4": "MyFastway",
        # Staging_Set_LastValue: use None so Jinja renders SQL NULL; override from trigger UI when needed.
        "ColumnName": None,
        "LastValue": None,
        "Force": False,
    },
) as dag:

    with TaskGroup(group_id="tg_package_source4_myfastway_mf") as tg_source4:
        # STOCK:SEQUENCE — ref_id: Package\Source4 (MyFastway) _MF

        op_9 = BigQueryInsertJobOperator(
            task_id="package_source4_myfastway_mf_truncate_fl_conitem_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_fl_ConItem_Stg`;",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Source4 (MyFastway) _MF\Load fl_ConItem_Stg (Pipeline -> SP)
        op_7 = BigQueryInsertJobOperator(
            task_id="package_source4_myfastway_mf_load_fl_conitem_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"CALL `{SP_DATASET_ID}.sp_load_Staging_fl_ConItem_Stg_Hist`();",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        op_9 >> op_7

    with TaskGroup(group_id="tg_package_sequence_container") as tg_sequence:
        # STOCK:SEQUENCE — ref_id: Package\Sequence Container

        op_5 = BigQueryInsertJobOperator(
            task_id="package_sequence_container_truncate_sat_label_allocation_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": "\n".join(
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.{tbl}`;"
                        for tbl in _STAGING_TABLES_TO_TRUNCATE
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Sequence Container\Load SAT_Label_Allocation_Stg — Exec [Staging].[Load_SAT_Label_Allocation_Stg] ProcessId
        op_3 = BigQueryInsertJobOperator(
            task_id="package_sequence_container_load_sat_label_allocation_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.staging_Load_SAT_Label_Allocation_Stg2`("
                        f"{{{{ dag_run.conf.get('process_id', params.process_id) }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Sequence Container\Load SAT_Label_Allocation — Exec [dv].[Load_SAT_Label_Allocation] ProcessId
        op_1 = BigQueryInsertJobOperator(
            task_id="package_sequence_container_load_sat_label_allocation",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_SAT_Label_Allocation`("
                        f"{{{{ dag_run.conf.get('process_id', params.process_id) }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Sequence Container\Load SAT_Label_Allocation_MF — Exec [dv].[Load_SAT_Label_Allocation_MF] ProcessId, RecordSource4
        op_2 = BigQueryInsertJobOperator(
            task_id="package_sequence_container_load_sat_label_allocation_mf",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_SAT_Label_Allocation_MF`("
                        f"{{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSource4 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Sequence Container\Set LastDate (MyFastway) — Staging_Set_LastValue(RecordSource4)
        op_4 = BigQueryInsertJobOperator(
            task_id="package_sequence_container_set_lastdate_myfastway",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.Staging_Set_LastValue`("
                        f"'{{{{ params.RecordSource4 }}}}', "
                        "{% if params.ColumnName is not none %}'{{ params.ColumnName }}'{% else %}NULL{% endif %}, "
                        "{% if params.LastValue is not none %}'{{ params.LastValue }}'{% else %}NULL{% endif %}, "
                        f"{{{{ params.Force }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        op_5 >> op_3 >> op_1 >> op_2 >> op_4

    tg_source4 >> tg_sequence