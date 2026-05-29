"""
DAG for SSIS package: LoadGokuTables (GCP / BigQuery).

Mirrors `Interim_LNK_Scan.py` patterns: truncate staging → Gold layer 1 staging SPs →
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
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator

GCP_PROJECT_ID = os.getenv("GCP_PROJECT_ID")
SP_DATASET_ID = os.getenv("SP_DATASET_ID")
TARGET_DATASET_ID = os.getenv("TARGET_DATASET_ID")

# Airflow Google Cloud connection for BigQueryInsertJobOperator tasks.
_GCP_CONN_ID = "oceania_target_sa_connection"

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
    tags=["ssis", "skeleton", "loadgokutables", "Historical"],
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

    op_5 = BigQueryInsertJobOperator(
        task_id="load_goku_call_sp_load_Staging_payzone_agents_Stg",
        configuration={
            "query": {
                "query": (
                    f"CALL `{SP_DATASET_ID}.sp_load_Staging_payzone_agents_Stg_Hist`();"
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
                    f"CALL `{SP_DATASET_ID}.sp_load_Staging_payzone_regions_Stg_Hist`();"
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

    op_1 >> op_5 >> op_8 >> op_11
    op_1 >> op_6 >> op_9 >> op_12
    op_1 >> op_7 >> op_10 >> op_13
