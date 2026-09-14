from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
import pendulum


default_args = {
    'owner': 'airflow',
    'depends_on_past': True,
    'retries': 3,
}

with DAG(
    dag_id="load_cf_productivity_nz",
    start_date=pendulum.datetime(2026, 4, 1, tz="Pacific/Auckland"),
    schedule_interval="30 6 * * *",
    catchup=False,
    default_args=default_args,
    tags=["load", "cf", "productivity", "nz", "ssis", "Incremental"],
) as dag:

    op_1 = BigQueryInsertJobOperator(
        task_id="trigger_load_cf_productivity_nz",
        gcp_conn_id="oceania_target_sa_connection",
        location="europe-west2",
        configuration={
            "query": {
                "query": "CALL `prj-drgfly-prod-sp-01.bq_ds_prod_euw2_store_procedure.Staging_Load_CF_Productivity_NZ`(-1717);",
                "use_legacy_sql": False,
            }
        },
        job_id="bq_gold_transformation_oceania",
    )
    
    op_1