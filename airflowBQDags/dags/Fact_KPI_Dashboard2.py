"""
Completed DAG for SSIS package: Fact_KPI_Dashboard2
Migration: SSIS -> BigQuery

Structurally similar to Fact_KPI_Dashboard but:
  * `Get Next ProcessID` sits directly under Package\Staging (not \Initial).
  * Staging 3 is inside Package\Staging (not separate \Staging 3).
  * TrackAndTrace uses `[Staging].[Get_LastValue_Scans]` (-> 3-column result
    set LastId/LastDate/EndDate) rather than the single-value helper.
  * Product ServiceItem uses `[dv].[Load_Label_Product_ServiceItem_Stg_Interim]`
    (dv schema; same logical SP as dv_Load_Label_Product_ServiceItem_Stg_Interim
    confirmed in ProceduresBQ/sp_parameters.json).
  * Final uses `Load_Fact_KPI_Daily_Stg` (no `_2` suffix).

See DAG_COMPLETION_NOTES.md §Fact_KPI_Dashboard2 for SP-name inferences,
the -30000 sentinel, ISOCountryCodes (hardcoded constant), RecordSource3/4
defaults, and the Staging_Get_LastValue_Scans non-trivial signature
(RecordSource, CalcMethod, EndDate INOUT, MaxDays) — only one of four
inputs is bound in SSIS so CalcMethod / MaxDays defaults are required.
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup
from utils.getValue import (
    allocate_dashboard_processid,
    get_last_value,
    get_last_value_scans,
    get_yesterday_eod_iso,
)

PROJECT_ID = "searce-sandbox-da-delivery"
SP_DATASET_ID = "Aramex_oceania_SP"
TARGET_DATASET_ID = "Aramex_oceania"
PACKAGE_NAME = "Fact_KPI_Dashboard2"

# SSIS $Package:: defaults — not in extracted metadata, placeholders.
RECORD_SOURCE_3 = "RecordSource3"
RECORD_SOURCE_4 = "RecordSource"
ISO_COUNTRY_CODES = "AUNZ"
# Staging_Get_LastValue_Scans requires a CalcMethod — SSIS binds only RecordSource.
# Conservative default picks 'UploadDate' (Staging_LoadControl-driven path).
GET_LASTVALUE_SCANS_CALC_METHOD = "UploadDate"
GET_LASTVALUE_SCANS_MAX_DAYS = -99

_TASK_ID_GET_PROCESS_ID = "tg_package_staging.package_staging_get_next_processid"
_TASK_ID_GET_LAST_MF = "tg_package_staging.tg_package_staging_staging_1.package_staging_staging_1_get_lastdate_myfastway"
_TASK_ID_GET_LASTSCANDATE = "tg_package_staging.tg_package_staging_staging_2.package_staging_staging_2_get_lastscandate_trackandtrace"
_TASK_ID_GET_STARTDATE = "tg_package_staging.tg_package_staging_staging_3.package_staging_staging_3_get_start_date"


with DAG(
    dag_id="ssis_skeleton_fact_kpi_dashboard2",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "fact_kpi_dashboard2"],
    params={
        "record_source_3": RECORD_SOURCE_3,
        "record_source_4": RECORD_SOURCE_4,
        "iso_country_codes": ISO_COUNTRY_CODES,
    },
) as dag:

    _xcom_processid = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_PROCESS_ID}') }}}}"
    _xcom_last_mf = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_LAST_MF}') }}}}"
    _xcom_last_scandate = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_LASTSCANDATE}') }}}}"
    _xcom_start_date = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_STARTDATE}') }}}}"

    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE — ref_id: Package\Staging

        # ref_id: Package\Staging\Get Next ProcessID — negative sentinel (-30000) scheme
        op_5 = PythonOperator(
            task_id="package_staging_get_next_processid",
            python_callable=allocate_dashboard_processid,
            op_kwargs={
                "project_id": PROJECT_ID,
                "dataset_id": TARGET_DATASET_ID,
            },
        )

        with TaskGroup(group_id="tg_package_staging_staging_1") as tg_stg1:

            # ref_id: Package\Staging\Staging 1\Truncate fl_MF_Interim_Stg
            op_9 = BigQueryInsertJobOperator(
                task_id="package_staging_staging_1_truncate_fl_mf_interim_stg",
                configuration={
                    "query": {
                        "query": f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_fl_MF_Interim_Stg`;",
                        "useLegacySql": False,
                    }
                },
            )

            # ref_id: Package\Staging\Staging 1\Get LastDate (MyFastway) — [Staging].[Get_LastValue] RecordSource4
            op_7 = PythonOperator(
                task_id="package_staging_staging_1_get_lastdate_myfastway",
                python_callable=get_last_value,
                op_kwargs={
                    "project_id": PROJECT_ID,
                    "dataset_id": SP_DATASET_ID,
                    "record_source": "{{ params.record_source_4 }}",
                },
            )

            # ref_id: Package\Staging\Staging 1\Load fl_MF_Interim_Stg — pipeline -> inferred SP (LastDate)
            op_8 = BigQueryInsertJobOperator(
                task_id="package_staging_staging_1_load_fl_mf_interim_stg",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_load_fl_MF_Interim_Stg`("
                            f"SAFE_CAST('{_xcom_last_mf}' AS DATETIME));"
                        ),
                        "useLegacySql": False,
                    }
                },
            )

            op_9 >> op_7 >> op_8

        with TaskGroup(group_id="tg_package_staging_staging_2") as tg_stg2:

            # ref_id: Package\Staging\Staging 2\Truncate Staging tables
            op_14 = BigQueryInsertJobOperator(
                task_id="package_staging_staging_2_truncate_staging_tables",
                configuration={
                    "query": {
                        "query": f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_TrackAndTrace_Stg`;",
                        "useLegacySql": False,
                    }
                },
            )

            # ref_id: Package\Staging\Staging 2\Get LastScanDate (TrackAndTrace) — Staging_Get_LastValue_Scans
            op_12 = PythonOperator(
                task_id="package_staging_staging_2_get_lastscandate_trackandtrace",
                python_callable=get_last_value_scans,
                op_kwargs={
                    "project_id": PROJECT_ID,
                    "dataset_id": SP_DATASET_ID,
                    "record_source": "{{ params.record_source_3 }}",
                    "calc_method": GET_LASTVALUE_SCANS_CALC_METHOD,
                    "max_days": GET_LASTVALUE_SCANS_MAX_DAYS,
                },
            )

            # ref_id: Package\Staging\Staging 2\Load TrackAndTrace_Stg — pipeline -> inferred SP (LastScanDate)
            op_13 = BigQueryInsertJobOperator(
                task_id="package_staging_staging_2_load_trackandtrace_stg",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_load_TrackAndTrace_Stg`("
                            f"SAFE_CAST('{_xcom_last_scandate}' AS DATETIME));"
                        ),
                        "useLegacySql": False,
                    }
                },
            )

            op_14 >> op_12 >> op_13

        with TaskGroup(group_id="tg_package_staging_staging_3") as tg_stg3:

            # ref_id: Package\Staging\Staging 3\Truncate fl_conitmsrv_stg
            op_19 = BigQueryInsertJobOperator(
                task_id="package_staging_staging_3_truncate_fl_conitmsrv_stg",
                configuration={
                    "query": {
                        "query": (
                            f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_fl_ConItemSrv_Stg_Interim`;\n"
                            f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_Label_Product_ServiceItem_Stg_Interim`;"
                        ),
                        "useLegacySql": False,
                    }
                },
            )

            # ref_id: Package\Staging\Staging 3\Get Start Date — Python scalar push
            op_16 = PythonOperator(
                task_id="package_staging_staging_3_get_start_date",
                python_callable=get_yesterday_eod_iso,
            )

            # ref_id: Package\Staging\Staging 3\Load fl_ConItemSrv_Stg — pipeline -> inferred SP (StartDate)
            op_18 = BigQueryInsertJobOperator(
                task_id="package_staging_staging_3_load_fl_conitemsrv_stg",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_load_fl_ConItemSrv_Stg_Interim`("
                            f"SAFE_CAST('{_xcom_start_date}' AS DATETIME));"
                        ),
                        "useLegacySql": False,
                    }
                },
            )

            # ref_id: Package\Staging\Staging 3\Load Product ServiceItem_Stg — [dv].[Load_Label_Product_ServiceItem_Stg_Interim] ProcessId, RecordSource4
            op_17 = BigQueryInsertJobOperator(
                task_id="package_staging_staging_3_load_product_serviceitem_stg",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_Label_Product_ServiceItem_Stg_Interim`("
                            f"{_xcom_processid}, "
                            f"'{{{{ params.record_source_4 }}}}');"
                        ),
                        "useLegacySql": False,
                    }
                },
            )

            op_19 >> op_16 >> op_18 >> op_17

        op_5 >> [tg_stg1, tg_stg2, tg_stg3]

    with TaskGroup(group_id="tg_package_load_interim_labels") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\Load Interim Labels

        # ref_id: Package\Load Interim Labels\Load Interim_KPI_Labels_Src_Stg — [Staging].[Load_Fact_KPI_Interim_Src_Stg] ProcessId
        op_3 = BigQueryInsertJobOperator(
            task_id="package_load_interim_labels_load_interim_kpi_labels_src_stg",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_Load_Fact_KPI_Interim_Src_Stg`("
                        f"{_xcom_processid});"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Load Interim Labels\Load Fact_KPI_Daily_Stg — [Staging].[Load_Fact_KPI_Daily_Stg] ProcessId
        op_1 = BigQueryInsertJobOperator(
            task_id="package_load_interim_labels_load_fact_kpi_daily_stg",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_Load_Fact_KPI_Daily_Stg`("
                        f"{_xcom_processid});"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Load Interim Labels\Load Fact_KPI_Interim — [dbo].[Load_Fact_KPI_Interim] ProcessId
        op_2 = BigQueryInsertJobOperator(
            task_id="package_load_interim_labels_load_fact_kpi_interim",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dbo_Load_Fact_KPI_Interim`("
                        f"{_xcom_processid});"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        op_3 >> op_1 >> op_2

    tg_staging >> tg_final
