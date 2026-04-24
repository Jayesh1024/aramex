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

from datetime import datetime
import os

from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup

GCP_PROJECT = os.getenv("GCP_PROJECT")
SP_DATASET_ID = os.getenv("SP_DATASET_ID")
TARGET_DATASET_ID = os.getenv("TARGET_DATASET_ID")


with DAG(
    dag_id="ssis_skeleton_sat_overrides",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "sat_overrides"],
    params={
        "ProcessId": 0,
        "RecordSource": 'Fastway_PriceOverrides',
    },
) as dag:

    with TaskGroup(group_id="tg_package_customer_overrides_staging") as tg_cust_stg:
        # ref_id: ...\Load Customer Price Overrides — pipeline -> inferred SP
        op_3 = BigQueryInsertJobOperator(
            task_id="package_customer_overrides_staging_load_customer_price_overrides",
            configuration={
                "query": {
                    "query": f"SELECT * FROM `{TARGET_DATASET_ID}.Staging_fl_PriceListCustomerOverride_Stg`",
                    "useLegacySql": False,
                }
            },
        )

    with TaskGroup(group_id="tg_package_customer_overrides_final") as tg_cust_final:
        # STOCK:SEQUENCE — ref_id: Package\Customer Overrides - Final

        # ref_id: ...\Load SAT_CustomerPriceOverride — dv_Load_SAT_FL_PriceListCustomerOverride(ProcessId, RecordSource)
        op_1 = BigQueryInsertJobOperator(
            task_id="package_customer_overrides_final_load_sat_customerpriceoverride",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_SAT_FL_PriceListCustomerOverride`("
                        f"{{{{ params.ProcessId }}}}, '{{{{ params.RecordSource }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

    with TaskGroup(group_id="tg_package_zones_overrides_staging") as tg_zones_stg:
        # STOCK:SEQUENCE — ref_id: Package\Zones Overrides- Staging

        # ref_id: ...\Truncate Zones
        op_13 = BigQueryInsertJobOperator(
            task_id="package_zones_overrides_staging_truncate_zones",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.dv_SAT_FL_Zones`;\n"
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.dv_SAT_FL_ServiceZoneOverride`;"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: ...\Truncate Zone Overrides
        op_12 = BigQueryInsertJobOperator(
            task_id="package_zones_overrides_staging_truncate_zone_overrides",
            configuration={
                "query": {
                    "query": (
                        f"TRUNCATE TABLE `{TARGET_DATASET_ID}.dv_SAT_FL_ServiceZoneOverride`;"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: ...\Load fl_Zones — pipeline -> inferred SP
        op_11 = BigQueryInsertJobOperator(
            task_id="package_zones_overrides_staging_load_fl_zones",
            configuration={
                "query": {
                    "query": f"SELECT * FROM `{TARGET_DATASET_ID}.Staging_fl_Zones_Stg`",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: ...\Load Zone Satchel Overiides — pipeline -> inferred SP
        op_9 = BigQueryInsertJobOperator(
            task_id="package_zones_overrides_staging_load_zone_satchel_overiides",
            configuration={
                "query": {
                    "query": f"SELECT * FROM `{TARGET_DATASET_ID}.vw_Staging_fl_ServiceZoneSatchelOverride_Stg`",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: ...\Load Zone Weight Overiides — pipeline -> inferred SP
        op_10 = BigQueryInsertJobOperator(
            task_id="package_zones_overrides_staging_load_zone_weight_overiides",
            configuration={
                "query": {
                    "query": f"SELECT * FROM `{TARGET_DATASET_ID}.vw_Staging_fl_ServiceZoneWeightOverride_Stg`",
                    "useLegacySql": False,
                }
            },
        )

        op_13 >> op_11
        op_12 >> op_9
        op_12 >> op_10

    with TaskGroup(group_id="tg_package_zones_overrides_final") as tg_zones_final:
        # STOCK:SEQUENCE — ref_id: Package\Zones Overrides - Final

        # ref_id: ...\Load SAT Zones — dv_Load_SAT_FL_Zones(ProcessId, RecordSource)
        op_7 = BigQueryInsertJobOperator(
            task_id="package_zones_overrides_final_load_sat_zones",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_SAT_FL_Zones`("
                        f"{{{{ params.ProcessId }}}}, '{{{{ params.RecordSource }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: ...\Load SAT Zone Overrides — dv_Load_SAT_FL_Zone_Overrides(ProcessId, RecordSource)
        op_6 = BigQueryInsertJobOperator(
            task_id="package_zones_overrides_final_load_sat_zone_overrides",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_SAT_FL_Zone_Overrides`("
                        f"{{{{ params.ProcessId }}}}, '{{{{ params.RecordSource }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        op_7 >> op_6

    tg_cust_stg >> tg_cust_final
    tg_zones_stg >> tg_zones_final
