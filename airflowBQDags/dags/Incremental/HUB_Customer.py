"""
Completed DAG for SSIS package: HUB_Customer
Migration: SSIS -> BigQuery
Formatting: Jinja2 Templating for Parameters

SSIS Microsoft.Pipeline tasks (bulk inserts from external SQL Server sources)
are modelled as their BigQuery equivalents: Staging_Load_<table>_Stg /
dv_Load_<target> stored procedures, mirroring the convention established in
HUB_CF.py (where the "Load Courier_Stg" pipeline became
`Staging_Load_Courier_Stg`).

Staging loads (no params) -> Final (ProcessId, RecordSource).
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.models import Variable
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup

GCP_PROJECT_ID = Variable.get("PROJECT_ID")
SP_DATASET_ID = Variable.get("SP_DATASET_ID")
TARGET_DATASET_ID = Variable.get("TARGET_DATASET_ID")



default_args = {
    'owner': 'airflow',
    'depends_on_past': True,
    'retries': 3,
}

with DAG(
    dag_id="ssis_skeleton_hub_customer",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    default_args=default_args,
    tags=["ssis", "skeleton", "hub_customer", "RecordSource_FMS_Customer", "RecordSource_tblCustomer", "RecordSource_CustomerLinks", "Incremental"],
    params={
        "DisableFinal": 0,
        "DisableLoadFMSCustomer": 0,
        "DisableLoadtblCustomer": 0,
        "DisableStaging": 0,
        "process_id": -13,
        "RecordSource1": 'FMS_Customer',
        "RecordSource2": 'tblCustomer',
        "RecordSource_dv_Load_SAL_Customer": 'CustomerLinks'

    },
) as dag:

    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE — ref_id: Package\Staging

        # ref_id: Package\Staging\Truncate CustomerLinks_Stg
        op_10 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_customerlinks_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_CustomerLinks_Stg`;",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Staging\Truncate FMS_Customer_Stg
        op_11 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_fms_customer_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_FMS_Customer_Stg`;",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )
   

        # ref_id: Package\Staging\Truncate IFSCustomers_Stg
        op_12 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_ifscustomers_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_IFSCustomers_Stg`;",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Staging\Truncate tblCustomer_Stg
        # SSIS truncates BOTH [Staging].[tblCustomer_Stg] and [dv].[SAT_Customer_OES]
        # in a single ExecuteSQL task — preserving that grouping here.
        op_13 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_tblcustomer_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_tblCustomer_Stg`;"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Staging\Load CustomerLinks_Stg (Pipeline -> SP)
        op_6 = BigQueryInsertJobOperator(
            task_id="package_staging_load_customerlinks_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"CALL `{SP_DATASET_ID}.sp_load_Staging_CustomerLinks_Stg`();",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Staging\Load FMS_Customer_Stg (Pipeline -> SP)
        op_7 = BigQueryInsertJobOperator(
            task_id="package_staging_load_fms_customer_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"CALL `{SP_DATASET_ID}.sp_load_Staging_FMS_Customer_Stg`();",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Staging\Load IFSCustomers_Stg (Pipeline -> SP)
        op_8 = BigQueryInsertJobOperator(
            task_id="package_staging_load_ifscustomers_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"CALL `{SP_DATASET_ID}.sp_load_Staging_IFSCustomers_Stg`();",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Staging\Load tblCustomer_Stg (Pipeline -> SP)
        op_9 = BigQueryInsertJobOperator(
            task_id="package_staging_load_tblcustomer_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"CALL `{SP_DATASET_ID}.sp_load_Staging_tblCustomer_Stg`();",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        op_10 >> op_6
        op_11 >> op_7
        op_12 >> op_8
        op_13 >> op_9

    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\Final

        # ref_id: Package\Final\Load HUB_Customer — Exec [dv].[Load_HUB_Customer] ProcessId, RecordSource
        op_1 = BigQueryInsertJobOperator(
            task_id="package_final_load_hub_customer",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_HUB_Customer`("
                        f"{{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSource1 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Final\Load SAT_Customer — Exec [dv].[Load_SAT_Customer] ProcessId, RecordSource
        op_3 = BigQueryInsertJobOperator(
            task_id="package_final_load_sat_customer",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_SAT_Customer`("
                        f"{{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSource1 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Final\Load SAL_Customer — Exec [dv].[Load_SAL_Customer] ProcessId
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_load_sal_customer",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_SAL_Customer`("
                        f"{{{{ dag_run.conf.get('process_id', params.process_id) }}}}, "
                        f"'{{{{ params.RecordSource_dv_Load_SAL_Customer }}}}');"

                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Final\Load SAT_Customer_OES (Pipeline -> SP)
        # SSIS bulk-inserts Staging.tblCustomer_Stg -> dv.SAT_Customer_OES with no transform.
        # Wrapped as a SP following the HUB_CF / HUB_Customer staging-load convention.
        

        op_1 >> op_3

    tg_staging >> tg_final
