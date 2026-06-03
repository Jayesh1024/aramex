"""
Completed DAG for SSIS package: LNK_RuralOnFowards
Migration: SSIS -> BigQuery

Flow:
  Get ProcessID (MAX) -> Truncate -> Get LastDate -> Load LA_RuralOnforwards_Stg
    -> dv_Load_LNK_RuralOnforwards -> Set LastDate.

Notes:
  * Get ProcessID uses MAX(ProcessID) (NOT MAX+1) — mirrored verbatim.
  * Pipeline `Data Flow Task` loads Staging.LA_RuralOnforwards_Stg via SQL
    that requires (LastDate, StartDate, EndDate) — inferred SP
    `sp_load_Staging_LA_RuralOnforwards_Stg(LastDate, StartDate, EndDate)`.
    SSIS defaults unresolved StartDate/EndDate to '1900-01-01'; same here.
  * SSIS `EXEC [dv].[Load_LNK_RuralOnforwards]` had no visible parameters in
    metadata; BigQuery `dv_Load_LNK_RuralOnforwards` requires `ProcessID INT64`
    (see ProceduresBQ). DAG passes the same ProcessID as `Get ProcessID`
    (MAX from LoadLog via XCom), with `params.process_id` as Jinja fallback.
  * RecordSource14 default not available in metadata.
"""
from __future__ import annotations


from airflow import DAG
from airflow.models import Variable
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup
from utils.getValue import get_last_value, get_max_process_id
import pendulum

GCP_PROJECT_ID = Variable.get("PROJECT_ID")
SP_DATASET_ID = Variable.get("SP_DATASET_ID")
TARGET_DATASET_ID = Variable.get("TARGET_DATASET_ID")


_TASK_ID_GET_PROCESS_ID = "tg_package_sequence_container.package_sequence_container_get_processid"
_TASK_ID_GET_LASTDATE = "tg_package_load_la_ruraonforwards.package_load_la_ruraonforwards_get_lastdate_la_ruralonforwards"

with DAG(
    dag_id="ssis_skeleton_lnk_ruralonfowards_Hist",
    start_date=pendulum.datetime(2026, 4, 1, tz="Pacific/Auckland"),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "lnk_ruralonfowards_hist", "Historical"],
    params={
        "process_id": -121,
        "RecordSource14": 'LA_RuralOnforwards',
    },
) as dag:

    with TaskGroup(group_id="tg_package_sequence_container") as tg_seq:
        # STOCK:SEQUENCE — ref_id: Package\Sequence Container

        # ref_id: Package\Sequence Container\Get ProcessID — SELECT MAX(ProcessID) FROM Staging.LoadLog
        op_7 = PythonOperator(
            task_id="package_sequence_container_get_processid",
            python_callable=get_max_process_id,
            op_kwargs={
                "project_id": GCP_PROJECT_ID,
                "dataset_id": TARGET_DATASET_ID,
            },
        )

    with TaskGroup(group_id="tg_package_load_la_ruraonforwards") as tg_load:
        # STOCK:SEQUENCE — ref_id: Package\Load LA_RuraOnForwards

        # ref_id: Package\Load LA_RuraOnForwards\Truncate Staging Tables
        op_5 = BigQueryInsertJobOperator(
            task_id="package_load_la_ruraonforwards_truncate_staging_tables",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_LA_RuralOnforwards_Stg`;",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Load LA_RuraOnForwards\Data Flow Task — pipeline -> inferred SP (_Hist)
        op_1 = BigQueryInsertJobOperator(
            task_id="package_load_la_ruraonforwards_data_flow_task",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.sp_load_Staging_LA_RuralOnforwards_Stg_Hist`();"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Load LA_RuraOnForwards\Execute SQL Task — BQ: dv_Load_LNK_RuralOnforwards(ProcessID)
        op_2 = BigQueryInsertJobOperator(
            task_id="package_load_la_ruraonforwards_execute_sql_task",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_LNK_RuralOnforwards`("
                        f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_PROCESS_ID}') or params.process_id }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Load LA_RuraOnForwards\Set LastDate — Staging_Set_LastValue(4 args)
        op_4 = BigQueryInsertJobOperator(
            task_id="package_load_la_ruraonforwards_set_lastdate",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.Staging_Set_LastValue`("
                        f"'{{{{ params.RecordSource14 }}}}', CAST(NULL AS STRING), CAST(NULL AS STRING), FALSE);"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        op_5 >> op_1 >> op_2 >> op_4

    tg_seq >> tg_load
