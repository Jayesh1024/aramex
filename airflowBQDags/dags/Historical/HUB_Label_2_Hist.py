"""
Completed DAG for SSIS package: HUB_Label_2
Migration: SSIS -> BigQuery

Shape:
  * Package\Staging 2  (InterBranch staging)  -> Package\Final
  * Package\Monthly Miscellaneous            (independent, runs in parallel)

The Staging InterBranch pipeline reads from `Fastway..invbtch / invhead /
labels / prods / invdet` driven by a `@RecordSource` that switches between
'InterBranchAU' and 'InterBranchNZ' to filter `CountryCode`. Wrapped as
`sp_load_Staging_Label_Interbranch_Stg_Hist(record_source STRING)`.

`Set LastValue (InterBranch)` in SSIS `Package\\Final` runs after
`Load LSAT_Label_InterBranch`; it updates `Staging.LoadControl` when the
staging table has rows (same logic as the dtsx Execute SQL), translated here
as a BQ UPDATE with a correlated COUNT.
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


# SSIS $Package::RecordSource12 is configured via DAG params.RecordSource12.
# Package loads either 'InterBranchAU' or 'InterBranchNZ' per run.

with DAG(
    dag_id="ssis_skeleton_hub_label_2",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["ssis", "skeleton", "hub_label_2", "RecordSource_InterBranchNZ", "Historical"],
    params={
        "DisableFinal": 0,
        "DisableInterBranch": 0,
        "process_id": 1,
        "RecordSource12": "InterBranchNZ"
    },
) as dag:

    with TaskGroup(group_id="tg_package_staging_2") as tg_staging_2:
        # STOCK:SEQUENCE â€” ref_id: Package\Staging 2

        op_10 = BigQueryInsertJobOperator(
            task_id="package_staging_2_truncate_label_interbranch_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.Staging_Label_Interbranch_Stg`;",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Staging 2\Load Label_Interbranch_Stg (Pipeline -> SP)
        op_8 = BigQueryInsertJobOperator(
            task_id="package_staging_2_load_label_interbranch_stg",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.sp_load_Staging_Label_Interbranch_Stg_Hist`("
                        f"'{{{{ dag_run.conf.get(\'RecordSource12\',params.RecordSource12) }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )
        

        

        op_10 >> op_8
    with TaskGroup(group_id="tg_package_final") as tg_final:
        # STOCK:SEQUENCE â€” ref_id: Package\Final

        # ref_id: Package\Staging 2\Set LastValue (InterBranch) â€” only update if staging has rows.
        op_9 = BigQueryInsertJobOperator(
            task_id="package_staging_2_set_lastvalue_interbranch",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"UPDATE `{TARGET_DATASET_ID}.Staging_LoadControl` "
                        "SET LastValue = CAST(("
                        f"(SELECT COALESCE(MAX(BatchId), 0) + 1 FROM `{TARGET_DATASET_ID}.Staging_Label_Interbranch_Stg`)"
                        ") AS STRING) "
                        "WHERE RecordSource = '{{ dag_run.conf.get(\'RecordSource12\',params.RecordSource12) }}' "
                        "AND (SELECT COUNT(*) FROM "
                        f"`{TARGET_DATASET_ID}.Staging_Label_Interbranch_Stg`) > 0;"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )
        

        # ref_id: Package\Final\Load LSAT_Label_InterBranch â€” Exec [dv].[Load_LSAT_Label_InterBranch] ProcessId, RecordSource12
        op_2 = BigQueryInsertJobOperator(
            task_id="package_final_load_lsat_label_interbranch",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": (
                        f"CALL `{SP_DATASET_ID}.dv_Load_LSAT_Label_InterBranch`("
                        f"{{{{ dag_run.conf.get('process_id', params.process_id) }}}}, '{{{{ dag_run.conf.get(\'RecordSource12\',params.RecordSource12) }}}}');"
                    ),
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        op_2 >> op_9

    with TaskGroup(group_id="tg_package_monthly_miscellaneous") as tg_monthly:
        # STOCK:SEQUENCE â€” ref_id: Package\Monthly Miscellaneous (independent)

        op_5 = BigQueryInsertJobOperator(
            task_id="package_monthly_miscellaneous_truncate_dlbs_rf_batching",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"TRUNCATE TABLE `{TARGET_DATASET_ID}.dbo_DLBSRFBatching`;",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        # ref_id: Package\Monthly Miscellaneous\Maintain DLBS RFBatching (Pipeline -> SP)
        op_4 = BigQueryInsertJobOperator(
            task_id="package_monthly_miscellaneous_maintain_dlbs_rfbatching",
            gcp_conn_id="oceania_target_sa_connection",
            location="europe-west2",
            configuration={
                "query": {
                    "query": f"CALL `{SP_DATASET_ID}.sp_load_dbo_DLBSRFBatching`();",
                    "useLegacySql": False,
                }
            },
            job_id="bq_gold_transformation_oceania",
        )

        op_5 >> op_4

    tg_staging_2 >> tg_final