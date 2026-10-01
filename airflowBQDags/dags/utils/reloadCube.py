from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from datetime import timedelta
import pendulum as P

default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 2,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    dag_id="reload_CUBE",
    default_args=default_args,
    description="A simple DAG automation to reload CUBE",
    catchup=False,
    tags=["ssis, reload, CUBE, utility"],
) as dag:

    