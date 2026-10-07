from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.utils.task_group import TaskGroup
from datetime import timedelta
import pendulum
import sys
import json
import subprocess
import requests
from utils.run_sql_bq import main

WEBSERVER_URL = "https://3521ea19e2be418d877ea44dc0150633-dot-europe-west2.composer.googleusercontent.com"

DAGS_TO_UNPAUSE = [
    "ssis_skeleton_loadpickuprequests",
    "ssis_skeleton_loadcontrol",
    "ssis_skeleton_hub_blkcontainermanifest",
    "ssis_skeleton_load_fwfastlabel_invoices",
    "ssis_skeleton_loadgokutables",
    "interim_scans",
    "load_interbranch",
    "ssis_skeleton_fact_delivery_performance",
    "load_cf_productivity_nz",
    "load_cf_productivity_au",
    "ssis_skeleton_hub_label_mf_only",
    "ssis_skeleton_dls_manual_pricing",
]


def unpause_dags(dag_ids, is_paused=False):
    token = subprocess.check_output(
        ["gcloud", "auth", "print-access-token"]
    ).decode().strip()

    action = "Paused" if is_paused else "Unpaused"
    for dag_id in dag_ids:
        response = requests.patch(
            f"{WEBSERVER_URL.rstrip('/')}/api/v1/dags/{dag_id}",
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {token}",
            },
            data=json.dumps({"is_paused": is_paused}),
        )
        response.raise_for_status()
        print(f"{action} {dag_id}: {response.json()}")

default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}

# Arguments required by run_sql_bq.py
CREDENTIALS = "adc"  # use ADC on Cloud Composer
PROJECT = "prj-drgfly-prod-sp-01"
LOCATION = "europe-west2"
MAX_WORKERS = 20
LOG_DIR = "gs://armx-data-validation/logs"

#TODO: Read queries from gcs and Write logs to gcs rather than reading/writing from/to local filesystem
def run_sql_bq(sql_dir, credentials, project, location, max_workers, log_dir):
    sys.argv = [
        "run_sql_bq.py",
        sql_dir,
        credentials,
        "--project", project,
        "--location", location,
        "--max-workers", str(max_workers),
        "--log-dir", log_dir,
    ]
    main()


with DAG(
    dag_id="reload_CUBE",
    schedule=None,
    default_args=default_args,
    description="A simple DAG automation to reload CUBE",
    catchup=False,
    tags=["ssis, reload, CUBE, utility"],
) as dag:

    unpause_ssis_dags = PythonOperator(
        task_id="unpause_ssis_dags",
        python_callable=unpause_dags,
        op_kwargs={"dag_ids": DAGS_TO_UNPAUSE},
        doc="Unpause all SSIS DAGs before triggering them.",
    )

    truncate_cube = PythonOperator(
        task_id="truncate_cube",
        python_callable=run_sql_bq,
        op_kwargs={
            "sql_dir": "gs://drgfly-prod-euw2-composer-01/dags/utils/sql/truncateQueriesGold/",
            "credentials": CREDENTIALS,
            "project": PROJECT,
            "location": LOCATION,
            "max_workers": MAX_WORKERS,
            "log_dir": LOG_DIR,
        },
        doc="""
            Truncate all tables in CUBE.
        """
    )

    load_manual_tables = PythonOperator(
        task_id="load_manual_tables",
        python_callable=run_sql_bq,
        op_kwargs={
            "sql_dir": "gs://drgfly-prod-euw2-composer-01/dags/utils/sql/manualLoadQueries",
            "credentials": CREDENTIALS,
            "project": PROJECT,
            "location": LOCATION,
            "max_workers": MAX_WORKERS,
            "log_dir": LOG_DIR,
        },
        doc="""
            1. Load tables that are populated by INSERT statements
            2. Load Staging_Load_Control table
            3. Load HUB_CF and SAT_CF tables that are imported directly from SQLSERVER CUBE.
        """
    )
    with TaskGroup(
        group_id='load_cube_1'
    ) as load_cube_1:
        trigger_load_control_hist = TriggerDagRunOperator(
            task_id="trigger_load_control_hist",
            trigger_dag_id="ssis_skeleton_loadcontrol_Hist",
            wait_for_completion=True,
            doc="""
                Trigger the load_control_hist DAG to load all the table that are associated with Load Control dag
            """
        )
        trigger_interim_scan_hist = TriggerDagRunOperator(
            task_id="trigger_interim_scan_hist",
            trigger_dag_id="ssis_skeleton_interim_scans_Hist",
            wait_for_completion=True,
            doc="""
                Trigger the interim_scan_hist DAG to load all the table that are associated with Interim Scan dag - LNK_Scan, Fact_Scan_KPI and LNK_Scan_SignatureAI.
            """
        )
        trigger_interbranch_hist = TriggerDagRunOperator(
            task_id="trigger_interbranch_hist",
            trigger_dag_id="load_interbranch_hist",
            wait_for_completion=True,
            doc="""
                Trigger the load_interbranch_hist DAG, this trigger HUB_Label_2 dag twice but with different record source.
            """
        )
        trigger_loadgokutables = TriggerDagRunOperator(
            task_id="trigger_loadgokutables",
            trigger_dag_id="ssis_skeleton_loadgokutables_Hist",
            wait_for_completion=True,
            doc="""
                Trigger the loadgokutables DAG.
            """
        )
        trigger_fwfastlabel_invoices = TriggerDagRunOperator(
            task_id="trigger_fwfastlabel_invoices",
            trigger_dag_id="ssis_skeleton_load_fwfastlabel_invoices_Hist",
            wait_for_completion=True,
            doc="""
                Trigger the load_fwfastlabel_invoices DAG.
            """
        )
        trigger_hub_blkcontainermanifest = TriggerDagRunOperator(
            task_id="trigger_hub_blkcontainermanifest",
            trigger_dag_id="ssis_skeleton_hub_blkcontainermanifest_Hist",
            wait_for_completion=True,
            doc="""
                Trigger the hub_blkcontainermanifest DAG.
            """
        )

    with TaskGroup(group_id = 'load_cube_2') as load_cube_2:
        trigger_fact_delivery_performance = TriggerDagRunOperator(
            task_id="trigger_fact_delivery_performance",
            trigger_dag_id="ssis_skeleton_fact_delivery_performance",
            wait_for_completion=True,
            doc="""
                Trigger the fact_delivery_performance DAG.
            """
        )
        trigger_cf_productivity_nz_Hist = TriggerDagRunOperator(
            task_id="trigger_cf_productivity_nz_Hist",
            trigger_dag_id="load_cf_productivity_nz_Hist",
            wait_for_completion=True,
            doc="""
                Trigger the load_cf_productivity_nz DAG.
            """
        )
        trigger_cf_productivity_au_Hist = TriggerDagRunOperator(
            task_id="trigger_cf_productivity_au_Hist",
            trigger_dag_id="load_cf_productivity_au_Hist",
            wait_for_completion=True,
            doc="""
                Trigger the load_cf_productivity_au DAG.
            """
        )

    truncate_cube >> load_manual_tables >> load_cube_1 >> load_cube_2 >> unpause_ssis_dags