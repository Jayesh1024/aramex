"""
Completed DAG for SSIS package: SAT_Overrides
Migration: SSIS -> BigQuery

Two parallel branches:
  * Customer Overrides   — Truncate -> Load Stg pipeline -> Load SAT Customer
  * Zones Overrides      — Truncate Zones + Truncate Zone Overrides
                            -> Load fl_Zones + Load Zone Satchel Overrides
                            + Load Zone Weight Overrides
                            -> Load SAT Zones -> Load SAT Zone Overrides

All pipelines are simple "SELECT * FROM src -> INSERT stg" patterns without
LastDate filtering. Inferred SPs follow `Staging_load_<TableName>`.

RecordSource defaults not in metadata.
"""
from __future__ import annotations


from airflow import DAG
from airflow.models import Variable
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup
import pendulum

GCP_PROJECT_ID = Variable.get("PROJECT_ID")
SP_DATASET_ID = Variable.get("SP_DATASET_ID")
TARGET_DATASET_ID = Variable.get("TARGET_DATASET_ID")


with DAG(
    dag_id="ssis_skeleton_sat_overrides",
    start_date=pendulum.datetime(2026, 4, 1, tz="Pacific/Auckland"),
    schedule_interval="10 5 * * *",
    catchup=False,
    tags=["ssis", "skeleton", "sat_overrides"],
    params={
        "process_id": 0,
        "RecordSource": 'Fastway_PriceOverrides',
    },
) as dag:

    with TaskGroup(group_id="tg_package_customer_overrides_staging") as tg_cust_stg:
        # ref_id: ...\Load Customer Price Overrides — pipeline -> inferred SP
        op_3 = BigQueryInsertJobOperator(
            task_id="package_customer_overrides_staging_load_customer_price_overrides",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"SELECT * FROM `{TARGET_DATASET_ID}.Staging_fl_PriceListCustomerOverride_Stg`",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

    with TaskGroup(group_id="tg_package_customer_overrides_final") as tg_cust_final:
        # STOCK:SEQUENCE — ref_id: Package\Customer Overrides - Final

        # ref_id: ...\Load SAT_CustomerPriceOverride — dv_Load_SAT_FL_PriceListCustomerOverride(ProcessId, RecordSource)
        op_1 = BigQueryInsertJobOperator(
            task_id="package_customer_overrides_final_load_sat_customerpriceoverride",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_SAT_FL_PriceListCustomerOverride`("
                        f"{{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSource }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

    with TaskGroup(group_id="tg_package_zones_overrides_staging") as tg_zones_stg:
        # STOCK:SEQUENCE — ref_id: Package\Zones Overrides- Staging

        # ref_id: ...\Truncate Zones
        op_13 = BigQueryInsertJobOperator(
            task_id="package_zones_overrides_staging_truncate_zones",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.dv_SAT_FL_Zones`;\n"
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.dv_SAT_FL_ServiceZoneOverride`;"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: ...\Truncate Zone Overrides
        op_12 = BigQueryInsertJobOperator(
            task_id="package_zones_overrides_staging_truncate_zone_overrides",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.dv_SAT_FL_ServiceZoneOverride`;"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: ...\Load fl_Zones — pipeline -> inferred SP
        op_11 = BigQueryInsertJobOperator(
            task_id="package_zones_overrides_staging_load_fl_zones",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"SELECT * FROM `{TARGET_DATASET_ID}.Staging_fl_Zones_Stg`",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: ...\Load Zone Satchel Overiides — pipeline -> inferred SP
        op_9 = BigQueryInsertJobOperator(
            task_id="package_zones_overrides_staging_load_zone_satchel_overiides",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"SELECT * FROM `{TARGET_DATASET_ID}.vw_Staging_fl_ServiceZoneSatchelOverride_Stg`",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: ...\Load Zone Weight Overiides — pipeline -> inferred SP
        op_10 = BigQueryInsertJobOperator(
            task_id="package_zones_overrides_staging_load_zone_weight_overiides",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"SELECT * FROM `{TARGET_DATASET_ID}.vw_Staging_fl_ServiceZoneWeightOverride_Stg`",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        op_13 >> op_11
        op_12 >> op_9
        op_12 >> op_10

    with TaskGroup(group_id="tg_package_zones_overrides_final") as tg_zones_final:
        # STOCK:SEQUENCE — ref_id: Package\Zones Overrides - Final

        # ref_id: ...\Load SAT Zones — dv_Load_SAT_FL_Zones(ProcessId, RecordSource)
        op_7 = BigQueryInsertJobOperator(
            task_id="package_zones_overrides_final_load_sat_zones",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_SAT_FL_Zones`("
                        f"{{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSource }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: ...\Load SAT Zone Overrides — dv_Load_SAT_FL_Zone_Overrides(ProcessId, RecordSource)
        op_6 = BigQueryInsertJobOperator(
            task_id="package_zones_overrides_final_load_sat_zone_overrides",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_SAT_FL_Zone_Overrides`("
                        f"{{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ params.RecordSource }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        op_7 >> op_6

    tg_cust_stg >> tg_cust_final
    tg_zones_stg >> tg_zones_final
