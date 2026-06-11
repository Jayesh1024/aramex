"""
DAG for SSIS package: LoadGokuTables (GCP / BigQuery) — incremental FWFastlabel_ClickAndCollect only.

Mirrors `Interim_LNK_Scan.py` patterns: truncate staging → `get_last_value` for RecordSource
(SP_DATASET_ID + `Staging_Get_LastValue`) → Gold layer 1 staging SP (single `DATETIME` watermark
from XCom; silver rows load only where `ingestion_time` is after that watermark) →
Gold layer 2 `dbo_Load_ClickAndCollect` with ProcessID → `Staging_Set_LastValue` (RecordSource,
`NULL` ColumnName, `LastValue` = scalar subquery `CAST(MAX(ingestion_time) AS STRING)` from
`{TARGET_DATASET_ID}.Staging_FWFastlabel_ClickAndCollect_Stg`, `Force` FALSE).

RecordSource string must exist on `Staging_LoadControl` (same contract as `utils.getValue.get_last_value`).
Override default via DAG params when your LoadControl key differs.
"""
from __future__ import annotations

from datetime import datetime
from airflow.models import Variable
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from utils.getValue import get_last_value

GCP_PROJECT_ID = Variable.get("PROJECT_ID")
SP_DATASET_ID = Variable.get("SP_DATASET_ID")
TARGET_DATASET_ID = Variable.get("TARGET_DATASET_ID")

# Airflow Google Cloud connection for BigQueryInsertJobOperator tasks.
_GCP_CONN_ID = "oceania_target_sa_connection"

# task_id referenced by ti.xcom_pull in BigQuery CALL text below.
_TASK_ID_GET_LAST_FWFASTLABEL_CLICKANDCOLLECT = (
    "load_goku_get_last_value_fwfastlabel_clickandcollect"
)

_xcom_last_fwfastlabel_clickandcollect = (
    f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_LAST_FWFASTLABEL_CLICKANDCOLLECT}') }}}}"
)

# Staging_Set_LastValue `p_LastValue`: MAX(ingestion_time) from gold_1 staging (`TARGET_DATASET_ID`).
_max_ingestion_time_staging_fwfastlabel_clickandcollect = (
    f"(SELECT CAST(MAX(ingestion_time) AS STRING) "
    f"FROM `{TARGET_DATASET_ID}.Staging_FWFastlabel_ClickAndCollect_Stg`)"
)


default_args = {
    'owner': 'airflow',
    'depends_on_past': True,
    'retries': 0,
}

with DAG(
    dag_id="ssis_skeleton_loadgokutables",
    start_date=datetime(2024, 1, 1),
    schedule="22 16 * * *",
    catchup=False,
    default_args=default_args,
    tags=["ssis", "skeleton", "loadgokutables", "RecordSource_FWFastlabel_ClickAndCollect", "Incremental"],
    params={
        "Disable_ClickAndCollect": 0,
        "IsReload": 0,
        "ProcessID": -7,
        "RecordSourceClickAndCollect": "FWFastlabel_ClickAndCollect",
    },
) as dag:

    op_1 = BigQueryInsertJobOperator(
        task_id="load_goku_truncate_staging_fwfastlabel_clickandcollect",
        configuration={
            "query": {
                "query": (
                    f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_FWFastlabel_ClickAndCollect_Stg`;"
                ),
                "useLegacySql": False,
            }
        },
        gcp_conn_id=_GCP_CONN_ID,
        job_id="bq_gold_transformation_oceania",
    )

    op_4 = PythonOperator(
        task_id=_TASK_ID_GET_LAST_FWFASTLABEL_CLICKANDCOLLECT,
        python_callable=get_last_value,
        op_kwargs={
            "project_id": GCP_PROJECT_ID,
            "dataset_id": SP_DATASET_ID,
            "record_source": "{{ params.RecordSourceClickAndCollect }}",
            "gcp_conn_id": _GCP_CONN_ID,
        },
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

    op_1 >> op_4 >> op_7 >> op_10 >> op_13
