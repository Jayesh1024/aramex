from airflow import DAG
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
import pendulum

with DAG(
    dag_id="interim_scans",
    start_date=pendulum.datetime(2026, 4, 1, tz="Pacific/Auckland"),
    schedule_interval="*/15 * * * *",
    catchup=False,
    tags=["interim", "scans", "ssis"],
) as dag:

    op_1 = TriggerDagRunOperator(
        task_id="trigger_interim_lnk_scan",
        trigger_dag_id="ssis_skeleton_interim_lnk_scan",
        wait_for_completion=True,
        poke_interval=30,
        reset_dag_run=True
    )

    op_2 = TriggerDagRunOperator(
        task_id="trigger_interim_fact_scan_kpi",
        trigger_dag_id="ssis_skeleton_interim_fact_scan_kpi",
        wait_for_completion=True,
        poke_interval=30,
        reset_dag_run=True
    )


    op_1 >> op_2