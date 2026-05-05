"""
DAG for SSIS package: LoadGokuTables (GCP / BigQuery).

Mirrors `Interim_LNK_Scan.py` patterns: truncate staging → `get_last_value` per RecordSource
(SP_DATASET_ID + `Staging_Get_LastValue`) → Gold layer 1 staging SPs (single `DATETIME` watermark
from XCom; silver rows load only where `ingestion_time` is after that watermark) →
Gold layer 2 `dbo_Load_*` routines with ProcessID → `Staging_Set_LastValue` (RecordSource,
`NULL` ColumnName, `LastValue` = scalar subquery `CAST(MAX(ingestion_time) AS STRING)` from the
corresponding `{TARGET_DATASET_ID}.Staging_*` table, `Force` FALSE) after each dbo load.

RecordSource strings must exist on `Staging_LoadControl` (same contract as `utils.getValue.get_last_value`).
Override defaults via DAG params when your LoadControl keys differ.
"""
from __future__ import annotations

from datetime import datetime
import os

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from utils.getValue import get_last_value

GCP_PROJECT_ID = os.getenv("GCP_PROJECT_ID")
SP_DATASET_ID = os.getenv("SP_DATASET_ID")
TARGET_DATASET_ID = os.getenv("TARGET_DATASET_ID")

# Airflow Google Cloud connection for BigQueryInsertJobOperator tasks.
_GCP_CONN_ID = "oceania_target_sa_connection"

# task_ids referenced by ti.xcom_pull in BigQuery CALL text below.
_TASK_ID_GET_LAST_PAYZONE_AGENTS = "load_goku_get_last_value_payzone_agents"
_TASK_ID_GET_LAST_PAYZONE_REGIONS = "load_goku_get_last_value_payzone_regions"
_TASK_ID_GET_LAST_FWFASTLABEL_CLICKANDCOLLECT = (
    "load_goku_get_last_value_fwfastlabel_clickandcollect"
)

_xcom_last_payzone_agents = (
    f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_LAST_PAYZONE_AGENTS}') }}}}"
)
_xcom_last_payzone_regions = (
    f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_LAST_PAYZONE_REGIONS}') }}}}"
)
_xcom_last_fwfastlabel_clickandcollect = (
    f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_LAST_FWFASTLABEL_CLICKANDCOLLECT}') }}}}"
)

# Staging_Set_LastValue `p_LastValue`: MAX(ingestion_time) from gold_1 staging (`TARGET_DATASET_ID`).
_max_ingestion_time_staging_payzone_agents = (
    f"(SELECT CAST(MAX(ingestion_time) AS STRING) "
    f"FROM `{TARGET_DATASET_ID}.Staging_payzone_agents_Stg`)"
)
_max_ingestion_time_staging_payzone_regions = (
    f"(SELECT CAST(MAX(ingestion_time) AS STRING) "
    f"FROM `{TARGET_DATASET_ID}.Staging_payzone_regions_Stg`)"
)
_max_ingestion_time_staging_fwfastlabel_clickandcollect = (
    f"(SELECT CAST(MAX(ingestion_time) AS STRING) "
    f"FROM `{TARGET_DATASET_ID}.Staging_FWFastlabel_ClickAndCollect_Stg`)"
)


