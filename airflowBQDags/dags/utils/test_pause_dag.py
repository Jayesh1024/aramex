from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import timedelta
from time import sleep
from utils.callbacks import on_task_failure

DAG_ID_TO_PAUSE = "reload_CUBE"
WEBSERVER_URL = "https://3521ea19e2be418d877ea44dc0150633-dot-europe-west2.composer.googleusercontent.com/"  # replace this

default_args = {
    "owner": "airflow",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 0,
    "retry_delay": timedelta(minutes=5),
    "on_failure_callback": on_task_failure,
}

def always_fail():
    print("Task is running!!")
    sleep(15)
    raise RuntimeError("This task is supposed to fail for testing purposes.")

with DAG(
    dag_id="test_pause_dag",
    schedule=None,
    default_args=default_args,
    description="Test DAG to verify pausing another DAG via Airflow REST API",
    catchup=False,
    tags=["test", "utility", "ssis"],
) as dag:

    fail_log_check = PythonOperator(
        task_id = "fail_log_check",
        python_callable = always_fail
    )

    fail_log_check