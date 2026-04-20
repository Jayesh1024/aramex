"""
Completed DAG for SSIS package: HUB_Address
Migration: SSIS -> BigQuery
Formatting: Jinja2 Templating for Parameters

Tables use TARGET_DATASET_ID (Aramex_oceania). Stored procedures live under
SP_DATASET_ID (Aramex_oceania_SP) and follow schema_proc naming
(dv_Load_HUB_Address, Staging_Load_Label_Address_Stg, ...).

Note: sp_config.json lists dv_Load_HUB_Address as taking a single p_ProcessID
argument (no RecordSource), matching the .dtsx param_map. The SSIS
"Rebuild Indexes" task has been dropped — BigQuery has no indexes.
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
    dag_id="ssis_skeleton_hub_address",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_address"],
    params={
        "DisableFinal": 0,
        "DisableStaging": 0,
        "ProcessId": 0,
    },
) as dag:

    with TaskGroup(group_id="tg_package_staging") as tg_staging:
        # STOCK:SEQUENCE — ref_id: Package\Staging

        op_7 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_label_address_stg",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_Label_Address_Stg`;",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging\Load SAT_Label_Address_Stg
        # SSIS: Exec [Staging].[Load_Label_Address_Stg] ProcessId
        op_6 = BigQueryInsertJobOperator(
            task_id="package_staging_load_sat_label_address_stg",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.Staging_Load_Label_Address_Stg`("
                        f"{{{{ params.ProcessId }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        op_7 >> op_6

    with TaskGroup(group_id="tg_package_final_load_hub_address") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\Final (Load HUB_Address)

        # ref_id: Package\Final (Load HUB_Address)\Load HUB_Address
        # SSIS: Exec [dv].[Load_HUB_Address] ProcessId
        op_1 = BigQueryInsertJobOperator(
            task_id="package_final_load_hub_address_load_hub_address",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_HUB_Address`("
                        f"{{{{ params.ProcessId }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final (Load HUB_Address)\Load SAT_Address
        # SSIS: Exec [dv].[Load_SAT_Address] ProcessId
        op_3 = BigQueryInsertJobOperator(
            task_id="package_final_load_hub_address_load_sat_address",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_SAT_Address`("
                        f"{{{{ params.ProcessId }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final (Load HUB_Address)\Load LNK_Label_Address
        # SSIS: Exec [dv].[Load_LNK_Label_Address] ProcessId
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_load_hub_address_load_lnk_label_address",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_LNK_Label_Address`("
                        f"{{{{ params.ProcessId }}}});"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        op_3 >> op_2

    tg_staging >> tg_final
