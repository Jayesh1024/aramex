"""
DAG for SSIS package: LoadControl (GCP / BigQuery).

GCP naming: SSIS schemas dv, dbo, Staging map to BigQuery identifiers by replacing only
the dot (e.g. [Staging].[LoadLog] → Staging_LoadLog, [Staging].[SaveLog] → Staging_SaveLog).

SSIS «Get Misceallaneous data» runs child package Miscellaneous.dtsx → TriggerDagRunOperator
to `params.miscellaneous_dag_id` (deploy that DAG or override the param).
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup

from utils.getValue import get_next_process_id

PACKAGE_NAME = "LoadControl"
SP_DATASET_ID = "Aramex_oceania_SP"
PROJECT_ID = "searce-sandbox-da-delivery"

with DAG(
    dag_id="ssis_skeleton_loadcontrol",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "loadcontrol"],
    params={
        # SSIS $Package::DisableLNKLoad (default 0 in LoadControl.dtsx)
        "disable_lnk_load": False,
        # Child of ExecutePackageTask «Get Misceallaneous data» → Miscellaneous.dtsx
        "miscellaneous_dag_id": "ssis_skeleton_miscellaneous",
    },
) as dag:

    # ref_id: Package\Get Next ProcessID — SSIS: ExecuteSQLTask; BQ: Staging_LoadLog
    op_3 = PythonOperator(
        task_id="package_get_next_processid",
        python_callable=get_next_process_id,
        op_kwargs={
            "project_id": PROJECT_ID,
            "dataset_id": SP_DATASET_ID,
        },
    )

    # ref_id: Package\Get Misceallaneous data — SSIS: ExecutePackageTask → Miscellaneous.dtsx
    op_2 = TriggerDagRunOperator(
        task_id="package_get_misceallaneous_data",
        trigger_dag_id="{{ params.miscellaneous_dag_id }}",
        wait_for_completion=True,
        reset_dag_run=False,
        conf={"process_id": "{{ ti.xcom_pull(task_ids='package_get_next_processid') }}"},
    )

    # ref_id: Package\Reserve ProcessID — SSIS batch + EXEC [Staging].[SaveLog]; BQ: script + CALL Staging_SaveLog
    _reserve_process_sql = (
        "DECLARE process_id INT64 DEFAULT {{ ti.xcom_pull(task_ids='package_get_next_processid') }};\n"
        "DECLARE disable_lnk_load BOOL DEFAULT "
        "{% if params.disable_lnk_load %}TRUE{% else %}FALSE{% endif %};\n"
        "DECLARE component STRING;\n"
        "SET component = IF(\n"
        "  disable_lnk_load,\n"
        "  'Load Labels - Job Start',\n"
        "  'Load TrackAndTrace - Job Start'\n"
        ");\n"
        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_SaveLog`(\n"
        "  component,\n"
        "  process_id,\n"
        "  CURRENT_TIMESTAMP(),\n"
        "  CAST(NULL AS TIMESTAMP),\n"
        "  CAST(NULL AS STRING),\n"
        "  '',\n"
        "  CAST(0 AS INT64)\n"
        ");\n"
    )

    op_18 = BigQueryInsertJobOperator(
        task_id="package_reserve_processid",
        configuration={
            "query": {
                "query": _reserve_process_sql,
                "useLegacySql": False,
            }
        },
        gcp_conn_id="google_cloud_default",
    )

    # --- control flow (nested TaskGroup per sequence container) ---
    with TaskGroup(group_id="tg_package_database_maintenance"):
        # STOCK:SEQUENCE — ref_id: Package\Database Maintenance
        op_0 = EmptyOperator(task_id="package_database_maintenance")

        # ref_id: Package\Database Maintenance\DB Maintenance
        op_1 = EmptyOperator(task_id="package_database_maintenance_db_maintenance")

    with TaskGroup(group_id="tg_package_load_dim_tables"):
        # STOCK:SEQUENCE — ref_id: Package\Load Dim tables
        op_4 = EmptyOperator(task_id="package_load_dim_tables")

        # ref_id: Package\Load Dim tables\Fact_KPI
        op_5 = EmptyOperator(task_id="package_load_dim_tables_fact_kpi")

        # ref_id: Package\Load Dim tables\Load Dim_Label
        op_6 = EmptyOperator(task_id="package_load_dim_tables_load_dim_label")

    with TaskGroup(group_id="tg_package_load_hub_tables"):
        # STOCK:SEQUENCE — ref_id: Package\Load HUB tables
        op_7 = EmptyOperator(task_id="package_load_hub_tables")

        with TaskGroup(group_id="tg_package_load_hub_tables_full_reload"):
            # STOCK:SEQUENCE — ref_id: Package\Load HUB tables\Full Reload
            op_8 = EmptyOperator(task_id="package_load_hub_tables_full_reload")

            # ref_id: Package\Load HUB tables\Full Reload\HUB_CF
            op_9 = EmptyOperator(task_id="package_load_hub_tables_full_reload_hub_cf")

            # ref_id: Package\Load HUB tables\Full Reload\HUB_Customer
            op_10 = EmptyOperator(task_id="package_load_hub_tables_full_reload_hub_customer")

            # ref_id: Package\Load HUB tables\Full Reload\HUB_Product
            op_11 = EmptyOperator(task_id="package_load_hub_tables_full_reload_hub_product")

            # ref_id: Package\Load HUB tables\Full Reload\HUB_RF
            op_12 = EmptyOperator(task_id="package_load_hub_tables_full_reload_hub_rf")

            # ref_id: Package\Load HUB tables\Full Reload\HUB_ScanStatus
            op_13 = EmptyOperator(task_id="package_load_hub_tables_full_reload_hub_scanstatus")

            # ref_id: Package\Load HUB tables\Full Reload\HUB_ServiceItem
            op_14 = EmptyOperator(task_id="package_load_hub_tables_full_reload_hub_serviceitem")

        # ref_id: Package\Load HUB tables\HUB_Invoice
        op_15 = EmptyOperator(task_id="package_load_hub_tables_hub_invoice")

        # ref_id: Package\Load HUB tables\HUB_Label
        op_16 = EmptyOperator(task_id="package_load_hub_tables_hub_label")

        # ref_id: Package\Load HUB tables\HUB_ServiceCon
        op_17 = EmptyOperator(task_id="package_load_hub_tables_hub_servicecon")

    with TaskGroup(group_id="tg_package_send_notification_email"):
        # STOCK:SEQUENCE — ref_id: Package\Send Notification Email
        op_19 = EmptyOperator(task_id="package_send_notification_email")

        # ref_id: Package\Send Notification Email\Get Summary Data
        op_20 = EmptyOperator(task_id="package_send_notification_email_get_summary_data")

        # ref_id: Package\Send Notification Email\Send Email
        op_21 = EmptyOperator(task_id="package_send_notification_email_send_email")

    # --- precedence (upstream >> downstream) ---
    op_4 >> op_0
    op_3 >> op_2
    op_7 >> op_4
    op_18 >> op_7
    op_8 >> op_15
    op_8 >> op_16
    op_8 >> op_17
    op_3 >> op_18
    op_0 >> op_19
    op_20 >> op_21
