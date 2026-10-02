from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from datetime import timedelta
import pendulum
import sys
from utils.run_sql_bq import main

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
        description="""
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
        description="""
            1. Load tables that are populated by INSERT statements
            2. Load Staging_Load_Control table
            3. Load HUB_CF and SAT_CF tables that are imported directly from SQLSERVER CUBE.
        """
    )


    truncate_cube >> load_manual_tables