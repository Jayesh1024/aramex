from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.models import Variable
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup
from utils.getValue import allocate_negative_sentinel_processid, get_last_value

GCP_PROJECT_ID = Variable.get("PROJECT_ID")
SP_DATASET_ID = Variable.get("SP_DATASET_ID")
TARGET_DATASET_ID = Variable.get("TARGET_DATASET_ID")


_TASK_ID_GET_PROCESS_ID = "package_get_processid"
_TASK_ID_GET_LAST_SCAN = "tg_package_staging.package_staging_get_last_containercontents_lastscandate"



default_args = {
    'owner': 'airflow',
    'depends_on_past': True,
    'retries': 0,
}

with DAG(
    dag_id="ssis_skeleton_hub_blkcontainermanifest",
    start_date=datetime(2024, 1, 1),
    schedule="25 6 * * *",
    catchup=False,
    default_args=default_args,
    tags=["ssis", "skeleton", "hub_blkcontainermanifest", "RecordSource_BLK_ManifestContents", "RecordSource_BLK_Container", "RecordSource_BLK_TransitManifest", "RecordSource_BLK_TransitContents", "Incremental"],
    params={
        "DisableFinal": 0,
        "DisableStage": 0,
        "ManifestContentsBatchSize": 200000,
        "Minimum_ManifestId": 65000,
        "RecordSource1": 'BLK_ManifestContents',
        "RecordSource2": 'BLK_ManifestContents',
        "RecordSource3": 'BLK_Container',
        "RecordSource4": 'BLK_TransitManifest',
        "RecordSource5": 'BLK_TransitContents',
    },
) as dag:

    # ref_id: Package\Get ProcessID — negative sentinel scheme (min - 1 over < -99999).
    op_5 = PythonOperator(
        task_id=_TASK_ID_GET_PROCESS_ID,
        python_callable=allocate_negative_sentinel_processid,
        op_kwargs={
            "project_id": GCP_PROJECT_ID,
            "dataset_id": TARGET_DATASET_ID,
        },
    )

    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE — ref_id: Package\Staging

        # ref_id: Package\Staging\Truncate BLK_Manifest_Stg
        # SSIS truncates five staging tables in one task.
        op_10 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_blk_manifest_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_BLK_ContainerManifestContents_Stg`;"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Staging\Get Last ContainerContents LastScanDate
        # SSIS: Exec [Staging].[Get_LastValue] RecordSource -> scalar LastScanDate.
        op_7 = PythonOperator(
            task_id="package_staging_get_last_containercontents_lastscandate",
            python_callable=get_last_value,
            op_kwargs={
                "project_id": GCP_PROJECT_ID,
                "dataset_id": SP_DATASET_ID,
                "record_source": "{{ params.RecordSource2 }}",
            },
        )

        # ref_id: Package\Staging\Load ContainerContents (Pipeline -> SP, takes LastScanDate)
        op_8 = BigQueryInsertJobOperator(
            task_id="package_staging_load_containercontents",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.sp_load_Staging_BLK_ContainerManifestContents_Stg`(\n"
                        f"'{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_LAST_SCAN}') }}}}',\n"
                        f"{{{{ params.Minimum_ManifestId }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )


        op_10 >> op_7
        op_7 >> op_8

    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\Final

        _xcom_processid = f"{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_PROCESS_ID}') }}}}"


        # ref_id: Package\Final\Load SAT_BLKContainerManifestContent — EXEC [dv].[Load_SAT_BLKContainerManifestContents] ?,?
        op_3 = BigQueryInsertJobOperator(
            task_id="package_final_load_sat_blkcontainermanifestcontent",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_SAT_BLKContainerManifestContents`("
                        f"{_xcom_processid}, '{{{{ params.RecordSource2 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )


        # ref_id: Package\Final\Update LoadControl LastScanDate (BLK_ManifestID)
        # SSIS: correlated UPDATE of Staging.LoadControl.LastValue with
        #        MAX(ScanDate) from Staging.BLK_ContainerManifestContents_Stg.
        op_4 = BigQueryInsertJobOperator(
            task_id="package_final_update_loadcontrol_lastscandate_blk_manifestid",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"UPDATE `{TARGET_DATASET_ID}.Staging_LoadControl` lc "
                        "SET lc.LastValue = CAST(("
                        "SELECT CAST(MAX(ScanDate) AS STRING) "
                        f"FROM `{TARGET_DATASET_ID}.Staging_BLK_ContainerManifestContents_Stg`"
                        " WHERE CAST(ScanDate AS TIMESTAMP) < CURRENT_TIMESTAMP()"
                        ") AS STRING) "
                        "WHERE lc.RecordSource = '{{ params.RecordSource2 }}';"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        op_3 >> op_4

    op_5 >> tg_staging >> tg_final
