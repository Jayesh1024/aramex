from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
import pendulum

with DAG(
    dag_id="load_cf_productivity_au",
    start_date=pendulum.datetime(2026, 4, 1, tz="Pacific/Auckland"),
    schedule_interval="0 7 * * *",
    catchup=False,
    tags=["load", "cf", "productivity", "au"],
) as dag:

    op_1 = BigQueryInsertJobOperator(
        task_id="trigger_load_cf_productivity_au",
        configuration={
            "query": {
                "query": "CALL `prj-drgfly-dev-sp-01.bq_ds_dev_euw2_store_procedure.Staging_Load_CF_Productivity_AU`(-717);",
                "use_legacy_sql": False,
            }
        }
    )
    
    op_1