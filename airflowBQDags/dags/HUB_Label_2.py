"""
Completed DAG for SSIS package: HUB_Label_2
Migration: SSIS -> BigQuery

Shape:
  * Package\Staging 2  (InterBranch staging)  -> Package\Final
  * Package\Monthly Miscellaneous            (independent, runs in parallel)

The Staging InterBranch pipeline reads from `Fastway..invbtch / invhead /
labels / prods / invdet` driven by a `@RecordSource` that switches between
'InterBranchAU' and 'InterBranchNZ' to filter `CountryCode`. Wrapped as
`sp_load_Staging_Label_Interbranch_Stg(last_batch_id INT64, record_source STRING)`.

`Set LastValue (InterBranch)` is an SSIS ExecuteSQL that updates
Staging.LoadControl conditioned on the staging table having rows — translated
as a direct BQ UPDATE with a correlated COUNT.
"""
from __future__ import annotations

from datetime import datetime
import os

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.providers.google.cloud.operators.bigquery import BigQueryInsertJobOperator
from airflow.utils.task_group import TaskGroup
from utils.getValue import get_last_value

SP_DATASET_ID = os.getenv("SP_DATASET_ID")
TARGET_DATASET_ID = os.getenv("TARGET_DATASET_ID")


# SSIS $Package::RecordSource12 is configured via DAG params.RecordSource12.
# Package loads either 'InterBranchAU' or 'InterBranchNZ' per run.

_TASK_ID_GET_LAST_ID = "tg_package_staging_2.package_staging_2_get_lastid_interbranch"

with DAG(
    dag_id="ssis_skeleton_hub_label_2",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_label_2"],
    params={
        "DisableFinal": 0,
        "DisableInterBranch": 0,
        "ProcessId": 1,
        "RecordSource12": 'InterBranchNZ',
    },
) as dag:

    with TaskGroup(group_id="tg_package_staging_2") as tg_staging_2:
        # STOCK:SEQUENCE — ref_id: Package\Staging 2

        op_10 = BigQueryInsertJobOperator(
            task_id="package_staging_2_truncate_label_interbranch_stg",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_Label_Interbranch_Stg`;",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging 2\Get LastId (InterBranch) — Staging_Get_LastValue(RecordSource12)
        op_7 = PythonOperator(
            task_id="package_staging_2_get_lastid_interbranch",
            python_callable=get_last_value,
            op_kwargs={
                "project_id": os.getenv("GOOGLE_CLOUD_PROJECT"),
                "dataset_id": SP_DATASET_ID,
                "record_source": "{{ params.RecordSource12 }}",
            },
        )

        # ref_id: Package\Staging 2\Load Label_Interbranch_Stg (Pipeline -> SP)
        op_8 = BigQueryInsertJobOperator(
            task_id="package_staging_2_load_label_interbranch_stg",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.sp_load_Staging_Label_Interbranch_Stg`("
                        f"SAFE_CAST('{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_LAST_ID}') }}}}' AS INT64), "
                        f"'{{{{ params.RecordSource12 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Staging 2\Set LastValue (InterBranch) — only update if staging has rows.
        op_9 = BigQueryInsertJobOperator(
            task_id="package_staging_2_set_lastvalue_interbranch",
            configuration={
                "query": {
                    "query": (
                        f"UPDATE `{TARGET_DATASET_ID}.Staging_LoadControl` "
                        "SET LastValue = CAST(("
                        f"SAFE_CAST('{{{{ ti.xcom_pull(task_ids='{_TASK_ID_GET_LAST_ID}') }}}}' AS INT64) + 1"
                        ") AS STRING) "
                        "WHERE RecordSource = '{{ params.RecordSource12 }}' "
                        "AND (SELECT COUNT(*) FROM "
                        f"`{TARGET_DATASET_ID}.Staging_Label_Interbranch_Stg`) > 0;"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        op_10 >> op_7 >> op_8 >> op_9

    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE — ref_id: Package\Final

        # ref_id: Package\Final\Load LNK_Label_InterBranch — Exec [dv].[Load_LNK_Label_InterBranch] ProcessId, RecordSource12
        op_1 = BigQueryInsertJobOperator(
            task_id="package_final_load_lnk_label_interbranch",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_LNK_Label_InterBranch`("
                        f"{{{{ params.ProcessId }}}}, '{{{{ params.RecordSource12 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Final\Load LSAT_Label_InterBranch — Exec [dv].[Load_LSAT_Label_InterBranch] ProcessId, RecordSource12
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_load_lsat_label_interbranch",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_LSAT_Label_InterBranch`("
                        f"{{{{ params.ProcessId }}}}, '{{{{ params.RecordSource12 }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
        )

        op_1 >> op_2

    with TaskGroup(group_id="tg_package_monthly_miscellaneous") as tg_monthly:
        # STOCK:SEQUENCE — ref_id: Package\Monthly Miscellaneous (independent)

        op_5 = BigQueryInsertJobOperator(
            task_id="package_monthly_miscellaneous_truncate_dlbs_rf_batching",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.dbo_DLBSRFBatching`;",
                    "useLegacySql": False,
                }
            },
        )

        # ref_id: Package\Monthly Miscellaneous\Maintain DLBS RFBatching (Pipeline -> SP)
        op_4 = BigQueryInsertJobOperator(
            task_id="package_monthly_miscellaneous_maintain_dlbs_rfbatching",
            configuration={
                "query": {
                    "query": f"CALL `{SP_DATASET_ID}.sp_load_dbo_DLBSRFBatching`();",
                    "useLegacySql": False,
                }
            },
        )

        op_5 >> op_4

    tg_staging_2 >> tg_final