with DAG(
    dag_id="ssis_skeleton_loadgokutables",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "loadgokutables"],
    params={
        "Disable_ClickAndCollect": 0,
        "Disable_PayZone": 0,
        "IsReload": 0,
        "ProcessID": -7,
        "RecordSourcePayzoneAgents": "Payzone_Agents",
        "RecordSourcePayzoneRegions": "Payzone_Regions",
        "RecordSourceClickAndCollect": "FWFastlabel_ClickAndCollect",
    },
) as dag:

    op_1 = BigQueryInsertJobOperator(
        task_id="load_goku_truncate_staging_payzone_agents_regions_fwfastlabel_clickandcollect",
        configuration={
            "query": {
                "query": (
                    f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_payzone_agents_Stg`;\n"
                    f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_payzone_regions_Stg`;\n"
                    f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_FWFastlabel_ClickAndCollect_Stg`;"
                ),
                "useLegacySql": False,
            }
        },
        gcp_conn_id=_GCP_CONN_ID,
        job_id="bq_gold_transformation_oceania",
    )

    op_2 = PythonOperator(
        task_id=_TASK_ID_GET_LAST_PAYZONE_AGENTS,
        python_callable=get_last_value,
        op_kwargs={
            "project_id": PROJECT_ID,
            "dataset_id": SP_DATASET_ID,
            "record_source": "{{ params.RecordSourcePayzoneAgents }}",
            "gcp_conn_id": _GCP_CONN_ID,
        },
    )

    op_3 = PythonOperator(
        task_id=_TASK_ID_GET_LAST_PAYZONE_REGIONS,
        python_callable=get_last_value,
        op_kwargs={
            "project_id": PROJECT_ID,
            "dataset_id": SP_DATASET_ID,
            "record_source": "{{ params.RecordSourcePayzoneRegions }}",
            "gcp_conn_id": _GCP_CONN_ID,
        },
    )

    op_4 = PythonOperator(
        task_id=_TASK_ID_GET_LAST_FWFASTLABEL_CLICKANDCOLLECT,
        python_callable=get_last_value,
        op_kwargs={
            "project_id": PROJECT_ID,
            "dataset_id": SP_DATASET_ID,
            "record_source": "{{ params.RecordSourceClickAndCollect }}",
            "gcp_conn_id": _GCP_CONN_ID,
        },
    )

    op_5 = BigQueryInsertJobOperator(
        task_id="load_goku_call_sp_load_Staging_payzone_agents_Stg",
        configuration={
            "query": {
                "query": (
                    f"CALL `{SP_DATASET_ID}.sp_load_Staging_payzone_agents_Stg`("
                    f"SAFE_CAST('{_xcom_last_payzone_agents}' AS DATETIME));"
                ),
                "useLegacySql": False,
            }
        },
        gcp_conn_id=_GCP_CONN_ID,
        job_id="bq_gold_transformation_oceania",
    )

    op_6 = BigQueryInsertJobOperator(
        task_id="load_goku_call_sp_load_Staging_payzone_regions_Stg",
        configuration={
            "query": {
                "query": (
                    f"CALL `{SP_DATASET_ID}.sp_load_Staging_payzone_regions_Stg`("
                    f"SAFE_CAST('{_xcom_last_payzone_regions}' AS DATETIME));"
                ),
                "useLegacySql": False,
            }
        },
        gcp_conn_id=_GCP_CONN_ID,
        job_id="bq_gold_transformation_oceania",
    )

    op_7 = BigQueryInsertJobOperator(
        task_id="load_goku_call_sp_load_staging_fwfastlabel_clickandcollect_stg",
        configuration={
            "query": {
                "query": (
                    f"CALL `{SP_DATASET_ID}.sp_load_Staging_FWFastlabel_ClickAndCollect_Stg`("
                    f"SAFE_CAST('{_xcom_last_fwfastlabel_clickandcollect}' AS DATETIME));"
                ),
                "useLegacySql": False,
            }
        },
        gcp_conn_id=_GCP_CONN_ID,
        job_id="bq_gold_transformation_oceania",
    )

    op_8 = BigQueryInsertJobOperator(
        task_id="load_goku_call_dbo_load_payzone_agents",
        configuration={
            "query": {
                "query": (
                    f"CALL `{SP_DATASET_ID}.dbo_Load_Payzone_Agents`("
                    f"{{{{ dag_run.conf.get('process_id', params.ProcessID) }}}});"
                ),
                "useLegacySql": False,
            }
        },
        gcp_conn_id=_GCP_CONN_ID,
        job_id="bq_gold_transformation_oceania",
    )

    op_9 = BigQueryInsertJobOperator(
        task_id="load_goku_call_dbo_load_payzone_regions",
        configuration={
            "query": {
                "query": (
                    f"CALL `{SP_DATASET_ID}.dbo_Load_Payzone_Regions`("
                    f"{{{{ dag_run.conf.get('process_id', params.ProcessID) }}}});"
                ),
                "useLegacySql": False,
            }
        },
        gcp_conn_id=_GCP_CONN_ID,
        job_id="bq_gold_transformation_oceania",
    )

    op_10 = BigQueryInsertJobOperator(
        task_id="load_goku_call_dbo_load_clickandcollect",
        configuration={
            "query": {
                "query": (
                    f"CALL `{SP_DATASET_ID}.dbo_Load_ClickAndCollect`("
                    f"{{{{ dag_run.conf.get('process_id', params.ProcessID) }}}});"
                ),
                "useLegacySql": False,
            }
        },
        gcp_conn_id=_GCP_CONN_ID,
        job_id="bq_gold_transformation_oceania",
    )

    op_11 = BigQueryInsertJobOperator(
        task_id="load_goku_set_last_value_payzone_agents",
        configuration={
            "query": {
                "query": (
                    f"CALL `{SP_DATASET_ID}.Staging_Set_LastValue`("
                    f"'{{{{ params.RecordSourcePayzoneAgents }}}}', "
                    f"CAST(NULL AS STRING), "
                    f"{_max_ingestion_time_staging_payzone_agents}, "
                    f"FALSE);"
                ),
                "useLegacySql": False,
            }
        },
        gcp_conn_id=_GCP_CONN_ID,
        job_id="bq_gold_transformation_oceania",
    )

    op_12 = BigQueryInsertJobOperator(
        task_id="load_goku_set_last_value_payzone_regions",
        configuration={
            "query": {
                "query": (
                    f"CALL `{SP_DATASET_ID}.Staging_Set_LastValue`("
                    f"'{{{{ params.RecordSourcePayzoneRegions }}}}', "
                    f"CAST(NULL AS STRING), "
                    f"{_max_ingestion_time_staging_payzone_regions}, "
                    f"FALSE);"
                ),
                "useLegacySql": False,
            }
        },
        gcp_conn_id=_GCP_CONN_ID,
        job_id="bq_gold_transformation_oceania",
    )

    op_13 = BigQueryInsertJobOperator(
        task_id="load_goku_set_last_value_fwfastlabel_clickandcollect",
        configuration={
            "query": {
                "query": (
                    f"CALL `{SP_DATASET_ID}.Staging_Set_LastValue`("
                    f"'{{{{ params.RecordSourceClickAndCollect }}}}', "
                    f"CAST(NULL AS STRING), "
                    f"{_max_ingestion_time_staging_fwfastlabel_clickandcollect}, "
                    f"FALSE);"
                ),
                "useLegacySql": False,
            }
        },
        gcp_conn_id=_GCP_CONN_ID,
        job_id="bq_gold_transformation_oceania",
    )

    op_1 >> op_2 >> op_5 >> op_8 >> op_11
    op_1 >> op_3 >> op_6 >> op_9 >> op_12
    op_1 >> op_4 >> op_7 >> op_10 >> op_13
