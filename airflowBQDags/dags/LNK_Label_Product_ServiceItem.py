"""
Completed DAG for SSIS package: LNK_Label_Product_ServiceItem
Migration: SSIS -> BigQuery

Table names use schema_tablename (e.g. Staging_Label_Product_ServiceItem_Stg). Procedures use schema_proc (e.g.
dv_Load_LNK_Label_Product_ServiceItem).

RecordSource (metadata param_1.variable_name) → RECORD_SOURCE_1 / params.record_source_1 (add _2, … if metadata
lists more distinct RecordSource variable_name values).

Precedence: Staging truncate → Staging load (dv SP) → Final LNK → Final LSAT (executable_dependencies: LNK
downstream is LSAT, not parallel).
"""
from __future__ import annotations

from datetime import datetime

from airflow import DAG
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup

# --- Project Configuration ---
PROJECT_ID = "searce-sandbox-da-delivery"
SP_DATASET_ID = "Aramex_oceania_SP"
TARGET_DATASET_ID = "Aramex_oceania"
PACKAGE_NAME = "LNK_Label_Product_ServiceItem"
# metadata: Load_* tasks param_1.variable_name (1st RecordSource placeholder)
RECORD_SOURCE_1 = "RecordSource"

with DAG(
    dag_id="ssis_skeleton_lnk_label_product_serviceitem",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "lnk_label_product_serviceitem"],
    params={
        "process_id": 1,
        "record_source_1": RECORD_SOURCE_1,
    },
) as dag:

    # --- Package\Staging ---
    with TaskGroup(group_id="tg_package_staging"):
        # STOCK:SEQUENCE — ref_id: Package\Staging

        # ref_id: Package\Staging\Truncate Label_Product_ServiceItem_Stg — TRUNCATE [Staging].[Label_Product_ServiceItem_Stg]
        op_4 = BigQueryInsertJobOperator(
            task_id="package_staging_truncate_label_product_serviceitem_stg",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{PROJECT_ID}.{TARGET_DATASET_ID}.Staging_Label_Product_ServiceItem_Stg`",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging\Load Label_Product_ServiceItem_Stg — Exec [dv].[Load_Label_Product_ServiceItem_Stg] ?,?
        op_3 = BigQueryInsertJobOperator(
            task_id="package_staging_load_label_product_serviceitem_stg",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_Label_Product_ServiceItem_Stg`("
                        "{{ params.process_id }}, '{{ params.record_source_1 }}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )


    # --- Package\Final ---
    with TaskGroup(group_id="tg_package_final"):
        # STOCK:SEQUENCE — ref_id: Package\Final

        # ref_id: Package\Final\Load LNK_Label_Product_ServiceItem — Exec [dv].[Load_LNK_Label_Product_ServiceItem] ?,?
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_load_lnk_label_product_serviceitem",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_LNK_Label_Product_ServiceItem`("
                        "{{ params.process_id }}, '{{ params.record_source_1 }}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final\Load LSAT_Label_Product_ServiceItem — Exec [dv].[Load_LSAT_Label_Product_ServiceItem] ?,?
        op_1 = BigQueryInsertJobOperator(
            task_id="package_final_load_lsat_label_product_serviceitem",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{PROJECT_ID}.{SP_DATASET_ID}.dv_Load_LSAT_Label_Product_ServiceItem`("
                        "{{ params.process_id }}, '{{ params.record_source_1 }}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )


    op_4 >> op_3 >> op_2 >> op_1
