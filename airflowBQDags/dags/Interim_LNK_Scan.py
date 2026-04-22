"""
Completed DAG for SSIS package: Interim_LNK_Scan
Migration: SSIS -> BigQuery

Combines the InterimStaging variant of LNK_Scan loading and the SignatureAI
sub-branch. Uses the negative-sentinel ProcessID scheme and two separate
LoadControl RecordSources (RecordSource1=SignatureAI, RecordSource3=TrackAndTrace).

See DAG_COMPLETION_NOTES.md §Interim_LNK_Scan for SP-name inferences on
the TrackAndTrace and SignatureAI pipelines (the BQ layer uses
`InterimStaging_load_<TableName>` — mirrors HUB_Invoice conventions).
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

_TASK_ID_GET_PROCESS_ID = "tg_package_staging.package_staging_get_processid"
_TASK_ID_GET_LAST_SIGAI = "tg_package_staging.package_staging_get_last_date_signatureai"
_TASK_ID_GET_LAST_TT = "tg_package_staging.package_staging_get_last_id_trackandtraceid"


with DAG(
    dag_id="ssis_skeleton_interim_lnk_scan",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "interim_lnk_scan"],
    params={
        "DisableFinal": 0,
        "DisableStaging": 0,
        "ProcessId": -101703,
        "RecordSource1": 'TrackAndTraceData_SignatureAI',
        "RecordSource3": 'TrackAndTraceID',
    },
) as dag:

    _xcom_processid = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_PROCESS_ID}') }}}}"
    _xcom_last_sigai = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_LAST_SIGAI}') }}}}"
    _xcom_last_tt = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_LAST_TT}') }}}}"

    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE — ref_id: Package\Staging

        # ref_id: Package\Staging\Get ProcessID — negative sentinel (< -99999)
        op_18 = PythonOperator(
            task_id="package_staging_get_processid",
            python_callable=allocate_negative_sentinel_processid,
            op_kwargs={
                "project_id": PROJECT_ID,
                "dataset_id": TARGET_DATASET_ID,
            },
        )

        # ref_id: Package\Staging\Truncate Staging tables
        op_21 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_staging_tables",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.InterimStaging_TrackAndTrace_Stg`;\n"
                        f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.InterimStaging_TrackAndTraceData_SignatureAI_Stg`;"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging\Get Last Date (SignatureAI) — [Staging].[Get_LastValue] RecordSource1
        op_16 = PythonOperator(
            task_id="package_staging_get_last_date_signatureai",
            python_callable=get_last_value,
            op_kwargs={
                "project_id": PROJECT_ID,
                "dataset_id": SP_DATASET_ID,
                "record_source": "{{{{ params.RecordSource1 }}}}",
            },
        )

        # ref_id: Package\Staging\Get Last ID (TrackAndTraceID) — [Staging].[Get_LastValue] RecordSource3
        op_17 = PythonOperator(
            task_id="package_staging_get_last_id_trackandtraceid",
            python_callable=get_last_value,
            op_kwargs={
                "project_id": PROJECT_ID,
                "dataset_id": SP_DATASET_ID,
                "record_source": "{{{{ params.RecordSource3 }}}}",
            },
        )

        # ref_id: Package\Staging\Load TrackAndTrace SignatureAI — pipeline -> inferred SP (LastUpdateDate)
        op_19 = BigQueryInsertJobOperator(
            task_id="package_staging_load_trackandtrace_signatureai",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.sp_load_InterimStaging_TrackAndTraceData_SignatureAI_Stg`("
                        f"SAFE_CAST('{_xcom_last_sigai}' AS DATETIME));"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging\Load TrackAndTrace_Stg — pipeline -> inferred SP (LastId)
        op_20 = BigQueryInsertJobOperator(
            task_id="package_staging_load_trackandtrace_stg",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.sp_load_InterimStaging_TrackAndTrace_Stg`("
                        f"SAFE_CAST('{_xcom_last_tt}' AS INT64));"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        op_18 >> op_21
        op_21 >> op_16 >> op_19
        op_21 >> op_17 >> op_20

    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\Final

        # ref_id: Package\Final\Load HUB_Location — dv_Load_HUB_Location(ProcessId, RecordSource1)
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_load_hub_location",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_HUB_Location`("
                        f"{_xcom_processid}, '{{{{ params.RecordSource1 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        with TaskGroup(group_id="tg_package_final_load_lnk") as tg_lnk:
            # STOCK:SEQUENCE — ref_id: Package\Final\Load LNK

            # ref_id: Package\Final\Load LNK\Truncate Staging Tables
            op_10 = BigQueryInsertJobOperator(
                task_id="package_final_load_lnk_truncate_staging_tables",
                configuration={
                    "query": {
                        "query": (
                            f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_Scans_Stg`;\n"
                            f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_LNK_Scan_Stg`;"
                        ),
                        "useLegacySql": False,
                    }
                },
            )

            # ref_id: Package\Final\Load LNK\Interim Load_Scans_Stg — interimStaging_Interim_Load_Scans_Stg(ProcessId)
            op_5 = BigQueryInsertJobOperator(
                task_id="package_final_load_lnk_interim_load_scans_stg",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.interimStaging_Interim_Load_Scans_Stg`("
                            f"{_xcom_processid});"
                        ),
                        "useLegacySql": False,
                    }
                },
            )

            # ref_id: Package\Final\Load LNK\Load LNK_Scan_Stg — Staging_Load_LNK_Scan_Stg(ProcessId)
            op_8 = BigQueryInsertJobOperator(
                task_id="package_final_load_lnk_load_lnk_scan_stg",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_Load_LNK_Scan_Stg`("
                            f"{_xcom_processid});"
                        ),
                        "useLegacySql": False,
                    }
                },
            )

            # ref_id: Package\Final\Load LNK\Load LNK_Scan — dv_Load_LNK_Scan(ProcessId)
            op_6 = BigQueryInsertJobOperator(
                task_id="package_final_load_lnk_load_lnk_scan",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_LNK_Scan`("
                            f"{_xcom_processid});"
                        ),
                        "useLegacySql": False,
                    }
                },
            )

            # ref_id: Package\Final\Load LNK\Load LNK_Scan_Signatures — dv_Load_LNK_Scan_Signature(ProcessId)
            op_7 = BigQueryInsertJobOperator(
                task_id="package_final_load_lnk_load_lnk_scan_signatures",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_LNK_Scan_Signature`("
                            f"{_xcom_processid});"
                        ),
                        "useLegacySql": False,
                    }
                },
            )

            # ref_id: Package\Final\Load LNK\Set Last ID (TrackAndTraceID) — Interim_Set_LastValue(RecordSource3, NULL, NULL, 0)
            op_9 = BigQueryInsertJobOperator(
                task_id="package_final_load_lnk_set_last_id_trackandtraceid_now_in_interim_fact_scan_kpi",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.interimStaging_Set_LastValue`("
                            f"'{{{{ params.RecordSource3 }}}}', NULL, NULL, FALSE);"
                        ),
                        "useLegacySql": False,
                    }
                },
            )

            op_10 >> op_5 >> op_8 >> op_6
            op_6 >> op_7 >> op_9

        with TaskGroup(group_id="tg_package_final_load_signatureai") as tg_sigai:
            # STOCK:SEQUENCE — ref_id: Package\Final\Load SignatureAI

            # ref_id: Package\Final\Load SignatureAI\Load LNK_SignatureAI — dv_Load_LNK_Scan_SignatureAI(ProcessId)
            op_12 = BigQueryInsertJobOperator(
                task_id="package_final_load_signatureai_load_lnk_signatureai",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_LNK_Scan_SignatureAI`("
                            f"{_xcom_processid});"
                        ),
                        "useLegacySql": False,
                    }
                },
            )

            # ref_id: Package\Final\Load SignatureAI\Set Last ID (SignatureAI) — Interim_Set_LastValue(RecordSource1, NULL, NULL, 0)
            op_13 = BigQueryInsertJobOperator(
                task_id="package_final_load_signatureai_set_last_id_signatureai",
                configuration={
                    "query": {
                        "query": (
                            f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.interimStaging_Set_LastValue`("
                            f"'{{{{ params.RecordSource1 }}}}', NULL, NULL, FALSE);"
                        ),
                        "useLegacySql": False,
                    }
                },
            )

            op_12 >> op_13

        op_2 >> tg_lnk
        tg_lnk >> tg_sigai

    tg_staging >> tg_final
