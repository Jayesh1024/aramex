"""
Completed DAG for SSIS package: HUB_Product
Migration: SSIS -> BigQuery
Formatting: Jinja2 Templating for Parameters

Graph shape: three independent Staging sequences feed two Final sequences.
  Staging     (Product_Stg)                     -> Final   (HUB_Product, SAT_Product)
  Staging 2   (STK_RFProducts_Stg)              -> Final 2 (SAT_CustomerCommissionOverride, SAT_STK_RFProducts)
  Staging 3   (CustomerCommissionOverride_Stg)  -> Final 2

Microsoft.Pipeline tasks are modelled as `Staging_Load_<table>_Stg` BQ SPs,
following the HUB_CF convention. SSIS misspellings ("Prroduct",
"CustomerCommision") are kept in task_ids to match the original DAG graph,
but table / SP names use the correct spelling that appears in the actual
destination metadata.
"""
from __future__ import annotations

from datetime import datetime
import os

from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup

PROJECT_ID = os.getenv("PROJECT_ID")
SP_DATASET_ID = os.getenv("SP_DATASET_ID")
TARGET_DATASET_ID = os.getenv("TARGET_DATASET_ID")


with DAG(
    dag_id="ssis_skeleton_hub_product",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_product"],
    params={
        "DisableFinal": 0,
        "DisableStaging": 0,
        "ProcessId": -7,
        "RecordSource": 'Fastway',
    },
) as dag:

    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE — ref_id: Package\Staging

        op_14 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_prroduct_stg",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_Product_Stg`;",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging\Load Product_Stg (Pipeline -> SP)
        op_13 = BigQueryInsertJobOperator(
            task_id="package_staging_load_product_stg",
            configuration={
                "query": {
                    "query": f"CALL `{SP_DATASET_ID}.sp_load_Staging_Product_Stg`();",
                    "useLegacySql": False,
                }
            },
        )

        op_14 >> op_13

    with TaskGroup(group_id="tg_package_staging_2") as tg_staging_2:
        # STOCK:SEQUENCE — ref_id: Package\Staging 2

        op_9 = BigQueryInsertJobOperator(
            task_id="package_staging_2_truncate_stk_rfprroduct_stg",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_STK_RFProducts_Stg`;",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging 2\Load STK_RFPrroduct_Stg (Pipeline -> SP)
        op_8 = BigQueryInsertJobOperator(
            task_id="package_staging_2_load_stk_rfprroduct_stg",
            configuration={
                "query": {
                    "query": f"CALL `{SP_DATASET_ID}.sp_load_Staging_STK_RFProducts_Stg`();",
                    "useLegacySql": False,
                }
            },
        )

        op_9 >> op_8

    with TaskGroup(group_id="tg_package_staging_3") as tg_staging_3:
        # STOCK:SEQUENCE — ref_id: Package\Staging 3

        op_12 = BigQueryInsertJobOperator(
            task_id="package_staging_3_truncate_fms_customercommisionoverride",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_CustomerCommissionOverride_Stg`;",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging 3\Load FMS_CustomerCommisionOverride (Pipeline -> SP)
        op_11 = BigQueryInsertJobOperator(
            task_id="package_staging_3_load_fms_customercommisionoverride",
            configuration={
                "query": {
                    "query": f"CALL `{SP_DATASET_ID}.sp_load_Staging_CustomerCommissionOverride_Stg`();",
                    "useLegacySql": False,
                }
            },
        )

        op_12 >> op_11

    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\Final

        # ref_id: Package\Final\Load HUB_Product — Exec [dv].[Load_HUB_Product] ProcessId, RecordSource
        op_4 = BigQueryInsertJobOperator(
            task_id="package_final_load_hub_product",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_HUB_Product`("
                        f"{{{{ params.ProcessId }}}}, '{{{{ params.RecordSource }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final\Load SAT_Product — Exec [dv].[Load_SAT_Product] ProcessId, RecordSource
        op_5 = BigQueryInsertJobOperator(
            task_id="package_final_load_sat_product",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_SAT_Product`("
                        f"{{{{ params.ProcessId }}}}, '{{{{ params.RecordSource }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

    with TaskGroup(group_id="tg_package_final_2") as tg_final_2:
        # STOCK:SEQUENCE — ref_id: Package\Final 2

        # ref_id: Package\Final 2\Load SAT_CustomerCommisionOverride — Exec [dv].[Load_SAT_CustomerCommissionOverride] RecordSource
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_2_load_sat_customercommisionoverride",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_SAT_CustomerCommissionOverride`("
                        f"'{{{{ params.RecordSource }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final 2\Load SAT_STK_RFProduct — Exec [dv].[Load_SAT_STK_RFProducts] RecordSource
        op_3 = BigQueryInsertJobOperator(
            task_id="package_final_2_load_sat_stk_rfproduct",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_SAT_STK_RFProducts`("
                        f"'{{{{ params.RecordSource }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

    tg_staging >> tg_final
    [tg_staging_2, tg_staging_3] >> tg_final_2
