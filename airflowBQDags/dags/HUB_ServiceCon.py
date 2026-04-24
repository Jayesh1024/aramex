"""
Completed DAG for SSIS package: HUB_ServiceCon
Migration: SSIS -> BigQuery

Notes:
  * The SSIS task "Load HUB_ServiceCon" actually calls
    [dv].[Load_LNK_Product_ServiceCon], and "Load SAT_ServiceCon" calls
    [dv].[Load_LSAT_Product_ServiceCon]. Task ids mirror the SSIS labels.
  * "Rebuild Indexes 13" and the "DISABLE index" tail of
    "Truncate fl_ConSrv_Stg" have been dropped entirely — BigQuery has no
    indexes. The TRUNCATE is preserved.
  * SSIS $Package::RecordSource13 is bound to `params.RecordSource13`.
"""
from __future__ import annotations
import os

from datetime import datetime

from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup

PROJECT_ID = os.getenv("PROJECT_ID")
SP_DATASET_ID = os.getenv("SP_DATASET_ID")
TARGET_DATASET_ID = os.getenv("TARGET_DATASET_ID")


with DAG(
    dag_id="ssis_skeleton_hub_servicecon",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_servicecon"],
    params={
        "DisableFinal": 0,
        "DisableStaging": 0,
        "ProcessId": 0,
        "RecordSource13": 'MFConSrv',
    },
) as dag:

    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE — ref_id: Package\Staging

        # ref_id: Package\Staging\Truncate fl_ConSrv_Stg
        op_10 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_fl_consrv_stg",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_fl_ConSrv_Stg`;",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging\Load fl_ConSrv_Stg (Pipeline -> SP, no params)
        op_6 = BigQueryInsertJobOperator(
            task_id="package_staging_load_fl_consrv_stg",
            configuration={
                "query": {
                    "query": f"CALL `{SP_DATASET_ID}.sp_load_Staging_fl_ConSrv_Stg`();",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging\Truncate Product_ServiceCon_Stg
        op_9 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_product_servicecon_stg",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_Product_ServiceCon_Stg`;",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging\Load_LSAT_Product_ServiceCon — SSIS Exec [dv].[Load_Product_ServiceCon_Stg] ProcessId, RecordSource13;
        op_7 = BigQueryInsertJobOperator(
            task_id="package_staging_load_lsat_product_servicecon",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_Product_ServiceCon_Stg`("
                        f"{{{{ params.ProcessId }}}}, '{{{{ params.RecordSource13 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        op_10 >> op_6 >> op_9 >> op_7

    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\Final

        # ref_id: Package\Final\Truncate LNK_Product_ServiceCon
        op_3 = BigQueryInsertJobOperator(
            task_id="package_final_truncate_lnk_product_servicecon",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.dv_LNK_Product_ServiceCon`;",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final\Load HUB_ServiceCon — Exec [dv].[Load_LNK_Product_ServiceCon] ProcessId, RecordSource13
        op_1 = BigQueryInsertJobOperator(
            task_id="package_final_load_hub_servicecon",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_LNK_Product_ServiceCon`("
                        f"{{{{ params.ProcessId }}}}, '{{{{ params.RecordSource13 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final\Truncate LSAT_Product_ServiceCon
        op_4 = BigQueryInsertJobOperator(
            task_id="package_final_truncate_lsat_product_servicecon",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.dv_LSAT_Product_ServiceCon`;",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final\Load SAT_ServiceCon — SSIS Exec [dv].[Load_LSAT_Product_ServiceCon] ProcessId, RecordSource13;
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_load_sat_servicecon",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_LSAT_Product_ServiceCon`("
                        f"{{{{ params.ProcessId }}}}, '{{{{ params.RecordSource13 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        op_3 >> op_1 >> op_4 >> op_2

    tg_staging >> tg_final
