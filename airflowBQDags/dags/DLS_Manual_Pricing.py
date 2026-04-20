"""
Completed DAG for SSIS package: DLS_Manual_Pricing
Migration: SSIS -> BigQuery

Precedence from executable_dependencies.json (single sequence under Source2 (DynamicLabel) _DL).

RecordSource-style inputs use metadata variable_name: param uses
params.RecordSource2 (see Get LastId, Load Lastest Priced Invoices).

Insert Into … (large TRUNCATE/INSERT in metadata) and Update Dim_Label (UPDATE script) map to BigQuery procedures.
Get Next ProcessID uses an inline SELECT (ExecuteSQLTask query, not EXEC). SSIS variable chaining for LastID / NextProcessId
is approximated with params.adhoc_history_last_id and params.ProcessId — adjust or add XCom if you need exact SSIS binding.
"""
from __future__ import annotations

from datetime import datetime
import os

from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup

# --- Project Configuration ---
PROJECT_ID = os.getenv("PROJECT_ID")
SP_DATASET_ID = os.getenv("SP_DATASET_ID")
TARGET_DATASET_ID = os.getenv("TARGET_DATASET_ID")

with DAG(
    dag_id="ssis_skeleton_dls_manual_pricing",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "dls_manual_pricing"],
    params={
        "Disable_DynamicLabel": 0,
        "ProcessId": 1347,
        "RecordSource2": 'DynamicLabel',
        "ReturnCode2": 0,
        "adhoc_history_last_id": 0,
    },
) as dag:

    with TaskGroup(group_id="tg_package_source2_dynamiclabel_dl"):
        # STOCK:SEQUENCE — ref_id: Package\Source2 (DynamicLabel) _DL

        # ref_id: …\Truncate API_RF_AdHocLabel_AllocationHistory_Stg_Weekly
        op_1 = BigQueryInsertJobOperator(
            task_id="package_source2_dynamiclabel_dl_truncate_api_rf_adhoclabel_allocationhistory_stg_weekly",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_API_RF_AdHocLabel_AllocationHistory_Stg_Weekly`;"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: …\Get LastId (DynamicLabel) — Exec [Staging].[Get_LastValue] ? (RecordSource2)
        op_2 = BigQueryInsertJobOperator(
            task_id="package_source2_dynamiclabel_dl_get_lastid_dynamiclabel",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_Get_LastValue`("
                        "'{{ params.RecordSource2 }}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: …\Load API_RF_AdHocLabel_AllocationHistory_Stg_Weekly — pipeline → Staging (BQ: SP; ? LastID → param)
        op_3 = BigQueryInsertJobOperator(
            task_id="package_source2_dynamiclabel_dl_load_api_rf_adhoclabel_allocationhistory_stg_weekly",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.sp_load_Staging_API_RF_AdHocLabel_AllocationHistory_Stg_Weekly`("
                        "{{ params.adhoc_history_last_id }});"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: …\Insert Into API_RF_AdHocLabel_AllocationHistory_Stg — metadata TRUNCATE+INSERT script (BQ: SP)
        op_4 = BigQueryInsertJobOperator(
            task_id="package_source2_dynamiclabel_dl_insert_into_api_rf_adhoclabel_allocationhistory_stg",
            configuration={
                "query": {
                    "query": f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.sp_load_Staging_API_RF_AdHocLabel_AllocationHistory_Stg`();",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: …\Get Next ProcessID — metadata inline DECLARE/SELECT from Staging.LoadLog
        op_5 = BigQueryInsertJobOperator(
            task_id="package_source2_dynamiclabel_dl_get_next_processid",
            configuration={
                "query": {
                    "query": (
                        f"SELECT COALESCE(MAX(ProcessId), 0) + 1 AS NextProcessId "
                        f"FROM `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_LoadLog`;"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: …\Load Lastest Priced Invoices — Exec [dv].[Load_SAT_Label_Allocation_DL] ?,? (ProcessId, RecordSource2)
        op_6 = BigQueryInsertJobOperator(
            task_id="package_source2_dynamiclabel_dl_load_lastest_priced_invoices",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_SAT_Label_Allocation_DL`("
                        "{{ params.ProcessId }}, '{{ params.RecordSource2 }}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: …\Update Dim_Label — metadata UPDATE … WHERE ProcessId = ? (BQ: SP)
        op_7 = BigQueryInsertJobOperator(
            task_id="package_source2_dynamiclabel_dl_update_dim_label",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dbo_Load_Dim_Label`("
                        "{{ params.ProcessId }});"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        op_1 >> op_2 >> op_3 >> op_4 >> op_5 >> op_6 >> op_7
