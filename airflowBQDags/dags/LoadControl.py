"""
DAG for SSIS package: LoadControl (GCP / BigQuery).

LoadControl is the top-level orchestrator; every other HUB / Dim SSIS
package runs as an `Microsoft.ExecutePackageTask` under this one. In Airflow
we implement those with `TriggerDagRunOperator`, each targeting the
corresponding `ssis_skeleton_*` child DAG. The two inline `Microsoft.ExecuteSQLTask`
steps (Get Next ProcessID, Reserve ProcessID) become a PythonOperator + a
BigQueryInsertJobOperator calling `Staging_SaveLog`. The final
`Microsoft.ScriptTask` (Send Email) has no BigQuery/Airflow equivalent and is
left as an `EmptyOperator` placeholder — same blocker as
`Export_KPI_Performance` (see DAG_COMPLETION_NOTES.md).

The SSIS `Database Maintenance` sequence container (Rebuild/Defrag indexes,
Release Space) has been dropped entirely — BigQuery is a columnar, storage-
decoupled engine with no indexes to maintain and no files to shrink, so those
tasks have no equivalent and there is no child DAG to trigger for them.

GCP naming: SSIS schemas dv, dbo, Staging map to BigQuery identifiers by
replacing the dot (e.g. [Staging].[LoadLog] → `Staging_LoadLog`,
[dbo].[Load_Dim_Label] → `dbo_Load_Dim_Label`).

Child-DAG parameter propagation: the `process_id` allocated by Get Next
ProcessID is broadcast to every triggered child DAG via `conf={"process_id": ...}`.
Child DAGs currently expose `process_id` only through `DAG(params=...)`; they
will need a small follow-up change to read from `dag_run.conf.get("process_id")`
when it is set (flagged in DAG_COMPLETION_NOTES.md — the existing default of 1
is used when LoadControl is not the parent).
"""
from __future__ import annotations

import os

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup
import pendulum

from utils.getValue import get_next_process_id

GCP_PROJECT_ID = os.getenv("GCP_PROJECT_ID")
SP_DATASET_ID = os.getenv("SP_DATASET_ID")
TARGET_DATASET_ID = os.getenv("TARGET_DATASET_ID")

nz_tz = pendulum.timezone("Pacific/Auckland")

_GET_PROCESSID_XCOM = (
    "{{ ti.xcom_pull(task_ids='package_get_next_processid') }}"
)

