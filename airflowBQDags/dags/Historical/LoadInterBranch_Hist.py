
from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.python import PythonOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup
import pendulum

with DAG(
    dag_id="load_interbranch_hist",
    start_date=pendulum.datetime(2026, 4, 1, tz="Pacific/Auckland"),
    schedule_interval=None,
    catchup=False,
    tags=["load", "interbranch_hist", "ssis", "RecordSource_InterBranchNZ", "RecordSource_InterBranchAU", "Historical"],
) as dag:
    
    op_1 = TriggerDagRunOperator(
        task_id="trigger_load_interbranch_nz",
        trigger_dag_id="ssis_skeleton_hub_label_2_Hist",
        wait_for_completion=True,
        poke_interval=30,
        reset_dag_run=True,
        conf = {
            "RecordSource12": "InterBranchNZ"
        }
    )
    
    op_2 = TriggerDagRunOperator(
        task_id="trigger_load_interbranch_au",
        trigger_dag_id="ssis_skeleton_hub_label_2_Hist",
        wait_for_completion=True,
        poke_interval=30,
        reset_dag_run=True,
        conf={
            "RecordSource12": "InterBranchAU"
        }
    )

    op_1 >> op_2