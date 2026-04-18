"""
Completed DAG for SSIS package: Fact_KPI_Dashboard
Migration: SSIS -> BigQuery

Overall flow (from executable_dependencies.json):
  Staging (sequence container):
    Initial        -> Get Next ProcessID (negative sentinel, custom)
    Staging 1      -> [MyFastway] Truncate -> Get LastDate -> Load fl_MF_Interim_Stg
                      (pipeline) -> Data Flow Task (load fl_ConItem_Stg)
    Staging 2      -> [TrackAndTrace] Truncate -> Get LastScanID -> Load TAT_Stg
  Staging 3        -> [ConItemSrv] Truncate -> Get Start Date -> Load fl_ConItemSrv_Stg
                      -> Load Product ServiceItem_Stg (SP)
  Load Interim Labels (final):
    Load Interim_KPI_Labels_Src_Stg -> Load Fact_KPI_Daily_Stg -> Load Fact_KPI_Interim

See DAG_COMPLETION_NOTES.md §Fact_KPI_Dashboard for the (many) SP-name
inferences, the negative-sentinel ProcessID scheme (-30000), the
ISOCountryCodes package-level variable (hardcoded constant), and the
RecordSource4 / RecordSource1 defaults (also hardcoded).
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.hooks.bigquery import BigQueryHook
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup
from utils.getValue import get_last_value

PROJECT_ID = "searce-sandbox-da-delivery"
SP_DATASET_ID = "Aramex_oceania_SP"
TARGET_DATASET_ID = "Aramex_oceania"
PACKAGE_NAME = "Fact_KPI_Dashboard"

# SSIS $Package:: variables — defaults not in extracted metadata.
RECORD_SOURCE_4 = "RecordSource"
ISO_COUNTRY_CODES = "AUNZ"

_TASK_ID_GET_PROCESS_ID = "tg_package_staging.tg_package_staging_initial.package_staging_initial_get_next_processid"
_TASK_ID_GET_LAST_MF = "tg_package_staging.tg_package_staging_staging_1.package_staging_staging_1_get_lastdate_myfastway"
_TASK_ID_GET_LASTSCANID = "tg_package_staging.tg_package_staging_staging_2.package_staging_staging_2_get_lastscanid_trackandtrace"
_TASK_ID_GET_STARTDATE = "tg_package_staging_3.package_staging_3_get_start_date"


def _allocate_dashboard_processid(project_id: str, dataset_id: str) -> int:
    """Mirrors SSIS Package\\Staging\\Initial\\Get Next ProcessID:
        DECLARE @ProcessId Int;
        SELECT @ProcessId = IIF(MIN(ProcessId) > -30000, -30000, MIN(ProcessId))
        FROM [Staging].[LoadLog];
        SELECT IsNull(@ProcessId, 0) - 1 AS NextProcessId;
    """
    hook = BigQueryHook(project_id=project_id)
    query = (
        "WITH s AS ("
        "  SELECT MIN(ProcessId) AS min_pid "
        f"  FROM `{project_id}.{dataset_id}.Staging_LoadLog` "
        ") "
        "SELECT IFNULL(IF(min_pid > -30000, -30000, min_pid), 0) - 1 AS NextProcessId "
        "FROM s"
    )
    df = hook.get_df(sql=query, dialect="standard")
    return int(df.iloc[0, 0])


def _get_last_scan_id(project_id: str, dataset_id: str) -> int:
    """SSIS: SELECT LastID = MAX(ID) From Staging.TrackAndTrace_Stg"""
    hook = BigQueryHook(project_id=project_id)
    query = f"SELECT IFNULL(MAX(ID), 0) AS LastId FROM `{project_id}.{dataset_id}.Staging_TrackAndTrace_Stg`"
    df = hook.get_df(sql=query, dialect="standard")
    return int(df.iloc[0, 0])


def _get_start_date() -> str:
    """SSIS: SET @returnDate = CONVERT(varchar(10), DATEADD(DAY, -1, GETDATE()), 120) + 'T23:59:59.999';"""
    from datetime import datetime as _dt, timedelta as _td

    d = _dt.utcnow().date() - _td(days=1)
    return f"{d.isoformat()}T23:59:59.999"


with DAG(
    dag_id="ssis_skeleton_fact_kpi_dashboard",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "fact_kpi_dashboard"],
    params={
        "record_source_4": RECORD_SOURCE_4,
        "iso_country_codes": ISO_COUNTRY_CODES,
    },
) as dag:

    _xcom_processid = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_PROCESS_ID}') }}}}"
    _xcom_last_mf = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_LAST_MF}') }}}}"
    _xcom_last_scan = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_LASTSCANID}') }}}}"
    _xcom_start_date = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_STARTDATE}') }}}}"

    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE — ref_id: Package\Staging

        with TaskGroup(group_id="tg_package_staging_initial") as tg_initial:
            # STOCK:SEQUENCE — ref_id: Package\Staging\Initial

            # ref_id: Package\Staging\Initial\Get Next ProcessID
            op_11 = PythonOperator(
                task_id="package_staging_initial_get_next_processid",
                python_callable=_allocate_dashboard_processid,
                op_kwargs={
                    "project_id": PROJECT_ID,
                    "dataset_id": TARGET_DATASET_ID,
                },
            )

        with TaskGroup(group_id="tg_package_staging_staging_1") as tg_stg1:
            # STOCK:SEQUENCE — ref_id: Package\Staging\Staging 1

            # ref_id: Package\Staging\Staging 1\Truncate fl_MF_Interim_Stg
            op_16 = BigQueryInsertJobOperator(
                task_id="package_staging_staging_1_truncate_fl_mf_interim_stg",
                configuration={
                    "query": {
                        "query": f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_fl_MF_Interim_Stg`;",
                        "useLegacySql": False,
                    }
                },
            )

            # ref_id: Package\Staging\Staging 1\Get LastDate (MyFastway) — Exec [Staging].[Get_LastValue] RecordSource4
            op_14 = PythonOperator(
                task_id="package_staging_staging_1_get_lastdate_myfastway",
                python_callable=get_last_value,
                op_kwargs={
                    "project_id": PROJECT_ID,
                    "dataset_id": SP_DATASET_ID,
                    "record_source": "{{ params.record_source_4 }}",
                },
            )

            # ref_id: Package\Staging\Staging 1\Load fl_MF_Interim_Stg — pipeline -> inferred SP
            op_15 = BigQueryInsertJobOperator(
                task_id="package_staging_staging_1_load_fl_mf_interim_stg",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_load_fl_MF_Interim_Stg`("
                            f"SAFE_CAST('{_xcom_last_mf}' AS DATETIME), "
                            f"'{{{{ params.iso_country_codes }}}}');"
                        ),
                        "useLegacySql": False,
                    }
                },
            )

            # ref_id: Package\Staging\Staging 1\Data Flow Task — pipeline -> inferred SP (loads Staging.fl_ConItem_Stg from tmp.fl_Contitem_Stg)
            op_13 = BigQueryInsertJobOperator(
                task_id="package_staging_staging_1_data_flow_task",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_load_fl_ConItem_Stg`();"
                        ),
                        "useLegacySql": False,
                    }
                },
            )

            op_16 >> op_14 >> op_15 >> op_13

        with TaskGroup(group_id="tg_package_staging_staging_2") as tg_stg2:
            # STOCK:SEQUENCE — ref_id: Package\Staging\Staging 2

            # ref_id: Package\Staging\Staging 2\Truncate Staging tables
            op_21 = BigQueryInsertJobOperator(
                task_id="package_staging_staging_2_truncate_staging_tables",
                configuration={
                    "query": {
                        "query": f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_TrackAndTrace_Stg`;",
                        "useLegacySql": False,
                    }
                },
            )

            # ref_id: Package\Staging\Staging 2\Get LastScanID (TrackAndTrace) — SELECT MAX(ID) ...
            op_19 = PythonOperator(
                task_id="package_staging_staging_2_get_lastscanid_trackandtrace",
                python_callable=_get_last_scan_id,
                op_kwargs={
                    "project_id": PROJECT_ID,
                    "dataset_id": TARGET_DATASET_ID,
                },
            )

            # ref_id: Package\Staging\Staging 2\Load TrackAndTrace_Stg — pipeline -> inferred SP (LastScanID, ISOCountryCodes)
            op_20 = BigQueryInsertJobOperator(
                task_id="package_staging_staging_2_load_trackandtrace_stg",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_load_TrackAndTrace_Stg`("
                            f"SAFE_CAST('{_xcom_last_scan}' AS INT64), "
                            f"'{{{{ params.iso_country_codes }}}}');"
                        ),
                        "useLegacySql": False,
                    }
                },
            )

            op_21 >> op_19 >> op_20

    with TaskGroup(group_id="tg_package_staging_3") as tg_stg3:
        # STOCK:SEQUENCE — ref_id: Package\Staging 3

        # ref_id: Package\Staging 3\Truncate fl_conitmsrv_stg
        op_9 = BigQueryInsertJobOperator(
            task_id="package_staging_3_truncate_fl_conitmsrv_stg",
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

        # ref_id: Package\Staging 3\Get Start Date — Python scalar push
        op_6 = PythonOperator(
            task_id="package_staging_3_get_start_date",
            python_callable=_get_start_date,
        )

        # ref_id: Package\Staging 3\Load fl_ConItemSrv_Stg — pipeline -> inferred SP (StartDate, ISOCountryCodes)
        op_8 = BigQueryInsertJobOperator(
            task_id="package_staging_3_load_fl_conitemsrv_stg",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_load_fl_ConItemSrv_Stg_Interim`("
                        f"SAFE_CAST('{_xcom_start_date}' AS DATETIME), "
                        f"'{{{{ params.iso_country_codes }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging 3\Load Product ServiceItem_Stg — [Staging].[Load_Label_Product_ServiceItem_Stg_Interim] ProcessId, RecordSource4
        op_7 = BigQueryInsertJobOperator(
            task_id="package_staging_3_load_product_serviceitem_stg",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_Load_Label_Product_ServiceItem_Stg_Interim`("
                        f"{_xcom_processid}, "
                        f"'{{{{ params.record_source_4 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        op_9 >> op_6 >> op_8 >> op_7

    with TaskGroup(group_id="tg_package_load_interim_labels") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\Load Interim Labels

        # ref_id: Package\Load Interim Labels\Load Interim_KPI_Labels_Src_Stg — Exec Mini_FastwayDW.[Staging].[Load_Fact_KPI_Interim_Src_Stg] ProcessId
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

        # ref_id: Package\Load Interim Labels\Load Fact_KPI_Daily_Stg — Exec [Staging].[Load_Fact_KPI_Daily_Stg_2] ProcessId
        op_1 = BigQueryInsertJobOperator(
            task_id="package_load_interim_labels_load_fact_kpi_daily_stg",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_Load_Fact_KPI_Daily_Stg_2`("
                        f"{_xcom_processid});"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Load Interim Labels\Load Fact_KPI_Interim — Exec [dbo].[Load_Fact_KPI_Interim] ProcessId
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

    op_11 >> tg_stg1
    op_11 >> tg_stg2
    tg_staging >> tg_stg3 >> tg_final