with DAG(
    dag_id="ssis_skeleton_loadcontrol",
    start_date=pendulum.datetime(2026, 4, 1, tz="Pacific/Auckland"),
    schedule_interval="0 1 * * *",
    catchup=False,
    tags=["ssis", "skeleton", "loadcontrol"],
    params={
        "DisableAddressLoad": 0,
        "DisableDimLoad": 0,
        "DisableFinal": 0,
        "DisableHUBLoad": 0,
        "DisableIndexMtce": -1,
        "DisableLNKLoad": 0,
        "DisableStaging": 0,
        "GLB02": 'glb-util-02',
        "MyFastwayAltLargeWinDoW": 1,
        "MyFastwayWinSizeDays": 7,
        "RedoAllKPIs": 0,
        "SendLoadEmailTo": 'barry_woods@bigpond.com',
    },
) as dag:

    op_3 = PythonOperator(
        task_id="package_get_next_processid",
        python_callable=get_next_process_id,
        op_kwargs={
            "project_id": GCP_PROJECT_ID,
            "dataset_id": TARGET_DATASET_ID,
        },
    )


    _reserve_process_sql = (
        # Assign process_id and disable_lnk_load from params/XCOM (mimicking input params in original SQL)
        f"DECLARE process_id INT64 DEFAULT {_GET_PROCESSID_XCOM};\n"
        "DECLARE disable_lnk_load BOOL DEFAULT {% if params.DisableLNKLoad %}TRUE{% else %}FALSE{% endif %};\n"
        "\n"
        "-- Reserve ProcessId for this job\n"
        "DECLARE component STRING DEFAULT 'Load TrackAndTrace - Job Start';\n"
        "DECLARE started DATETIME DEFAULT CURRENT_DATETIME();\n"
        "DECLARE ended DATETIME;\n"
        "DECLARE result STRING;\n"
        "DECLARE error_message STRING DEFAULT '';\n"
        "DECLARE inserted INT64 DEFAULT 0;\n"
        "\n"
        "-- Adjust component name based on load flag\n"
        "IF (disable_lnk_load) THEN\n"
        "  SET component = 'Load Labels - Job Start';\n"
        "END IF;\n"
        "\n"
        "-- Execute logging procedure\n"
        f"CALL `{SP_DATASET_ID}.Staging_SaveLog`(\n"
        "  component,\n"
        "  process_id,\n"
        "  started,\n"
        "  ended,\n"
        "  result,\n"
        "  error_message,\n"
        "  inserted,\n"
        "  -1,\n"
        "  -1\n"
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
    )

    with TaskGroup(group_id="tg_package_load_hub_tables") as tg_load_hub_tables:
        with TaskGroup(
            group_id="tg_package_load_hub_tables_full_reload"
        ) as tg_full_reload:
            op_9 = TriggerDagRunOperator(
                task_id="package_load_hub_tables_full_reload_hub_cf",
                trigger_dag_id="ssis_skeleton_hub_cf",
                wait_for_completion=True,
                poke_interval=30,
                reset_dag_run=True,
                conf={"process_id": _GET_PROCESSID_XCOM},
            )

            op_10 = TriggerDagRunOperator(
                task_id="package_load_hub_tables_full_reload_hub_customer",
                trigger_dag_id="ssis_skeleton_hub_customer",
                wait_for_completion=True,
                poke_interval=30,
                reset_dag_run=True,
                conf={"process_id": _GET_PROCESSID_XCOM},
            )

            op_11 = TriggerDagRunOperator(
                task_id="package_load_hub_tables_full_reload_hub_product",
                trigger_dag_id="ssis_skeleton_hub_product",
                wait_for_completion=True,
                poke_interval=30,
                reset_dag_run=True,
                conf={"process_id": _GET_PROCESSID_XCOM},
            )

            op_12 = TriggerDagRunOperator(
                task_id="package_load_hub_tables_full_reload_hub_rf",
                trigger_dag_id="ssis_skeleton_hub_rf",
                wait_for_completion=True,
                poke_interval=30,
                reset_dag_run=True,
                conf={"process_id": _GET_PROCESSID_XCOM},
            )

            op_13 = TriggerDagRunOperator(
                task_id="package_load_hub_tables_full_reload_hub_scanstatus",
                trigger_dag_id="ssis_skeleton_hub_scanstatus",
                wait_for_completion=True,
                poke_interval=30,
                reset_dag_run=True,
                conf={"process_id": _GET_PROCESSID_XCOM},
            )

            op_14 = TriggerDagRunOperator(
                task_id="package_load_hub_tables_full_reload_hub_serviceitem",
                trigger_dag_id="ssis_skeleton_hub_serviceitem",
                wait_for_completion=True,
                poke_interval=30,
                reset_dag_run=True,
                conf={"process_id": _GET_PROCESSID_XCOM},
            )

        op_15 = TriggerDagRunOperator(
            task_id="package_load_hub_tables_hub_invoice",
            trigger_dag_id="ssis_skeleton_hub_invoice",
            wait_for_completion=True,
            poke_interval=30,
            reset_dag_run=True,
            conf={"process_id": _GET_PROCESSID_XCOM},
        )

        op_16 = TriggerDagRunOperator(
            task_id="package_load_hub_tables_hub_label",
            trigger_dag_id="ssis_skeleton_hub_label",
            wait_for_completion=True,
            poke_interval=30,
            reset_dag_run=True,
            conf={"process_id": _GET_PROCESSID_XCOM},
        )

        op_17 = TriggerDagRunOperator(
            task_id="package_load_hub_tables_hub_servicecon",
            trigger_dag_id="ssis_skeleton_hub_servicecon",
            wait_for_completion=True,
            poke_interval=30,
            reset_dag_run=True,
            conf={"process_id": _GET_PROCESSID_XCOM},
        )

        tg_full_reload >> [op_15, op_16, op_17]

    with TaskGroup(group_id="tg_package_load_dim_tables") as tg_load_dim_tables:
        op_5 = TriggerDagRunOperator(
            task_id="package_load_dim_tables_fact_kpi",
            trigger_dag_id="ssis_skeleton_fact_kpi",
            wait_for_completion=True,
            poke_interval=30,
            reset_dag_run=True,
            conf={"process_id": _GET_PROCESSID_XCOM},
        )

        op_6 = BigQueryInsertJobOperator(
            task_id="package_load_dim_tables_load_dim_label",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dbo_Load_Dim_Label`("
                        f"{_GET_PROCESSID_XCOM}, "
                        f"SAFE_CAST('{{{{ data_interval_start }}}}' AS DATETIME));"
                    ),
                    "useLegacySql": False,
                }
            },
        )

    with TaskGroup(
        group_id="tg_package_send_notification_email"
    ) as tg_send_notification_email:
        op_20 = BigQueryInsertJobOperator(
            task_id="package_send_notification_email_get_summary_data",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.Staging_Get_LoadReportHtml`("
                        f"{_GET_PROCESSID_XCOM}, "
                        f"CAST('{{{{ dag_run.id }}}}' AS INT64));"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        op_21 = EmptyOperator(task_id="package_send_notification_email_send_email")

        op_20 >> op_21

    op_3 >> op_18
    op_18 >> tg_load_hub_tables
    tg_load_hub_tables >> tg_load_dim_tables
    tg_load_dim_tables >> tg_send_notification_email
