"""
DAG for SSIS package: LoadGokuTables (GCP / BigQuery) — historical FWFastlabel_ClickAndCollect only.

Mirrors `Interim_LNK_Scan.py` patterns: truncate staging → Gold layer 1 staging SP →
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
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator

GCP_PROJECT_ID = Variable.get("PROJECT_ID")
SP_DATASET_ID = Variable.get("SP_DATASET_ID")
TARGET_DATASET_ID = Variable.get("TARGET_DATASET_ID")

# Airflow Google Cloud connection for BigQueryInsertJobOperator tasks.
_GCP_CONN_ID = "oceania_target_sa_connection"

# Staging_Set_LastValue `p_LastValue`: MAX(ingestion_time) from gold_1 staging (`TARGET_DATASET_ID`).
_max_ingestion_time_staging_fwfastlabel_clickandcollect = (
    f"(SELECT CAST(MAX(ingestion_time) AS STRING) "
    f"FROM `{TARGET_DATASET_ID}.Staging_FWFastlabel_ClickAndCollect_Stg`)"
)

with DAG(
    dag_id="ssis_skeleton_loadgokutables_Hist",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "loadgokutables", "Historical"],
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

    op_7 = BigQueryInsertJobOperator(
        task_id="load_goku_call_sp_load_staging_fwfastlabel_clickandcollect_stg",
        configuration={
            "query": {
                "query": (
                    f"CALL `{SP_DATASET_ID}.sp_load_Staging_FWFastlabel_ClickAndCollect_Stg_Hist`();"
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

    op_1 >> op_7 >> op_10 >> op_13
