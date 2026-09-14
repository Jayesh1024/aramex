"""
Completed DAG for SSIS package: DLS_Manual_Pricing
Migration: SSIS -> BigQuery

Precedence from executable_dependencies.json (single sequence under Source2 (DynamicLabel) _DL).

RecordSource-style inputs use metadata variable_name: param uses
params.RecordSource2 (see Get LastId, Load Lastest Priced Invoices).

Insert Into … (large TRUNCATE/INSERT in metadata) and Update Dim_Label (UPDATE script) map to BigQuery procedures.
Get Next ProcessID uses an inline SELECT (ExecuteSQLTask query, not EXEC). SSIS variable chaining for LastID / NextProcessId
is approximated with params.adhoc_history_last_id and params.process_id — adjust or add XCom if you need exact SSIS binding.
`ChangedSince` is the second arg to `dbo_Load_Dim_Label` (DATETIME); override per trigger if needed.
"""
from __future__ import annotations

import pendulum
from airflow import DAG
from airflow.models import Variable
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup
from utils.getValue import get_last_value

# --- Project Configuration ---
GCP_PROJECT_ID = Variable.get("PROJECT_ID")
SP_DATASET_ID = Variable.get("SP_DATASET_ID")
TARGET_DATASET_ID = Variable.get("TARGET_DATASET_ID")
_TASK_ID_GET_LAST_ID = "tg_package_source2_dynamiclabel_dl.package_source2_dynamiclabel_dl_get_lastid_dynamiclabel"


default_args = {
    'owner': 'airflow',
    'depends_on_past': True,
    'retries': 3,
}

with DAG(
    dag_id="ssis_skeleton_dls_manual_pricing",
    start_date=pendulum.datetime(2026, 4, 1, tz="Pacific/Auckland"),
    schedule_interval="0 8 * * 0",
    catchup=False,
    default_args=default_args,
    tags=["ssis", "skeleton", "dls_manual_pricing", "RecordSource_DynamicLabel", "Incremental"],
    params={
        "Disable_DynamicLabel": 0,
        "process_id": 3000,
        "RecordSource2": 'DynamicLabel',
        "ReturnCode2": 0,
        "adhoc_history_last_id": 0,
        # Second arg to dbo_Load_Dim_Label( ProcessID, ChangedSince ) — e.g. manual trigger or conf override.
        "ChangedSince": "1900-01-01 00:00:00",
    },
) as dag:

    with TaskGroup(group_id="tg_package_source2_dynamiclabel_dl"):
        # STOCK:SEQUENCE — ref_id: Package\Source2 (DynamicLabel) _DL

        # ref_id: …\Truncate API_RF_AdHocLabel_AllocationHistory_Stg_Weekly
        op_1 = BigQueryInsertJobOperator(
            task_id="package_source2_dynamiclabel_dl_truncate_api_rf_adhoclabel_allocationhistory_stg_weekly",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_API_RF_AdHocLabel_AllocationHistory_Stg_Weekly`;"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: …\Get LastId (DynamicLabel) — Exec [Staging].[Get_LastValue] ? (RecordSource2)
        op_2 = PythonOperator(
            task_id="package_source2_dynamiclabel_dl_get_lastid_dynamiclabel",
            python_callable=get_last_value,
            op_kwargs={
                "project_id": GCP_PROJECT_ID,
                "dataset_id": SP_DATASET_ID,
                "record_source": "{{ params.RecordSource2 }}",
            },
        )

        # ref_id: …\Load API_RF_AdHocLabel_AllocationHistory_Stg_Weekly — pipeline → Staging (BQ: SP; ? LastID → param)
        op_3 = BigQueryInsertJobOperator(
            task_id="package_source2_dynamiclabel_dl_load_api_rf_adhoclabel_allocationhistory_stg_weekly",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.sp_load_Staging_API_RF_AdHocLabel_AllocationHistory_Stg_Weekly`("
                        f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_LAST_ID}') | int }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: …\Insert Into API_RF_AdHocLabel_AllocationHistory_Stg — metadata TRUNCATE+INSERT script (BQ: SP)
        op_4 = BigQueryInsertJobOperator(
            task_id="package_source2_dynamiclabel_dl_insert_into_api_rf_adhoclabel_allocationhistory_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.sp_load_Staging_API_RF_AdHocLabel_AllocationHistory_Stg`("
                        f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_LAST_ID}') | int }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: …\Get Next ProcessID — metadata inline DECLARE/SELECT from Staging.LoadLog
        op_5 = BigQueryInsertJobOperator(
            task_id="package_source2_dynamiclabel_dl_get_next_processid",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"SELECT COALESCE(MAX(ProcessId), 0) + 1 AS NextProcessId "
                        f"FROM `{TARGET_DATASET_ID}.Staging_LoadLog`;"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: …\Load Lastest Priced Invoices — Exec [dv].[Load_SAT_Label_Allocation_DL] ?,? (ProcessId, RecordSource2)
        op_6 = BigQueryInsertJobOperator(
            task_id="package_source2_dynamiclabel_dl_load_lastest_priced_invoices",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_SAT_Label_Allocation_DL`({{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSource2 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: …\Update Dim_Label — metadata UPDATE … WHERE ProcessId = ? (BQ: SP)
        op_7 = BigQueryInsertJobOperator(
            task_id="package_source2_dynamiclabel_dl_update_dim_label",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dbo_Load_Dim_Label`("
                        f"{{{{ dag_run.conf.get('process_id', params.process_id) }}}}, "
                        f"DATETIME('{{{{ params.ChangedSince }}}}') "
                        f");"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        op_1 >> op_2 >> op_3 >> op_4 >> op_5 >> op_6 >> op_7
