from __future__ import annotations

from datetime import datetime
from typing import Any
from airflow.models import Variable
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup

from utils.getValue import get_last_value

GCP_PROJECT_ID = Variable.get("PROJECT_ID")
SP_DATASET_ID = Variable.get("SP_DATASET_ID")
TARGET_DATASET_ID = Variable.get("TARGET_DATASET_ID")


def _bq_qual(dataset_id: str, object_name: str) -> str:
    """BigQuery three-part id: `project.dataset.table_or_routine`."""
    return f"`{GCP_PROJECT_ID}.{dataset_id}.{object_name}`"

# SSIS defaults preserved for testing; override via dag_run.conf when orchestrated.
_COUNTRY_BRANCHES: tuple[dict[str, Any], ...] = (
    {
        "group_id": "tg_au",
        "record_source": "PickupRequests_AU",
        "process_id": -61,
        "table_suffix": "AU",
        "load_sp": "Staging_load_PickupRequest_AU_Stg",
        "dv_sp": "dv_Load_SAT_Label_PickupRequests_AU",
    },
    {
        "group_id": "tg_nz",
        "record_source": "PickupRequests_NZ",
        "process_id": -66,
        "table_suffix": "NZ",
        "load_sp": "Staging_load_PickupRequest_NZ_Stg",
        "dv_sp": "dv_Load_SAT_Label_PickupRequests_NZ",
    },
    {
        "group_id": "tg_sa",
        "record_source": "PickupRequests_SA",
        "process_id": -69,
        "table_suffix": "SA",
        "load_sp": "Staging_load_PickupRequest_SA_Stg",
        "dv_sp": "dv_Load_SAT_Label_PickupRequests_SA",
    },
)


_COPY_COUNTRY_TO_SHARED_SP = "Staging_Copy_PickupRequest_Country_To_Stg"



default_args = {
    'owner': 'airflow',
    'depends_on_past': True,
    'retries': 3,
}

with DAG(
    dag_id="ssis_skeleton_loadpickuprequests",
    start_date=datetime(2024, 1, 1),
    schedule="10 16 * * *",
    catchup=False,
    default_args=default_args,
    tags=["ssis", "skeleton", "loadpickuprequests", "RecordSource_PickupRequests_AU", "RecordSource_PickupRequests_NZ", "RecordSource_PickupRequests_SA", "Incremental"],
) as dag:

    for spec in _COUNTRY_BRANCHES:
        gid = spec["group_id"]
        rs = spec["record_source"]
        sfx = spec["table_suffix"]
        load_sp = spec["load_sp"]
        dv_sp = spec["dv_sp"]
        proc_id = spec["process_id"]
        tid_get_last = f"{gid}.get_last_value"

        with TaskGroup(group_id=gid):
            op_get_last = PythonOperator(
                task_id="get_last_value",
                python_callable=get_last_value,
                op_kwargs={
                    "project_id": GCP_PROJECT_ID,
                    "dataset_id": SP_DATASET_ID,
                    "record_source": rs,
                },
            )

            op_truncate = BigQueryInsertJobOperator(
                task_id="truncate_country_stg",
                configuration={
                    "query": {
                        "query": (
                            "TRUNCATE TABLE "
                            f"{_bq_qual(TARGET_DATASET_ID, f'Staging_PickupRequest_{sfx}_Stg')};"
                        ),
                        "useLegacySql": False,
                    }
                },
                gcp_conn_id="oceania_target_sa_connection",
            )

            xcom_jinja = f"{{{{ ti.xcom_pull(task_ids='{tid_get_last}', default='') }}}}"
            op_staging_load = BigQueryInsertJobOperator(
                task_id="staging_load_country",
                configuration={
                    "query": {
                        "query": (
                            f"CALL {_bq_qual(SP_DATASET_ID, load_sp)}('{xcom_jinja}');"
                        ),
                        "useLegacySql": False,
                    }
                },
                gcp_conn_id="oceania_target_sa_connection",
            )

            op_copy = BigQueryInsertJobOperator(
                task_id="copy_country_to_shared_stg",
                configuration={
                    "query": {
                        "query": (
                            f"CALL {_bq_qual(SP_DATASET_ID, _COPY_COUNTRY_TO_SHARED_SP)}"
                            f"('{sfx}');"
                        ),
                        "useLegacySql": False,
                    }
                },
                gcp_conn_id="oceania_target_sa_connection",
            )

            op_dv = BigQueryInsertJobOperator(
                task_id="dv_load_ct_sat_label_pickuprequests",
                configuration={
                    "query": {
                        "query": (
                            f"CALL {_bq_qual(SP_DATASET_ID, dv_sp)}({proc_id});"
                        ),
                        "useLegacySql": False,
                    }
                },
                gcp_conn_id="oceania_target_sa_connection",
            )

            op_set_last_value = BigQueryInsertJobOperator(
                task_id="set_last_value_loadcontrol",
                configuration={
                    "query": {
                        "query": (
                            "BEGIN\n"
                            "  DECLARE max_ingestion STRING;\n"
                            "  SET max_ingestion = (\n"
                            "    SELECT CAST(MAX(ingestion_time) AS STRING)\n"
                            f"    FROM {_bq_qual(TARGET_DATASET_ID, f'Staging_PickupRequest_{sfx}_Stg')}\n"
                            "  );\n"
                            f"  CALL {_bq_qual(SP_DATASET_ID, 'Staging_Set_LastValue')}(\n"
                            f"    '{rs}',\n"
                            "    'ingestion_time',\n"
                            "    max_ingestion,\n"
                            "    FALSE\n"
                            "  );\n"
                            "END;"
                        ),
                        "useLegacySql": False,
                    }
                },
                gcp_conn_id="oceania_target_sa_connection",
            )

            op_get_last >> op_truncate >> op_staging_load
            op_staging_load >> op_copy
            op_staging_load >> op_dv
            op_copy >> op_set_last_value
            op_dv >> op_set_last_value